# 成本优化指南

## 概述

本指南帮助你优化部署在 Cloudflare Pages + Azure Functions + 阿里云域名的 AI 聊天应用的成本。

---

## 成本结构

### Azure Functions

#### Consumption Plan（推荐）

**免费额度**:
- 每月 100 万次请求
- 400,000 GB-s 资源消耗
- 每月免费赠款（因地区而异）

**付费标准**:
- ¥0.75 / 百万次执行
- ¥0.000016 / GB-s
- 数据传输：¥0.87 / GB

**估算**:

| 流量级别 | 日请求数 | 月成本（人民币） |
|---------|---------|----------------|
| 低流量 | < 10K | ¥0-30 |
| 中等流量 | 10K-100K | ¥140-350 |
| 高流量 | > 100K | ¥350+ |

#### Flex Consumption Plan

**适用场景**:
- 需要更一致的性能
- 更少的冷启动
- 可预测的成本

**成本**: 比 Consumption 高约 20-30%，但性能更稳定。

### Cloudflare Pages

**免费 tier**（推荐）:
- ✅ 无限带宽
- ✅ 500 次构建/月
- ✅ 全球 CDN
- ✅ DDoS 防护
- ✅ 免费 SSL/TLS

**付费 tier**:
- $20/月：20,000 次构建
- 适用于需要频繁构建的项目

### 阿里云域名

**成本**:
- .com 域名：¥80-120/年
- .tech 域名：¥30-50/年
- 其他域名：价格不等

---

## 总成本估算

### 低流量场景（< 10K 请求/天）

- Azure Functions: ¥0-30/月（免费额度内）
- Cloudflare Pages: ¥0/月
- 域名：¥80-120/年（约 ¥7-10/月）
- **总计**: 约 ¥7-40/月

### 中等流量场景（10K-100K 请求/天）

- Azure Functions: ¥140-350/月
- Cloudflare Pages: ¥0/月
- 域名：¥7-10/月
- **总计**: 约 ¥150-370/月

### 高流量场景（> 100K 请求/天）

- Azure Functions: ¥350+/月
- Cloudflare Pages: ¥0-20/月
- 域名：¥7-10/月
- **总计**: 约 ¥360+/月

---

## Real-World Cost Analysis (2026)

### 实际部署案例：青鸾易测

**部署架构**:
- 前端: Cloudflare Pages
- 后端: Azure Functions (Flex Consumption)
- 域名: 自定义域名 (volaris.skyliu.tech)

### 实际成本分解

| 组件 | 月成本 | 年成本 | 占比 |
|------|--------|--------|------|
| Cloudflare Pages (前端) | $0.00 | $0.00 | 0% |
| Azure Functions (后端) | $0.03 | $0.36 | 3% |
| 域名 (volaris.skyliu.tech) | $1.00 | $12.00 | 97% |
| **总计** | **$1.03** | **$12.36** | **100%** |

**注意**:
- Cloudflare Pages 完全在免费额度内（无限请求、无限带宽）
- Azure Functions 极低使用量（个人项目）
- **域名是主要成本**（97%）

### 成本扩展预测

| 用户规模 | 月成本 | 年成本 | 用户数 | 每用户成本 |
|---------|--------|--------|--------|-----------|
| 个人项目 | $1.03 | $12.36 | 5-10 DAU | $0.10/月 |
| 小型生产 | $1.28 | $15.36 | 50-100 DAU | $0.01/月 |
| 流行应用 | $3.76 | $45.12 | 500-1000 DAU | $0.004/月 |
| 规模应用 | $27.76 | $333.12 | 5000-10000 DAU | $0.003/月 |

**分析**: Serverless 模型下，规模越大成本效率越高

### 与替代方案对比

#### Option A: 当前 Serverless 架构
```
前端: Cloudflare Pages (免费)
后端: Azure Functions Flex Consumption
域名: $12/年
总计: $12.36/年
```

#### Option B: 传统 VPS/VM
```
VPS: DigitalOcean Basic ($6/月)
域名: $1/月
总计: $84/年

维护开销:
- 服务器管理
- 安全更新
- 手动扩展
- 备份管理
```

**当前架构节省**: $71.64/年（**85% 更便宜**）

#### Option C: AWS Lambda + CloudFront
```
Lambda: 类似 Azure Functions
CloudFront: 免费层 1 年后过期
Route53: $0.50/月 (托管区域)
总计: ~$18/年

1 年后: CloudFront 成本增加
```

**当前架构优势**: 更简单的定价、可预测性

#### Option D: 完整 Azure (App Service)
```
App Service: $10-50/月 (Basic 层级)
Database: $5-15/月 (SQL)
域名: $1/月
总计: $192-792/年

当前流量使用过度
```

**当前架构优势**: 94-98% 更便宜

### 效率指标

#### 每用户成本

| 场景 | 月成本 | 用户 | 每用户/月成本 |
|------|--------|------|--------------|
| 个人 | $1.03 | 10 | $0.10 |
| 小型生产 | $1.28 | 100 | $0.01 |
| 流行应用 | $3.76 | 1000 | $0.004 |

**分析**: Serverless 模型规模效应显著

#### 每请求成本

| 场景 | 月成本 | 请求数 | 每 1000 请求成本 |
|------|--------|--------|------------------|
| 个人 | $0.03 | 3,000 | $0.01 |
| 小型生产 | $0.28 | 30,000 | $0.009 |
| 流行应用 | $2.76 | 300,000 | $0.009 |

**分析**: Serverless 定价具有规模经济

