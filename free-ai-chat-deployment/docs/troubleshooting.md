# 故障排除指南

## 概述

本指南帮助你诊断和解决部署和运行 AI 聊天应用时遇到的常见问题。

---

## 目录

1. [部署问题](#部署问题)
2. [CORS 问题](#cors-问题)
3. [SSE 流式传输问题](#sse-流式传输问题)
4. [DNS 和域名问题](#dns-和域名问题)
5. [认证问题](#认证问题)
6. [性能问题](#性能问题)
7. [成本问题](#成本问题)

---

## 部署问题

### 问题：Azure Functions 部署失败

**症状**:
```
Failed to deploy to Azure Functions
```

**诊断步骤**:

1. 检查登录状态
```bash
az account show
```

2. 检查 Function App 是否存在
```bash
az functionapp show \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP
```

3. 检查本地文件
```bash
cd backend
ls -la
# 确认 host.json 和 package.json 存在
```

**解决方案**:

1. 重新登录 Azure
```bash
az login
az account set --subscription YOUR_SUBSCRIPTION_ID
```

2. 检查 Function App 名称是否唯一
```bash
# Function App 名称必须全局唯一
# 如果重复，创建新的
az functionapp create --name $NEW_FUNCTION_APP ...
```

3. 清除本地构建缓存
```bash
rm -rf node_modules package-lock.json
npm install
```

---

### 问题：前端构建失败

**症状**:
```
npm run build 失败
```

**诊断步骤**:

```bash
# 检查 Node 版本
node --version  # 应该 >= 18.x

# 检查依赖
npm list

# 尝试构建
npm run build
```

**解决方案**:

1. 更新 Node.js
```bash
# 使用 nvm
nvm install 20
nvm use 20
```

2. 清除缓存
```bash
rm -rf node_modules dist package-lock.json
npm install
npm run build
```

3. 检查环境变量
```bash
# 确保生产环境变量已设置
cat .env.production
```

---

### 问题：Cloudflare Pages 部署失败

**症状**:
```
Wrangler deployment failed
```

**诊断步骤**:

```bash
# 检查登录
wrangler whoami

# 检查项目
wrangler pages project list
```

**解决方案**:

1. 重新登录
```bash
wrangler logout
wrangler login
```

2. 手动创建项目
```bash
wrangler pages project create myapp --production-branch=main
```

3. 检查构建输出目录
```bash
ls -la dist/
# 确认 index.html 存在
```

---

## CORS 问题

### 问题：CORS 错误

**症状**:
```
Access to fetch at 'https://api...' from origin 'https://domain' has been blocked by CORS policy
```

**诊断步骤**:

1. 检查浏览器控制台完整错误
2. 检查 Network 标签中的请求头

**解决方案**:

#### 1. 检查 Azure CORS 设置

```bash
az functionapp cors show \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP
```

#### 2. 添加缺失的源

```bash
az functionapp cors add \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --allowed-origins "https://your-domain.com"
```

#### 3. 更新代码中的 CORS

`backend/src/index.js`:
```javascript
const ALLOWED_ORIGINS = [
  'http://localhost:5173',
  'https://your-project.pages.dev',
  'https://your-custom-domain.com'  // 添加这个
];
```

#### 4. 验证模式匹配

```javascript
// 支持子域名
if (!isAllowed && origin) {
  isAllowed = origin.endsWith('.pages.dev') ||
              origin.includes('.azurewebsites.net');
}
```

#### 5. 重新部署

```bash
cd backend
func azure functionapp publish $FUNCTION_APP
az functionapp restart --name $FUNCTION_APP --resource-group $RESOURCE_GROUP
```

#### 6. 硬刷新浏览器

- Windows/Linux: `Ctrl+Shift+R`
- Mac: `Cmd+Shift+R`

---

## SSE 流式传输问题

### 问题：没有收到流式数据

**症状**:
- 前端没有收到任何数据块
- 连接立即关闭
- 等待很长时间后一次性收到所有数据

**诊断步骤**:

1. 测试端点直接访问
```bash
curl -N https://your-api.azurewebsites.net/api/stream-test
```

2. 检查响应头
```bash
curl -I https://your-api.azurewebsites.net/api/stream-test
```

**检查清单**:

- [ ] `host.json` 中 `enableStream: true`
- [ ] `index.js` 中 `app.setup({ enableHttpStream: true })`
- [ ] 响应头包含 `Content-Type: text/event-stream`
- [ ] 响应头包含 `X-Accel-Buffering: no`

**解决方案**:

#### 1. 配置 `host.json`

```json
{
  "extensions": {
    "http": {
      "enableStream": true
    }
  }
}
```

#### 2. 启用 HTTP 流式传输

`backend/src/index.js`:
```javascript
const { app } = require('@azure/functions');

// 必须在所有路由定义之前
app.setup({ enableHttpStream: true });
```

#### 3. 设置正确的响应头

```javascript
return {
  status: 200,
  headers: {
    ...corsHeaders,
    'Content-Type': 'text/event-stream; charset=utf-8',
    'Cache-Control': 'no-cache, no-store, no-transform',
    'Connection': 'keep-alive',
    'X-Accel-Buffering': 'no'  // 关键！
  },
  body: transformStream.readable
};
```

#### 4. 添加心跳机制

```javascript
const heartbeat = setInterval(() => {
  try {
    controller.enqueue(encoder.encode(': keepalive\n\n'));
  } catch (e) {
    clearInterval(heartbeat);
  }
}, 15000);
```

---

### 问题：流式数据解析错误

**症状**:
```
SyntaxError: Unexpected token in JSON
```

**原因**: 不完整的 SSE 数据块

**解决方案**:

前端缓冲处理：
```javascript
let buffer = '';

while (true) {
  const { done, value } = await reader.read();
  if (done) break;

  buffer += decoder.decode(value, { stream: true });

  // 只处理完整的数据块（以 \n\n 分隔）
  while (buffer.includes('\n\n')) {
    const idx = buffer.indexOf('\n\n');
    const chunk = buffer.slice(0, idx);
    buffer = buffer.slice(idx + 2);

    if (chunk.startsWith('data: ')) {
      try {
        const data = JSON.parse(chunk.slice(5));
        // 处理数据...
      } catch (e) {
        console.error('解析错误:', e);
      }
    }
  }
}
```

---

## DNS 和域名问题

### 问题：自定义域名无法访问

**症状**:
- `myapp.example.com` 无法加载
- DNS 查找失败

**诊断步骤**:

1. 检查 DNS 解析
```bash
dig myapp.example.com
nslookup myapp.example.com
```

2. 检查 Cloudflare 配置
```bash
wrangler pages custom-domains list --project-name=myapp
```

**解决方案**:

#### 1. 验证 DNS 记录

在阿里云 DNS 控制台检查：
- **类型**: CNAME
- **主机记录**: `myapp`
- **记录值**: `myapp.pages.dev`
- **TTL**: 600

#### 2. 等待 DNS 传播

DNS 传播需要 5-30 分钟。

验证传播：
```bash
# 使用多个 DNS 服务器
dig myapp.example.com @8.8.8.8
dig myapp.example.com @1.1.1.1
```

#### 3. 清除 DNS 缓存

```bash
# macOS
sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder

# Windows
ipconfig /flushdns

# Linux
sudo systemd-resolve --flush-caches
```

#### 4. 在浏览器中测试

使用无痕模式访问，排除本地缓存。

---

### 问题：SSL 证书错误

**症状**:
```
NET::ERR_CERT_AUTHORITY_INVALID
```

**解决方案**:

Cloudflare Pages 自动提供 SSL 证书。

如果使用自定义域名：

1. 在 Cloudflare 检查证书状态
2. 等待证书签发（通常需要 15-30 分钟）
3. 确保橙色云朵（代理）已开启

---

## 认证问题

### 问题：GitHub OAuth redirect_uri_mismatch

**症状**:
```
Error: redirect_uri_mismatch
```

**解决方案**:

1. 检查 GitHub OAuth App 设置
   - 访问：https://github.com/settings/developers
   - 编辑你的 OAuth App

2. 确认回调 URL 完全匹配：
```
https://your-domain.com/auth/callback
```

常见错误：
- ❌ `https://your-domain.com/auth/` （末尾多了斜杠）
- ❌ `http://your-domain.com/auth/callback` （使用了 HTTP）
- ✅ `https://your-domain.com/auth/callback` （正确）

3. 添加所有环境：
```
http://localhost:5173/auth/callback
https://your-project.pages.dev/auth/callback
https://your-custom-domain.com/auth/callback
```

---

### 问题：JWT token 无效

**症状**:
```
Invalid token
Unauthorized
```

**诊断步骤**:

1. 检查 token 是否包含在请求头
```javascript
headers['Authorization'] = `Bearer ${token}`
```

2. 检查 JWT_SECRET 是否一致

**解决方案**:

1. 确保 JWT_SECRET 已设置
```bash
az functionapp config appsettings list \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --query "[?name=='JWT_SECRET']"
```

2. 重启 Function App 应用新设置
```bash
az functionapp restart \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP
```

3. 检查 token 过期时间
```javascript
// token 过期？需要刷新
if (Date.now() > token.exp * 1000) {
  // 刷新 token
}
```

---

## 性能问题

### 问题：响应缓慢

**症状**:
- API 响应时间 > 5 秒
- 频繁超时

**诊断步骤**:

1. 测试后端直接访问
```bash
time curl https://your-api.azurewebsites.net/api/health
```

2. 检查 Azure 指标
   - 访问 Azure Portal
   - Function App → Metrics
   - 查看 Response Time

**解决方案**:

#### 1. 优化代码

- 减少同步操作
- 使用异步 API
- 避免阻塞调用

#### 2. 升级定价层级

如果使用 Consumption Plan：
- 考虑升级到 Flex Consumption 或 Premium
- 更少的冷启动，更一致的性能

#### 3. 启用缓存

```javascript
const cache = new Map();

function getCached(key) {
  const cached = cache.get(key);
  if (cached && Date.now() - cached.time < 300000) { // 5 分钟
    return cached.data;
  }
  return null;
}
```

---

### 问题：冷启动时间长

**症状**:
- 首次请求需要 5-10 秒
- 后续请求很快

**原因**: Azure Functions 冷启动

**解决方案**:

1. 优化依赖加载
```javascript
// 懒加载
let heavyLibrary;

app.http('endpoint', {
  handler: async (request, context) => {
    if (!heavyLibrary) {
      heavyLibrary = require('heavy-library');
    }
  }
});
```

2. 预热实例
```bash
# 定期发送请求保持实例活跃
*/5 * * * * curl https://your-api.azurewebsites.net/api/health
```

3. 升级到 Premium Plan（始终预热）

---

## 成本问题

### 问题：成本超出预期

**症状**:
- Azure 账单异常高

**诊断步骤**:

```bash
# 查看使用量
az consumption usage list \
  --resource-group $RESOURCE_GROUP \
  --output table

# 查看执行次数
az monitor metrics list \
  --resource /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Web/sites/{app} \
  --metric "FunctionExecutionCount"
```

**解决方案**:

1. 设置预算告警
```bash
az consumption budget create \
  --name monthly-budget \
  --resource-group $RESOURCE_GROUP \
  --amount 50
```

2. 优化代码减少执行时间

3. 实施速率限制防止滥用

4. 查看 [成本优化指南](./cost-optimization.md)

---

## 获取帮助

### 调试技巧

1. **启用详细日志**
```javascript
console.log('Debug info:', { variable });
```

2. **使用 Azure Application Insights**
```bash
# 查看日志
az monitor app-insights events show \
  --app myapp-insights \
  --resource-group $RESOURCE_GROUP
```

3. **检查 Function App 日志**
```bash
# 实时日志
az webapp log tail \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP
```

### 有用的链接

- [Azure Functions 文档](https://docs.microsoft.com/azure/azure-functions/)
- [Cloudflare Pages 文档](https://developers.cloudflare.com/pages/)
- [Azure 状态](https://status.azure.com/)
- [Cloudflare 状态](https://www.cloudflarestatus.com/)

### 联系支持

如果问题仍未解决：

1. Azure Portal → Support → Create Support Request
2. Cloudflare Dashboard → Support
3. GitHub Issues（如果问题来自代码）

---

**最后更新**: 2026-01-23
