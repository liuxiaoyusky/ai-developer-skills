# 安全加固指南

## 概述

本指南帮助你加强部署在 Cloudflare Pages + Azure Functions 的 AI 聊天应用的安全性。

---

## 密钥管理

### 1. 永远不要提交密钥到 Git

**`.gitignore` 配置**:

```gitignore
# Azure Functions
local.settings.json

# 环境变量
.env
.env.local
.env.production
.env.*.local

# 密钥文件
*.key
*.pem
secrets/
```

**验证**:

```bash
# 检查是否已提交密钥
git log --all --full-history --source -- "*.env" "local.settings.json"

# 如果已提交，从历史中移除
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch local.settings.json" \
  --prune-empty --tag-name-filter cat -- --all
```

### 2. 使用 Azure Key Vault（推荐）

#### 创建 Key Vault

```bash
# 创建 Key Vault
az keyvault create \
  --name myapp-kv \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --enable-purge-protection true

# 启用受保护的部署
az keyvault update \
  --name myapp-kv \
  --resource-group $RESOURCE_GROUP \
  --enable-soft-delete true \
  --enable-purge-protection true
```

#### 存储密钥

```bash
# 存储密钥
az keyvault secret set \
  --vault-name myapp-kv \
  --name "SiliconFlowApiKey" \
  --value "$SILICONFLOW_API_KEY"

az keyvault secret set \
  --vault-name myapp-kv \
  --name "JwtSecret" \
  --value "$(openssl rand -base64 32)"

az keyvault secret set \
  --vault-name myapp-kv \
  --name "GitHubClientSecret" \
  --value "$GITHUB_CLIENT_SECRET"
```

#### 在代码中使用

```javascript
// 安装 @azure/keyvault-secrets 和 @azure/identity
const { DefaultAzureCredential } = require('@azure/identity');
const { SecretClient } = require('@azure/keyvault-secrets');

const credential = new DefaultAzureCredential();
const client = new SecretClient(
  `https://${process.env.KEY_VAULT_NAME}.vault.azure.net`,
  credential
);

async function getSecret(secretName) {
  const secret = await client.getSecret(secretName);
  return secret.value;
}

// 使用
const apiKey = await getSecret('SiliconFlowApiKey');
```

#### 配置 Function App 访问 Key Vault

```bash
# 启用托管标识
az functionapp identity assign \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP

# 获取标识 ID
PRINCIPAL_ID=$(az functionapp identity show \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --query principalId -o tsv)

# 授予访问权限
az keyvault set-policy \
  --name myapp-kv \
  --resource-group $RESOURCE_GROUP \
  --object-id $PRINCIPAL_ID \
  --secret-permissions get list
```

### 3. 定期轮换密钥

**轮换周期**:
- API 密钥：每 90 天
- JWT_SECRET：每 180 天
- 数据库密码：每 180 天

**自动化轮换脚本**:

```bash
#!/bin/bash
# scripts/rotate-secrets.sh

KEY_VAULT_NAME="myapp-kv"

# 生成新的 JWT_SECRET
NEW_JWT_SECRET=$(openssl rand -base64 32)

# 更新 Key Vault
az keyvault secret set \
  --vault-name $KEY_VAULT_NAME \
  --name "JwtSecret" \
  --value "$NEW_JWT_SECRET"

# 重启 Function App 应用新密钥
az functionapp restart \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP

echo "✅ 密钥轮换完成"
```

---

## HTTPS 强制

### Azure Functions

**验证 HTTPS 已启用**:

```bash
az functionapp config show \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --query httpsOnly
```

**强制 HTTPS**:

```bash
az functionapp update \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --set httpsOnly=true
```

### Cloudflare Pages

- ✅ 自动提供免费 SSL（TLS 1.3）
- ✅ 自动 HTTP 到 HTTPS 重定向
- ✅ HSTS 启用

**验证**: 访问 `http://your-domain.com` 应自动重定向到 `https://your-domain.com`

---

## 速率限制

### 为什么需要速率限制？

- 防止 DDoS 攻击
- 防止 API 滥用
- 控制成本
- 保护后端服务

### 实现方案