#### 盈亏平衡分析

**当前 vs 传统 VPS**:
```
VPS 成本: $6/月（固定）
当前成本: $1.03 + ($0.27 每 30k 请求)

盈亏平衡点:
$6 - $1.03 = $4.97
$4.97 / $0.27 × 30,000 = 552,000 请求/月

在当前定价下，只有当超过 552k 请求/月时，
传统 VPS 才更便宜
```

**结论**: 对于绝大多数应用，当前架构更便宜

---

## 优化策略

### 1. 监控使用量

**Azure CLI**:

```bash
# 查看使用量
az consumption usage list \
  --resource-group $RESOURCE_GROUP \
  --output table

# 查看 Function App 统计
az monitor activity-log list \
  --resource-group $RESOURCE_GROUP \
  --caller $(az account show --query user.name -o tsv)
```

**Azure Portal**:
1. 访问 Function App
2. 点击 "Metrics"
3. 选择关键指标：
   - Execution Count
   - Response Time
   - Memory Usage

### 2. 设置预算告警

```bash
# 创建月度预算
az consumption budget create \
  --name monthly-budget \
  --resource-group $RESOURCE_GROUP \
  --amount 50 \
  --time-grain Monthly \
  --category cost \
  --notifications \
    threshold=80 \
    contact-emails=admin@example.com
```

**在 Portal 中设置**:
1. Cost Management + Billing
2. Cost Management
3. Budgets
4. Create Budget

### 3. 优化代码性能

#### 减少 Cold Start 时间

**❌ 不好的做法**:
```javascript
// 同步加载大量依赖
const heavyLibrary = require('heavy-library');
const data = loadLargeDataSet();

app.http('endpoint', {
  handler: async (request, context) => {
    // 每次冷启动都要加载
  }
});
```

**✅ 好的做法**:
```javascript
// 懒加载依赖
let heavyLibrary;

app.http('endpoint', {
  handler: async (request, context) => {
    if (!heavyLibrary) {
      heavyLibrary = require('heavy-library');
    }
    // 只在需要时加载
  }
});
```

#### 优化 AI API 调用

**使用流式传输**:
- 减少 max_tokens（如果不需要长响应）
- 使用合理的 temperature（0.7 通常够用）
- 缓存常见响应

**三步处理模式**:
- 将长请求拆分为多个短请求
- 减少单次请求超时风险
- 更好的用户体验

#### 实现缓存

```javascript
// 简单的内存缓存
const cache = new Map();
const CACHE_TTL = 5 * 60 * 1000; // 5 分钟

function getCached(key) {
  const cached = cache.get(key);
  if (cached && Date.now() - cached.time < CACHE_TTL) {
    return cached.data;
  }
  return null;
}

function setCache(key, data) {
  cache.set(key, { data, time: Date.now() });
}
```

### 4. 选择合适的定价层级

#### 何时使用 Consumption Plan？

- ✅ 流量不稳定
- ✅ 开发和测试环境
- ✅ 预算有限
- ✅ 可以容忍偶尔的冷启动

#### 何时使用 Flex Consumption/Premium？

- ✅ 需要一致的性能
- ✅ 流量较大且稳定
- ✅ 不能容忍冷启动
- ✅ 需要更长的时间限制

### 5. 优化 Cloudflare Pages 构建

**减少构建时间**:
- 缓存 `node_modules`
- 使用增量构建
- 最小化静态资源

```bash
# .gitignore
node_modules/
dist/
.cache/
```

**减少构建次数**:
- 合并 Pull Requests
- 使用 Preview deployments
- 避免不必要的提交

### 6. 使用 Azure Reserved Instances

如果你预计长期使用高流量，可以考虑：

- Reserved Capacity：预付 1 年或 3 年
- 节省约 30-60% 的成本

---

## 成本监控脚本

创建 `scripts/monitor-costs.sh`:

```bash
#!/bin/bash

RESOURCE_GROUP="${RESOURCE_GROUP:-myapp-rg}"

echo "=== Azure Functions 成本监控 ==="
echo ""

# 本月成本
az consumption usage list \
  --resource-group $RESOURCE_GROUP \
  --query "[?contains(properties.usageStart, '$(date +%Y-%m)')].{Name:name, Cost:properties.pretaxCost}" \
  --output table

echo ""
echo "=== 预算状态 ==="
az consumption budget list \
  --resource-group $RESOURCE_GROUP \
  --output table
```

---

## 常见问题

### Q: 如何降低 Azure Functions 成本？

A:
1. 优化代码减少执行时间
2. 使用缓存减少重复调用
3. 选择合适的定价层级
4. 监控使用量，设置预算告警

### Q: Cloudflare Pages 真的免费吗？

A: 是的，免费 tier 包含：
- 无限带宽和请求
- 500 次构建/月
- 全球 CDN
- 免费 SSL

除非你需要频繁构建（>500 次/月），否则不需要付费。

### Q: 如何估算我的成本？

A:
1. 从 Consumption Plan 开始
2. 监控一个月的使用量
3. 根据实际使用量选择合适的定价层级
4. 使用 Azure Pricing Calculator：https://azure.microsoft.com/pricing/calculator/

---

## 资源链接

- [Azure Functions Pricing](https://azure.microsoft.com/pricing/details/functions/)
- [Azure Cost Management](https://azure.microsoft.com/services/cost-management/)
- [Cloudflare Pages Pricing](https://developers.cloudflare.com/pages/platform/pricing-planes/)
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)

---

**最后更新**: 2026-01-23
