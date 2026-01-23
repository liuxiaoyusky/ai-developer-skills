---
name: free-ai-chat-deployment
description: 免费部署 AI 聊天应用到多云环境（Cloudflare Pages + Azure Functions + 阿里云域名）。包含前端部署、后端 API 配置、自定义域名设置、SSE 流式传输等完整流程。适用于需要低成本部署 AI 应用的开发者。
---

# 全栈 AI 应用部署技能 - Cloudflare + Azure + 阿里云域名

## 技能信息

**名称**: `free-ai-chat-deployment`
**类别**: 部署 (deployment)
**平台**: Cloudflare Pages + Azure Functions + 阿里云域名
**难度**: 中级
**预计时间**: 45-60 分钟
**语言**: 中文

---

## 技能描述

从零开始将 AI 聊天应用部署到多云环境的完整指南，包括：

- ✅ Azure Functions 后端部署（支持 SSE 流式传输）
- ✅ Cloudflare Pages 前端部署（全球 CDN）
- ✅ 阿里云域名配置（自定义域名和 DNS）
- ✅ SSE 流式传输实现指南
- ✅ 成本优化策略
- ✅ 安全加固措施

---

## 触发短语

你可以使用以下方式触发此技能：

- "帮我部署 AI 聊天应用到 Cloudflare 和 Azure"
- "如何设置多云部署和自定义域名"
- "配置流式传输 API 部署"
- "部署全栈 AI 应用"

---

## 前置准备

### 1. 账户准备

- **Azure 账户**: https://portal.azure.com
- **Cloudflare 账户**: https://dash.cloudflare.com
- **阿里云账户**: https://dc.console.aliyun.com
- **GitHub 账户** (可选，用于 OAuth)

### 2. 工具安装

```bash
# Azure CLI
brew install azure-cli
az login

# Azure Functions Core Tools
brew tap azure/functions
brew install azure-functions-core-tools@4

# Wrangler (Cloudflare CLI)
npm install -g wrangler
wrangler login

# 验证安装
func --version  # >= 4.x
node --version  # >= 18.x
wrangler --version
```

---

## 快速开始

### 步骤 1: 初始化 Azure 资源

```bash
# 设置环境变量
export RESOURCE_GROUP="myapp-rg"
export FUNCTION_APP="myapp-api"
export LOCATION="eastasia"
export STORAGE_ACCOUNT="myappstorage123"

# 创建资源
az group create --name $RESOURCE_GROUP --location $LOCATION
az storage account create --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --sku Standard_LRS
az functionapp create --resource-group $RESOURCE_GROUP --consumption-plan-location $LOCATION \
  --runtime node --runtime-version 20 --functions-version 4 \
  --name $FUNCTION_APP --storage-account $STORAGE_ACCOUNT --os-type Linux

echo "✅ Azure Function App 创建成功: https://$FUNCTION_APP.azurewebsites.net"
```

### 步骤 2: 配置环境变量

```bash
# 生成 JWT_SECRET
JWT_SECRET=$(openssl rand -base64 32)

# 配置环境变量
az functionapp config appsettings set \
  --name $FUNCTION_APP --resource-group $RESOURCE_GROUP \
  --settings \
    YOUR_API_KEY="$YOUR_API_KEY" \
    JWT_SECRET="$JWT_SECRET" \
    GITHUB_CLIENT_ID="$GITHUB_CLIENT_ID" \
    GITHUB_CLIENT_SECRET="$GITHUB_CLIENT_SECRET"
```

### 步骤 3: 部署后端

```bash
cd backend
npm install
func azure functionapp publish $FUNCTION_APP
az functionapp restart --name $FUNCTION_APP --resource-group $RESOURCE_GROUP

# 验证
curl https://$FUNCTION_APP.azurewebsites.net/api/health
```

### 步骤 4: 部署前端

```bash
cd frontend
npm install
npm run build
wrangler pages deploy dist --project-name=myapp --branch=production

echo "✅ 前端已部署: https://myapp.pages.dev"
```

### 步骤 5: 配置自定义域名

#### 在 Cloudflare 添加域名

```bash
wrangler pages custom-domains create myapp.example.com --project-name=myapp
```

#### 在阿里云配置 DNS

1. 访问阿里云 DNS 控制台
2. 添加 CNAME 记录：
   - 主机记录：`myapp`
   - 记录值：`myapp.pages.dev`
   - TTL：600

#### 更新 CORS

```bash
az functionapp cors add \
  --name $FUNCTION_APP --resource-group $RESOURCE_GROUP \
  --allowed-origins "https://myapp.example.com"
```

在代码中添加域名到 `ALLOWED_ORIGINS` 并重新部署。

---

## SSE 流式传输实现

### 后端配置

**1. `host.json`**:
```json
{
  "extensions": {
    "http": {
      "enableStream": true
    }
  }
}
```

**2. `index.js`**:
```javascript
const { app } = require('@azure/functions');
app.setup({ enableHttpStream: true });
```

**3. 流式端点模板**：
```javascript
const transformStream = new TransformStream({
  async start(controller) {
    const encoder = new TextEncoder();

    // 心跳（每 15 秒）
    const heartbeat = setInterval(() => {
      controller.enqueue(encoder.encode(': keepalive\n\n'));
    }, 15000);

    // 发送数据
    controller.enqueue(encoder.encode(`data: ${JSON.stringify({ content: '...' })}\n\n`));

    // 完成
    controller.enqueue(encoder.encode(`data: ${JSON.stringify({ done: true })}\n\n`));
    clearInterval(heartbeat);
    controller.close();
  }
});

return {
  status: 200,
  headers: {
    'Content-Type': 'text/event-stream; charset=utf-8',
    'Cache-Control': 'no-cache, no-store, no-transform',
    'X-Accel-Buffering': 'no'
  },
  body: transformStream.readable
};
```

