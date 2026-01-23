/**
 * Azure Functions 主入口文件
 * 支持 SSE 流式传输和 CORS
 */

const { app } = require('@azure/functions');

// 关键：启用 HTTP 流式传输
app.setup({ enableHttpStream: true });

// ============================================
// CORS 配置（根据你的项目修改）
// ============================================
const ALLOWED_ORIGINS = [
  'http://localhost:3000',
  'http://localhost:5173',
  'https://your-project.pages.dev',
  'https://*.your-project.pages.dev',
  'https://your-custom-domain.com'
];

function getCorsHeaders(request) {
  const origin = request.headers.get('origin');

  // 精确匹配
  let isAllowed = ALLOWED_ORIGINS.includes(origin);

  // 通配符匹配
  if (!isAllowed && origin) {
    isAllowed = origin.endsWith('.pages.dev') ||
                origin.includes('.azurewebsites.net');
  }

  return {
    'Access-Control-Allow-Origin': isAllowed ? origin : ALLOWED_ORIGINS[0],
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Credentials': 'true'
  };
}

// ============================================
// 辅助函数
// ============================================
function jsonResponse(data, status = 200, corsHeaders = {}) {
  return {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
    body: JSON.stringify(data)
  };
}

// ============================================
// 健康检查端点
// ============================================
app.http('health', {
  methods: ['GET'],
  authLevel: 'anonymous',
  route: 'health',
  handler: async (request, context) => {
    const corsHeaders = getCorsHeaders(request);
    return jsonResponse({
      status: 'ok',
      time: new Date().toISOString(),
      version: '1.0.0'
    }, 200, corsHeaders);
  }
});

// ============================================
// CORS 预检端点
// ============================================
app.http('cors', {
  methods: ['OPTIONS'],
  authLevel: 'anonymous',
  route: '{*path}',
  handler: async (request, context) => {
    const corsHeaders = getCorsHeaders(request);
    return {
      status: 204,
      headers: corsHeaders
    };
  }
});

// ============================================
// 示例：SSE 流式端点
// ============================================
app.http('stream-example', {
  methods: ['POST'],
  authLevel: 'anonymous',
  route: 'stream-example',
  handler: async (request, context) => {
    const corsHeaders = getCorsHeaders(request);
    const encoder = new TextEncoder();

    const transformStream = new TransformStream({
      async start(controller) {
        try {
          // 发送心跳（每 10 秒）
          const heartbeat = setInterval(() => {
            try {
              controller.enqueue(encoder.encode(': keepalive\n\n'));
            } catch (e) {
              clearInterval(heartbeat);
            }
          }, 10000);

          // 示例：发送 5 个数据块
          for (let i = 1; i <= 5; i++) {
            const data = {
              event: 'message',
              data: { chunk: `这是第 ${i} 条消息` }
            };

            controller.enqueue(encoder.encode(`event: ${data.event}\ndata: ${JSON.stringify(data.data)}\n\n`));
            await new Promise(resolve => setTimeout(resolve, 1000));
          }

          // 发送完成信号
          controller.enqueue(encoder.encode(`data: ${JSON.stringify({ done: true })}\n\n`));
          clearInterval(heartbeat);
          controller.close();

        } catch (error) {
          controller.enqueue(encoder.encode(`data: ${JSON.stringify({ error: error.message })}\n\n`));
          controller.close();
        }
      }
    });

    return {
      status: 200,
      headers: {
        ...corsHeaders,
        'Content-Type': 'text/event-stream; charset=utf-8',
        'Cache-Control': 'no-cache, no-store, no-transform',
        'Connection': 'keep-alive',
        'X-Accel-Buffering': 'no'
      },
      body: transformStream.readable
    };
  }
});

module.exports = { app, getCorsHeaders };
