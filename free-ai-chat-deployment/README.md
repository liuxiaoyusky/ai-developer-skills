# free-ai-chat-deployment 技能

## 概述

这是一个用于部署 AI 聊应用到 Cloudflare Pages + Azure Functions + 阿里云域名的完整技能。

## 技能结构

```
free-ai-chat-deployment/
├── skill.md                      # 主技能文档（从这里开始）
├── README.md                     # 本文件
├── templates/                    # 代码模板
│   ├── backend/
│   │   ├── host.json            # Azure Functions SSE 配置
│   │   ├── index.js             # 主入口和 CORS 配置
│   │   └── streaming.js         # SSE 流式处理模板
│   ├── frontend/
│   │   └── client.js            # SSE 客户端实现
│   └── config/
│       ├── wrangler.toml        # Cloudflare Pages 配置
│       └── env.example          # 环境变量模板
├── scripts/                     # 自动化脚本
│   ├── 01-init-azure.sh         # 初始化 Azure 资源
│   ├── 02-deploy-backend.sh     # 部署后端
│   ├── 03-deploy-frontend.sh    # 部署前端
│   ├── 04-configure-dns.sh      # DNS 配置指南
│   └── 05-test-deployment.sh    # 部署验证测试
└── docs/                        # 详细指南
    ├── cost-optimization.md     # 成本优化指南
    ├── security-hardening.md    # 安全加固指南
    └── troubleshooting.md       # 故障排除指南
```

## 快速开始

### 1. 阅读主文档

首先阅读 `skill.md`，它包含：
- 前置准备
- 快速开始指南
- SSE 实现说明
- 基本的故障排除

### 2. 使用代码模板

从 `templates/` 目录复制模板到你的项目：

```bash
# 复制后端配置
cp templates/backend/host.json your-project/backend/
cp templates/backend/index.js your-project/backend/src/
cp templates/backend/streaming.js your-project/backend/src/

# 复制前端代码
cp templates/frontend/client.js your-project/frontend/src/api/

# 复制配置文件
cp templates/config/wrangler.toml your-project/
cp templates/config/env.example your-project/.env.example
```

### 3. 运行自动化脚本

按顺序运行脚本：

```bash
# 1. 初始化 Azure 资源
./scripts/01-init-azure.sh

# 2. 配置环境变量（手动）
# 编辑 Azure Portal 或使用 CLI

# 3. 部署后端
export RESOURCE_GROUP="your-rg"
export FUNCTION_APP="your-api"
./scripts/02-deploy-backend.sh

# 4. 部署前端
export PROJECT_NAME="your-project"
./scripts/03-deploy-frontend.sh

# 5. 配置 DNS（按照指南手动操作）
./scripts/04-configure-dns.sh

# 6. 测试部署
./scripts/05-test-deployment.sh
```

### 4. 阅读详细指南

根据需要查看详细文档：

- **成本优化**: `docs/cost-optimization.md`
- **安全加固**: `docs/security-hardening.md`
- **故障排除**: `docs/troubleshooting.md`

## 主要特性

### ✅ SSE 流式传输

完整的 Server-Sent Events 实现，包括：
- 后端流式处理模板
- 前端客户端实现
- 心跳机制
- 错误处理

### ✅ CORS 多域名支持

支持多种域名类型：
- 本地开发 (`localhost:5173`)
- Cloudflare Pages (`*.pages.dev`)
- 自定义域名 (`your-domain.com`)

### ✅ 自动化脚本

半自动化部署流程：
- Azure 资源初始化
- 后端和前端部署
- DNS 配置指南
- 部署验证测试

### ✅ 成本优化

详细的成本分析和优化策略：
- Azure Functions 定价选择
- Cloudflare Pages 免费使用
- 监控和预算告警
- 性能优化建议
- **真实成本数据：$12.36/年（个人项目实际案例）** 🆕
- **成本扩展预测和规模经济分析** 🆕
- **与替代方案对比（85% 比 VPS 便宜）** 🆕

### ✅ 生产调试最佳实践 🆕

**防止"部署成功但问题依旧"的验证差距**：
- The Verification Gap 理论框架
- 4 个核心调试理论
- 生产环境验证流程（Step-by-step）
- 真实案例研究（失败 vs 正确做法）
- 5 条黄金调试法则
- Cache-busting 验证方法

### ✅ 安全加固

全面的安全最佳实践：
- Azure Key Vault 密钥管理
- HTTPS 强制
- 速率限制
- 安全响应头
- OAuth 安全

## 环境变量

必需的环境变量：

```bash
# Azure
export RESOURCE_GROUP="your-resource-group"
export FUNCTION_APP="your-function-app"
export STORAGE_ACCOUNT="your-storage-account"

# Cloudflare
export PROJECT_NAME="your-project-name"

# 自定义域名
export CUSTOM_DOMAIN="your-domain.example.com"
```

## 应用程序设置

后端环境变量（在 Azure Function App 中配置）：

```bash
YOUR_API_KEY              # AI 服务 API 密钥
JWT_SECRET               # JWT 签名密钥（使用 openssl 生成）
GITHUB_CLIENT_ID         # GitHub OAuth 客户端 ID
GITHUB_CLIENT_SECRET     # GitHub OAuth 客户端密钥
DATABASE_URL            # 数据库连接字符串（可选）
```

## 常见使用场景

### 场景 1: 从零开始部署新项目

1. 阅读完整的 `skill.md`
2. 复制所有模板到你的项目
3. 按顺序运行 `scripts/01-*.sh` 到 `05-*.sh`
4. 根据需要参考 `docs/` 中的指南

### 场景 2: 添加 SSE 到现有项目

1. 复制 `templates/backend/streaming.js`
2. 更新 `host.json` 启用流式传输
3. 复制 `templates/frontend/client.js`
4. 按照 `skill.md` 中的 SSE 实现说明操作

### 场景 3: 配置自定义域名

1. 运行 `./scripts/04-configure-dns.sh`
2. 按照指南在阿里云配置 DNS
3. 更新 CORS 配置
4. 运行 `./scripts/05-test-deployment.sh` 验证

### 场景 4: 成本优化

1. 阅读 `docs/cost-optimization.md`
2. 设置预算告警
3. 实施优化策略
4. 监控使用量

### 场景 5: 安全加固

1. 阅读 `docs/security-hardening.md`
2. 配置 Azure Key Vault
3. 实施速率限制
4. 添加安全响应头

## 故障排除

遇到问题？

1. 首先查看 `docs/troubleshooting.md`
2. 运行 `./scripts/05-test-deployment.sh` 诊断
3. 查看 Azure 和 Cloudflare 的日志

## 贡献

这是一个可重用的技能，基于实际项目经验创建。

如果你有改进建议，请：
1. 更新相关文档
2. 测试所有脚本
3. 提交你的更改

## 版本

**v1.0.0** (2026-01-23)
- 初始版本
- 完整的部署流程
- SSE 流式传输支持
- 成本优化和安全指南

## 许可

MIT License

---

**祝你部署顺利！** 🚀