#### 方案 1: 基于 Azure Storage

```javascript
const { BlobServiceClient } = require('@azure/storage-blob');

const blobServiceClient = BlobServiceClient.fromConnectionString(
  process.env.AzureWebJobsStorage
);
const containerClient = blobServiceClient.getContainerClient('ratelimit');

async function checkRateLimit(clientIP, maxRequests = 100) {
  const today = new Date().toISOString().slice(0, 10);
  const blobName = `${clientIP}_${today}`;
  const blockBlobClient = containerClient.getBlockBlobClient(blobName);

  try {
    const content = await blockBlobClient.download();
    const data = JSON.parse((await content.readToEnd()).toString());

    if (data.count >= maxRequests) {
      return { allowed: false, remaining: 0 };
    }

    data.count++;
    await blockBlobClient.upload(JSON.stringify(data), JSON.stringify(data).length, {
      overwrite: true
    });

    return { allowed: true, remaining: maxRequests - data.count };
  } catch (error) {
    // 首次访问
    const data = { count: 1, date: today };
    await blockBlobClient.upload(JSON.stringify(data), JSON.stringify(data).length);
    return { allowed: true, remaining: maxRequests - 1 };
  }
}
```

#### 方案 2: 使用 Redis（更快）

```javascript
const Redis = require('ioredis');
const redis = new Redis(process.env.REDIS_CONNECTION_STRING);

async function checkRateLimit(clientIP, maxRequests = 100, windowMs = 3600000) {
  const key = `ratelimit:${clientIP}`;
  const count = await redis.incr(key);

  if (count === 1) {
    await redis.expire(key, windowMs / 1000);
  }

  return {
    allowed: count <= maxRequests,
    remaining: Math.max(0, maxRequests - count),
    reset: await redis.pexpire(key)
  };
}
```

#### 方案 3: 简单的内存限流（开发环境）

```javascript
const ipLimits = new Map();

function checkRateLimit(clientIP, maxRequests = 100, windowMs = 3600000) {
  const now = Date.now();

  if (!ipLimits.has(clientIP)) {
    ipLimits.set(clientIP, { count: 1, resetTime: now + windowMs });
    return { allowed: true, remaining: maxRequests - 1 };
  }

  const limit = ipLimits.get(clientIP);

  if (now > limit.resetTime) {
    limit.count = 1;
    limit.resetTime = now + windowMs;
    return { allowed: true, remaining: maxRequests - 1 };
  }

  if (limit.count >= maxRequests) {
    return { allowed: false, remaining: 0, resetTime: limit.resetTime };
  }

  limit.count++;
  return { allowed: true, remaining: maxRequests - limit.count };
}
```

### 使用速率限制

```javascript
app.http('api-endpoint', {
  methods: ['POST'],
  authLevel: 'anonymous',
  route: 'api/endpoint',
  handler: async (request, context) => {
    const clientIP = request.headers.get('x-forwarded-for') || 'unknown';
    const limit = await checkRateLimit(clientIP, 100);

    if (!limit.allowed) {
      return jsonResponse({
        error: 'Too many requests',
        retryAfter: Math.ceil((limit.resetTime - Date.now()) / 1000)
      }, 429, corsHeaders);
    }

    // 处理请求...
  }
});
```

### Cloudflare 速率限制

Cloudflare 提供 Enterprise 级别的 DDoS 防护和速率限制。

---

## 安全响应头

### 添加安全头

```javascript
const securityHeaders = {
  'X-Content-Type-Options': 'nosniff',              // 防止 MIME 类型嗅探
  'X-Frame-Options': 'DENY',                        // 防止点击劫持
  'X-XSS-Protection': '1; mode=block',              // XSS 保护
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains', // HSTS
  'Content-Security-Policy': "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';", // CSP
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Permissions-Policy': 'geolocation=(), microphone=(), camera=()'
};

// 在所有响应中添加
app.http('example', {
  handler: async (request, context) => {
    return {
      status: 200,
      headers: {
        ...getCorsHeaders(request),
        ...securityHeaders
      },
      body: JSON.stringify(data)
    };
  }
});
```

### 通过 Cloudflare 添加

