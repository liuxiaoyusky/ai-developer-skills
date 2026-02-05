# n8n MCP & Workflow Automation

用于 n8n MCP 开发和工作流自动化的 Claude Code 技能。

## 简介

这个技能提供了创建 n8n MCP 服务器和程序化生成 n8n 工作流的完整指南。包含 MCP 服务器模板、常用节点类型、连接模式、工作流创建模式和最佳实践。

## 使用场景

- "创建 n8n MCP 服务器"
- "生成 n8n workflow"
- "n8n 工作流自动化"
- "使用 n8n API 创建工作流"
- "n8n 和 AI Agent 集成"

## 主要内容

### MCP 服务器模板
- 完整的 TypeScript MCP 服务器代码
- 4个核心工具（trigger_workflow, create_workflow, list_workflows, get_workflow）
- package.json 配置示例

### n8n 工作流结构
- 工作流 JSON 结构详解
- 常用节点类型参考（Webhook, HTTP Request, Code, Set, IF）
- 连接模式（线性流、条件分支、多输出）

### 工作流创建模式
- Webhook → Process → Respond
- Scheduled Task → Process → Notify
- Error Handling with IF Node

### 最佳实践
- 在 UI 中先测试再导出 JSON
- 使用描述性节点名称
- 视觉化组织节点
- 工作流版本控制
- 优雅的错误处理

## 依赖要求

- 自托管的 n8n 实例（API 访问需要）
- Node.js 18+（用于 MCP 服务器）
- n8n API 密钥

## 外部资源

- [Create Dynamic Workflows Programmatically](https://n8n.io/workflows/4544-create-dynamic-workflows-programmatically-via-webhooks-and-n8n-api/)
- [Automate creation of n8n workflows via Agents](https://community.n8n.io/t/automate-creation-of-n8n-workflows-via-agents/118650)
- [n8n workflow manager API](https://n8n.io/workflows/4166-n8n-workflow-manager-api/)
- [n8n API Documentation](https://docs.n8n.io/api/)

## 许可证

MIT License
