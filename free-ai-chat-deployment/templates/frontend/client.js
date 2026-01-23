/**
 * SSE 客户端模板
 * 用于消费 Azure Functions 的 SSE 流式端点
 *
 * 核心概念：
 * 1. 使用 fetch API 的 stream reader
 * 2. 缓冲不完整的数据块
 * 3. 解析 SSE 格式 (data: {...}\n\n)
 * 4. 错误处理和重连逻辑
 */

/**
 * 通用的 SSE 流式请求函数
 * @param {string} url - API 端点
 * @param {Object} data - 请求体数据
 * @param {Object} callbacks - 回调函数 { onChunk, onDone, onError }
 * @param {string} token - 可选的认证 token
 */
async function streamRequest(url, data, callbacks = {}, token = null) {
  const { onChunk, onDone, onError } = callbacks;

  const headers = {
    'Content-Type': 'application/json'
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers,
      body: JSON.stringify(data)
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ msg: '请求失败' }));
      onError?.(error);
      return;
    }

    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';
    let fullContent = '';
    let chunkCount = 0;

    while (true) {
      const { done, value } = await reader.read();

      if (value) {
        buffer += decoder.decode(value, { stream: true });
      }

      // 处理 SSE 格式: data: {...}\n\n
      while (buffer.includes('\n\n')) {
        const idx = buffer.indexOf('\n\n');
        const chunk = buffer.slice(0, idx);
        buffer = buffer.slice(idx + 2);

        if (chunk.startsWith('data: ')) {
          try {
            const jsonData = JSON.parse(chunk.slice(5));

            if (jsonData.content) {
              chunkCount++;
              fullContent += jsonData.content;
              onChunk?.(jsonData.content);
            }

            if (jsonData.done) {
              onDone?.({ content: fullContent, ...jsonData });
              return;
            }

            if (jsonData.error) {
              onError?.({ msg: jsonData.error });
              return;
            }
          } catch (e) {
            console.error('解析错误:', e, 'Chunk:', chunk);
          }
        }
      }

      if (done) break;
    }

    // 处理剩余数据
    if (buffer.trim() && buffer.startsWith('data: ')) {
      try {
        const jsonData = JSON.parse(buffer.slice(5).trim());
        if (jsonData.done) {
          onDone?.({ content: fullContent, ...jsonData });
        } else if (jsonData.error) {
          onError?.({ msg: jsonData.error });
        }
      } catch (e) {
        console.error('解析剩余数据错误:', e);
      }
    }

  } catch (error) {
    onError?.({ msg: error.message || '网络错误' });
  }
}

/**
 * API 客户端类示例
 */
class APIClient {
  constructor(apiBaseUrl) {
    this.apiBaseUrl = apiBaseUrl;
    this.token = null;
  }

  setToken(token) {
    this.token = token;
  }

  /**
   * 发起流式请求
   */
  async streamRequest(endpoint, data, callbacks = {}) {
    const url = `${this.apiBaseUrl}${endpoint}`;
    return streamRequest(url, data, callbacks, this.token);
  }

  /**
   * 示例：AI 聊天流式请求
   */
  async chatStream(messages, callbacks = {}) {
    return this.streamRequest('/chat/stream', { messages }, callbacks);
  }

  /**
   * 示例：普通 JSON 请求
   */
  async request(endpoint, data = {}) {
    const headers = {
      'Content-Type': 'application/json'
    };

    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }

    const response = await fetch(`${this.apiBaseUrl}${endpoint}`, {
      method: 'POST',
      headers,
      body: JSON.stringify(data)
    });

    if (!response.ok) {
      throw new Error(`请求失败: ${response.status}`);
    }

    return response.json();
  }
}

// 使用示例：
// const client = new APIClient('https://your-api.azurewebsites.net/api');
// client.setToken('your-jwt-token');
//
// client.chatStream([{ role: 'user', content: '你好' }], {
//   onChunk: (chunk) => console.log('收到数据块:', chunk),
//   onDone: (result) => console.log('完成:', result),
//   onError: (error) => console.error('错误:', error)
// });

module.exports = { streamRequest, APIClient };