### 前端实现

```javascript
async function streamRequest(url, data, callbacks = {}) {
  const { onChunk, onDone, onError } = callbacks;

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  });

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });

    while (buffer.includes('\n\n')) {
      const idx = buffer.indexOf('\n\n');
      const chunk = buffer.slice(0, idx);
      buffer = buffer.slice(idx + 2);

      if (chunk.startsWith('data: ')) {
        const data = JSON.parse(chunk.slice(5));
        if (data.content) onChunk?.(data.content);
        if (data.done) { onDone?.(data); return; }
      }
    }
  }
}
```

---

## 成本优化

### Azure Functions

- **Consumption Plan**: 250K 执行次数/月免费
- **低流量** (<10K 请求/天): ¥0-30/月
- **中等流量** (10K-100K 请求/天): ¥140-350/月

### Cloudflare Pages

- **免费 tier**: 无限带宽、500 构建/月、全球 CDN
- **成本**: ¥0/月

### 总成本估算

- 低流量: ¥7-15/月
- 中等流量: ¥150-370/月

**优化建议**:

```bash
# 监控使用量
az consumption usage list --resource-group $RESOURCE_GROUP

# 设置预算告警
az consumption budget create \
  --name monthly-budget --resource-group $RESOURCE_GROUP \
  --amount 50 --time-grain Monthly
```

---

## 安全加固

### 1. 密钥管理

**永远不要**将密钥提交到 Git：

```bash
# .gitignore
local.settings.json
.env
*.key
```

使用 Azure Key Vault 存储密钥：

```bash
az keyvault create --name myapp-kv --resource-group $RESOURCE_GROUP
az keyvault secret set --vault-name myapp-kv --name "MyApiKey" --value "$MY_API_KEY"
```

### 2. HTTPS 强制

Azure Functions 和 Cloudflare Pages 默认启用 HTTPS。

### 3. 速率限制

在代码中实现 IP 级限流：

```javascript
const ipLimits = new Map();

function checkRateLimit(clientIP, maxRequests = 100) {
  const now = Date.now();
  const hour = 60 * 60 * 1000;

  if (!ipLimits.has(clientIP)) {
    ipLimits.set(clientIP, { count: 1, resetTime: now + hour });
    return true;
  }

  const limit = ipLimits.get(clientIP);
  if (now > limit.resetTime) {
    limit.count = 1;
    limit.resetTime = now + hour;
    return true;
  }

  return limit.count++ < maxRequests;
}
```

---

## 故障排除

### 问题 1: CORS 错误

**解决方案**:

```bash
# 检查 CORS 设置
az functionapp cors show --name $FUNCTION_APP --resource-group $RESOURCE_GROUP

# 添加缺失的源
az functionapp cors add \
  --name $FUNCTION_APP --resource-group $RESOURCE_GROUP \
  --allowed-origins "https://your-domain.com"
```

在代码中更新 `ALLOWED_ORIGINS` 并重新部署。

### 问题 2: SSE 流式传输不工作

**检查清单**:

- [ ] `host.json` 中 `enableStream: true`
- [ ] `index.js` 中 `app.setup({ enableHttpStream: true })`
- [ ] 响应头包含 `Content-Type: text/event-stream`
- [ ] 响应头包含 `X-Accel-Buffering: no`

**测试**:
```bash
curl -N https://your-api.azurewebsites.net/api/stream-test
```

### 问题 3: 域名无法解析

**解决方案**:

```bash
# 检查 DNS
dig your-domain.com

# 清除 DNS 缓存
sudo dscacheutil -flushcache  # macOS
ipconfig /flushdns            # Windows
```

### 问题 4: 环境变量不工作

**解决方案**:

```bash
# 验证变量已设置
az functionapp config appsettings list \
  --name $FUNCTION_APP --resource-group $RESOURCE_GROUP

# 重启 Function App
az functionapp restart \
  --name $FUNCTION_APP --resource-group $RESOURCE_GROUP
```

等待 30-60 秒生效。

---

## 代码模板

技能包含以下代码模板（位于 `templates/` 目录）：

- `templates/backend/host.json` - Azure Functions 配置
- `templates/backend/index.js` - 主入口和 CORS 配置
- `templates/backend/streaming.js` - SSE 流式处理模板
- `templates/frontend/client.js` - SSE 客户端实现
- `templates/config/wrangler.toml` - Cloudflare Pages 配置
- `templates/config/env.example` - 环境变量模板

---

## 自动化脚本

技能包含以下自动化脚本（位于 `scripts/` 目录）：

- `scripts/01-init-azure.sh` - 初始化 Azure 资源
- `scripts/02-deploy-backend.sh` - 部署后端
- `scripts/03-deploy-frontend.sh` - 部署前端
- `scripts/04-configure-dns.sh` - DNS 配置指南
- `scripts/05-test-deployment.sh` - 部署验证测试

---

## 下一步

1. ✅ 复制代码模板到你的项目
2. ✅ 根据你的需求修改配置
3. ✅ 运行自动化脚本
4. ✅ 测试部署
5. ✅ 配置自定义域名
6. ✅ 优化成本和安全

---

## 需要帮助？

- Azure 文档: https://learn.microsoft.com/azure
- Cloudflare 文档: https://developers.cloudflare.com/pages
- 查看 `docs/` 目录中的详细指南

---

**版本**: v1.0.0
**最后更新**: 2026-01-23
