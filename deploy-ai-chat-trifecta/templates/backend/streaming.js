/**
 * SSE 流式处理模板
 * 用于 AI API 流式响应转发
 *
 * 核心概念：
 * 1. 使用 TransformStream 处理流
 * 2. 解析上游 SSE 格式 (data: {...}\n\n)
 * 3. 转发给客户端
 * 4. 实现心跳机制防止连接超时
 */

/**
 * 通用的 SSE 流式处理函数
 * @param {string} aiApiUrl - AI API 端点
 * @param {string} apiKey - API 密钥
 * @param {Array} messages - 消息数组 [{role, content}]
 * @param {Object} options - 配置选项
 * @returns {TransformStream} - 可读流
 */
function createSSEStream(aiApiUrl, apiKey, messages, options = {}) {
  const {
    model = 'gpt-3.5-turbo',
    max_tokens = 1000,
    temperature = 0.7,
    systemPrompt = null
  } = options;

  const encoder = new TextEncoder();
  const decoder = new TextDecoder();

  return new TransformStream({
    async start(controller) {
      try {
        // 1. 构建请求体
        const requestMessages = systemPrompt
          ? [{ role: 'system', content: systemPrompt }, ...messages]
          : messages;

        // 2. 调用 AI API（启用流式传输）
        const response = await fetch(aiApiUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${apiKey}`
          },
          body: JSON.stringify({
            model,
            messages: requestMessages,
            stream: true,
            max_tokens,
            temperature
          })
        });

        if (!response.ok) {
          throw new Error(`API error: ${response.status} ${response.statusText}`);
        }

        // 3. 启动心跳（每 15 秒发送一次，保持连接）
        const heartbeat = setInterval(() => {
          try {
            controller.enqueue(encoder.encode(': keepalive\n\n'));
          } catch (e) {
            // 连接已关闭，停止心跳
            clearInterval(heartbeat);
          }
        }, 15000);

        // 4. 读取上游流
        const reader = response.body.getReader();
        let buffer = '';
        let fullContent = '';

        while (true) {
          const { done, value } = await reader.read();
          if (done) break;

          // 5. 解码并缓冲数据
          buffer += decoder.decode(value, { stream: true });
          const lines = buffer.split('\n');
          buffer = lines.pop() || ''; // 保留不完整的行

          // 6. 处理每一行（SSE 格式：data: {...}\n\n）
          for (const line of lines) {
            const trimmed = line.trim();
            if (!trimmed || !trimmed.startsWith('data: ')) continue;

            const data = trimmed.slice(6); // 移除 "data: " 前缀

            if (data === '[DONE]') continue;

            try {
              const json = JSON.parse(data);
              const content = json.choices?.[0]?.delta?.content;

              if (content) {
                fullContent += content;

                // 7. 转发给客户端（SSE 格式）
                const sseMessage = `data: ${JSON.stringify({ content })}\n\n`;
                controller.enqueue(encoder.encode(sseMessage));
              }
            } catch (e) {
              console.error('解析错误:', e, '数据:', data);
              // 跳过解析错误，继续处理
            }
          }
        }

        // 8. 发送完成信号
        controller.enqueue(encoder.encode(`data: ${JSON.stringify({ done: true, content: fullContent })}\n\n`));
        clearInterval(heartbeat);
        controller.close();

      } catch (error) {
        // 9. 错误处理
        console.error('SSE 流错误:', error);
        try {
          controller.enqueue(encoder.encode(`data: ${JSON.stringify({ error: error.message })}\n\n`));
        } catch (e) {
          // 可能已经关闭
        }
        controller.close();
      }
    }
  });
}

/**
 * 在 Azure Functions 中使用的示例
 */
async function handleStreamingEndpoint(request, corsHeaders) {
  const apiKey = process.env.YOUR_AI_API_KEY;
  const aiApiUrl = 'https://api.example.com/v1/chat/completions';

  // 解析请求体
  const body = await request.json();
  const { messages, options } = body;

  // 创建 SSE 流
  const stream = createSSEStream(aiApiUrl, apiKey, messages, options);

  // 返回响应
  return {
    status: 200,
    headers: {
      ...corsHeaders,
      'Content-Type': 'text/event-stream; charset=utf-8',
      'Cache-Control': 'no-cache, no-store, no-transform',
      'Connection': 'keep-alive',
      'X-Accel-Buffering': 'no' // 禁用 nginx 缓冲
    },
    body: stream.readable
  };
}

module.exports = { createSSEStream, handleStreamingEndpoint };
