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

## Production Debugging & Verification Gap

### 问题：部署成功但用户报告问题依旧

**症状**:
- 部署工具显示"Success"
- 但用户仍看到旧的错误
- 代码修改似乎没有生效

**根因**: **The Verification Gap（验证差距）**

现代 Web 应用有多层缓存：
```
你的本地代码 → 构建产物 → 部署的文件 → 用户实际看到的
     ✅          ✅         ✅          ❌ (现实差距)
```

**关键认知**:
> **"部署成功" ≠ "用户看到了新代码"**
>
> **验证用户实际看到的，而不是你认为他们应该看到的**

---

### 理论框架：为什么调试失败

#### Theory 1: 错误信息即真理（Error Messages Are Ground Truth）

用户报错中的文件名、URL、行号是**唯一的事实**：

```
❌ 错误做法: 检查本地构建，看到正确的 API，假设问题已解决
✅ 正确做法: 用户错误显示 index-ABC.js:18 → 检查 THAT 文件 → 发现错误的 API
```

**规则**:
- 错误中的文件名 = FACT（事实）
- 永远不要用"构建产物"反驳"运行时错误"
- 总是验证错误信息指向的内容

#### Theory 2: 工具成功 ≠ 用户成功（Tool Success ≠ User Success）

工具报告成功有多个层级：

```
Level 1: 工具执行         ✅ (Bash 说 "Success")
Level 2: 文件上传         ✅ (Wrangler 说 "Deployed")
Level 3: 新文件已部署     ❓ (可能，可能没有)
Level 4: CDN 提供新文件   ❌ (缓存可能提供旧文件)
Level 5: 用户收到新文件   ❌ ← 唯一重要的
```

**规则**:
> **工具成功 ≠ 生产现实**
>
> **CDN、缓存、DNS、负载均衡在"已部署"和"已提供"之间制造差距**

#### Theory 3: 缓存优先假设（Cache-First Assumption）

现代 Web 在**每一层**都有缓存：

```
浏览器 → CDN → 服务器 → 构建 → DNS
  ↓       ↓      ↓       ↓      ↓
 缓存   缓存   缓存    缓存   缓存
```

**规则**:
> **始终假设你可能看到旧数据**
>
> **使用 cache-busting 方法验证生产环境**

#### Theory 4: 选择性验证偏差（Selective Verification Bias）

**错误**:
1. 检查**简单路径**（本地构建）→ ✅ 看起来正常
2. 跳过**困难路径**（生产现实）
3. 第一次确认后停止搜索

**修正**:
> **在问题所在处验证，而不是方便处**
>
> **用户的错误 > 你的假设 > 工具报告**

---

### 生产环境验证流程

#### Step 1: 从错误信息中提取实际 URL

```bash
# 用户错误: "index-FPRo3oei.js:18 API 调用失败"
# → 提取文件名: index-FPRo3oei.js
# → 这是唯一的真相来源
```

#### Step 2: 验证**实际运行**的内容

```bash
# ❌ 错误做法: 检查本地构建
cat dist/assets/index-D0w4YXqF.js | grep API_URL

# ✅ 正确做法: 检查错误信息中的文件
curl https://domain.com/assets/index-FPRo3oei.js | grep API_URL

# 或更好的: 先从 HTML 获取实际文件名
curl https://domain.com/ | grep -o "assets/index-.*\.js"
# 然后验证那个特定文件
```

#### Step 3: Cache-busting 验证

**方法 1: 直接文件检查（绕过 HTML 缓存）**
```bash
curl -s https://domain.com/assets/ACTUAL-FILENAME.js | grep PATTERN
```

**方法 2: 使用 cache-busting 头**
```bash
curl -H "Cache-Control: no-cache" \
     -H "Pragma: no-cache" \
     https://domain.com/assets/ACTUAL-FILENAME.js
```

**方法 3: 指示用户硬刷新**
- Chrome: `Cmd+Shift+R` (Mac) / `Ctrl+Shift+R` (Windows)
- Firefox: `Ctrl+Shift+R`
- Edge: `Ctrl+F5`

#### Step 4: 部署验证反模式

```bash
# ❌ 不要相信这些:
- "Wrangler: Upload successful (21 files)"
- "Deploy completed in 3.2s"
- "Build succeeded"

# ✅ 要相信这些:
- 实际文件内容检查
- 浏览器 DevTools Network 标签
- 用户的错误信息
```

---

### 真实案例研究

#### ❌ 错误做法（我犯的错）

```bash
# Step 1: 本地重新构建
npm run build
# 创建: dist/assets/index-D0w4YXqF.js

# Step 2: 检查本地构建（错误！）
curl dist/assets/index-D0w4YXqF.js | grep API
# 结果: https://volaris-api-flex.azurewebsites.net ✅

# Step 3: 部署
npx wrangler pages deploy dist
# 结果: "21 files uploaded" ✅

# Step 4: 宣布成功
# "问题已解决！"

# 现实: 用户仍看到旧文件和旧 API
```

**错误**:
1. ✅ 检查了文件，但**错误的文件**（本地 vs 生产）
2. ✅ 使用了工具，但**信任工具输出**超过用户现实
3. ✅ 部署了，但**没有验证提供的内容**
4. ❌ **没有检查错误信息中的实际文件**

#### ✅ 正确做法（应该怎么做）

```bash
# Step 1: 从错误中提取实际文件名
# 用户错误显示: index-FPRo3oei.js

# Step 2: 检查 HTML 引用的内容
curl https://volaris.skyliu.tech/ | grep "index-.*\.js"
# 结果: assets/index-FPRo3oei.js (匹配错误！)

# Step 3: 验证那个特定文件
curl https://volaris.skyliu.tech/assets/index-FPRo3oei.js | grep API
# 结果: https://volaris-api-test-ajfyavbcgacdc0a3.eastasia-01.azurewebsites.net ❌

# Step 4: 找到根因
# 生产环境提供的是旧构建，不是新构建

# Step 5: 强制缓存失效
# 方法: 触摸文件改变 hash，等待 CDN 传播
```

**关键洞察**:
- 错误信息 → 文件名的**真相来源**
- HTML → 加载内容的**真相来源**
- curl 生产文件 → **唯一可靠的验证**
- "已部署" ≠ "提供给用户"

---

### 生产调试黄金法则

1. **错误信息 = 现实**
   - 文件名、URL、行号是事实
   - 不要反驳错误信息

2. **生产文件 ≠ 本地文件**
   - 用户看到的可能不是你构建的
   - CDN 缓存会提供旧版本

3. **工具成功 ≠ 用户成功**
   - 部署工具的成功消息 ≠ 用户收到新代码
   - CDN、缓存会制造差距

4. **始终在用户层验证**
   - 检查用户实际加载的文件
   - 使用实际的生产 URL

5. **假设缓存在说谎**
   - 始终使用 cache-busting 方法
   - 不信任"已部署"消息

---

### 快速参考：当用户报告已部署应用的 Bug

```bash
# 1. 从错误中获取精确的文件名
cat browser-error.txt | grep "\.js:"

# 2. 验证生产 HTML
curl -s https://domain.com/ | grep -o "assets/[^\"']*\.[js|css]"

# 3. 检查实际的生产文件
curl -s https://domain.com/assets/ACTUAL-FILENAME.js | grep "PATTERN"

# 4. 如果需要，bust cache
curl -H "Cache-Control: no-cache" https://domain.com/assets/ACTUAL-FILENAME.js

# 5. 只有这时: 检查本地代码
Read src/code.js  # 对比，不要假设
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