Cloudflare Dashboard → Workers & Pages → Your Project → HTTP Headers

---

## OAuth 安全

### GitHub OAuth 最佳实践

#### 1. 使用 PKCE（推荐）

PKCE (Proof Key for Code Exchange) 防止授权码拦截攻击。

```javascript
// 生成 code_verifier 和 code_challenge
function generatePKCE() {
  const codeVerifier = base64UrlEncode(crypto.randomBytes(32));
  const codeChallenge = base64UrlEncode(
    crypto.createHash('sha256').update(codeVerifier).digest()
  );
  return { codeVerifier, codeChallenge };
}
```

#### 2. 验证 state 参数

防止 CSRF 攻击。

```javascript
// 生成 state
const state = crypto.randomBytes(16).toString('base64');

// 存储到 session
await session.set('oauth_state', state);

// 验证
const returnedState = request.query.get('state');
const storedState = await session.get('oauth_state');

if (returnedState !== storedState) {
  return { error: 'Invalid state parameter' };
}
```

#### 3. 限制回调 URL 为 HTTPS

在 GitHub OAuth App 设置中，只允许 HTTPS 回调 URL。

#### 4. 设置合理的 token 过期时间

```javascript
const JWT_EXPIRES_IN = '2h'; // 访问令牌：2 小时
const REFRESH_TOKEN_EXPIRES_IN = '7d'; // 刷新令牌：7 天
```

---

## 输入验证

### 验证用户输入

```javascript
function validateInput(data, schema) {
  const errors = [];

  for (const [field, rules] of Object.entries(schema)) {
    const value = data[field];

    if (rules.required && !value) {
      errors.push(`${field} is required`);
      continue;
    }

    if (value) {
      if (rules.type && typeof value !== rules.type) {
        errors.push(`${field} must be ${rules.type}`);
      }

      if (rules.maxLength && value.length > rules.maxLength) {
        errors.push(`${field} must be less than ${rules.maxLength} characters`);
      }

      if (rules.pattern && !rules.pattern.test(value)) {
        errors.push(`${field} format is invalid`);
      }
    }
  }

  return errors;
}

// 使用
app.http('interpret', {
  handler: async (request, context) => {
    const body = await request.json();

    const schema = {
      question: { required: true, type: 'string', maxLength: 500 },
      currentGua: { required: true, type: 'string', maxLength: 100 },
      style: { type: 'string', pattern: /^(classic|daoist)$/ }
    };

    const errors = validateInput(body, schema);
    if (errors.length > 0) {
      return jsonResponse({ errors }, 400, corsHeaders);
    }

    // 处理请求...
  }
});
```

---

## 日志和监控

### 启用 Application Insights

```bash
# 创建 Application Insights
az monitor app-insights component create \
  --app myapp-insights \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP

# 获取 Instrumentation Key
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
  --app myapp-insights \
  --resource-group $RESOURCE_GROUP \
  --query instrumentationKey -o tsv)

# 配置 Function App
az functionapp config appsettings set \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --settings \
    APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=$INSTRUMENTATION_KEY"
```

### 记录安全事件

```javascript
function logSecurityEvent(eventType, details) {
  console.log(JSON.stringify({
    type: 'security_event',
    eventType,
    details,
    timestamp: new Date().toISOString()
  }));
}

// 使用
if (!checkRateLimit(clientIP).allowed) {
  logSecurityEvent('rate_limit_exceeded', {
    clientIP,
    endpoint: request.url
  });
}
```

---

## 定期安全审计

### 检查清单

- [ ] 每月审查 Azure Advisor 安全建议
- [ ] 每季度轮换密钥
- [ ] 定期更新依赖包
- [ ] 审查访问日志
- [ ] 检查漏洞扫描结果

### 依赖更新

```bash
# 检查过时的包
npm outdated

# 更新依赖
npm update

# 审计安全性
npm audit

# 修复安全问题
npm audit fix
```

---

## 资源链接

- [Azure Security Best Practices](https://docs.microsoft.com/azure/security/fundamentals/best-practices)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OAuth 2.0 Security Best Current Practice](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics)

---

**最后更新**: 2026-01-23
