# AI Developer Skills

AI 辅助开发技能集合 - 为 Claude Code 提供的实用技能包

## 简介

这是一个 Claude Code 的技能市场（Skills Marketplace），包含多个实用的开发技能，帮助您提高开发效率。

## 包含的技能

### 1. Doc Auditor (doc-auditor)
AI 辅助的项目文档审计工具。扫描项目中的 Markdown 文档，收集上下文信息（Git 历史、文档结构、引用有效性），AI 分析文档类型和重要性，与用户交互式确认处理方式。

**使用场景**：
- "清理过时文档"
- "检查文档是否过时"
- "审计项目文档"
- "整理文档库"

### 2. Conversation Exporter (general/conversation-exporter)
导出 Claude Code 对话历史为 Markdown 格式。支持三种导出模式：精简、标准、详细。帮助您保存重要对话、创建文档、分享团队知识。

**使用场景**：
- "导出当前对话为 Markdown"
- "导出这次调试会话的详细记录"
- "保存这段对话作为参考文档"

### 3. Free AI Chat Deployment (free-ai-chat-deployment)
免费部署 AI 聊天应用到多云环境（Cloudflare Pages + Azure Functions + 阿里云域名）。包含前端部署、后端 API 配置、自定义域名设置、SSE 流式传输等完整流程。

**使用场景**：
- "帮我部署一个 AI 聊天应用"
- "使用 Cloudflare 和 Azure 部署全栈应用"
- "配置自定义域名"

### 4. Debug (general/debug)
系统化问题解决技能 - 整合 5 Whys 根因分析和第一性原理重建思维，提供三层问题解决模型（问题分类 → 双轨调查 → 四重解决）、双轨调试方法、生产环境验证和工具使用指南。适用于故障排查、性能优化、系统重构和创新突破。

**使用场景**：
- "使用 debug 技能分析这个问题"
- "帮我用 5 Whys 方法找出根本原因"
- "用第一性原理重新思考这个问题"
- "验证生产环境中的问题"
- "系统性能优化"

### 5. First Principles (general/first-principles)
马思克式第一性原理思维 - 将复杂问题拆解到基本真理，从零重建解决方案。区别于类比思维和根因分析（5 Whys），用于创新突破和挑战假设。

**使用场景**：
- "使用第一性原理思考这个问题"
- "如何从零重新设计这个系统？"
- "挑战所有现有假设"
- "找到突破性创新方案"

### 6. First Principles Planner (general/first-principles-planner)
基于第一性原理的项目规划器。通过深度对话和追问，帮助用户从想法中提炼出 3-5 个核心功能，定义实现程度（MVP vs 完整版），并制定可验收的实施计划。

**使用场景**：
- "规划新项目"
- "设计功能需求"
- "制定实施计划"
- "梳理项目思路"
- "我想做一个..."

### 7. Ralph Wiggum (general/ralph-wiggum)
搭建用于 Ralph Wiggum 的 bash 文件和相关文件，适合长期自运行自迭代项目。支持 Build 模式（一键启动）和 Plan 模式（交互式配置），跨平台支持（Linux/macOS/Windows），默认集成 debug skills 加速迭代。现已集成 first-principles-planner，可自动生成实施计划。

**使用场景**：
- "开始 ralph 循环"
- "启动 ralph"
- "ralph wiggum"
- "使用 ralph 自动开发"
- "长期项目"
- "启动loop"

## 安装方法

### 在 Claude Code VSCode 扩展中安装

1. 打开 Claude Code 面板
2. 输入 `/plugins` 打开插件管理界面
3. 切换到 **Marketplaces** 标签页
4. 添加 marketplace：`liuxiaoyusky/ai-developer-skills`
5. 点击刷新图标
6. 切换到 **Plugins** 标签页
7. 安装您需要的技能

### 在 Claude Code CLI 中安装

```bash
# 添加 marketplace
claude plugin marketplace add liuxiaoyusky/ai-developer-skills

# 安装特定技能
claude plugin install doc-auditor@liuxiaoyusky
claude plugin install conversation-exporter@liuxiaoyusky
claude plugin install free-ai-chat-deployment@liuxiaoyusky
claude plugin install debug@liuxiaoyusky
claude plugin install first-principles@liuxiaoyusky
claude plugin install first-principles-planner@liuxiaoyusky
claude plugin install ralph-wiggum@liuxiaoyusky
```

## 更新技能

### 更新已安装的技能

**通过 CLI 更新：**
```bash
# 更新特定技能
claude plugin update ralph-wiggum@liuxiaoyusky

# 更新所有来自此 marketplace 的技能
claude plugin marketplace update ai-developer-skills
```

**通过 VSCode 扩展更新：**
1. 打开 `/plugins` 命令
2. 切换到 **Marketplaces** 标签页
3. 找到 `liuxiaoyusky/ai-developer-skills`
4. 点击刷新图标更新到最新版本
5. 切换到 **Plugins** 标签页
6. 找到需要更新的技能，点击更新图标

**重新加载技能：**
如果技能文件已更新但未生效：
- VSCode: `Cmd+Shift+P` → "Reload Window"
- 或重启 Claude Code

### 开发者本地测试

如果你正在开发技能并想测试修改：
1. 修改 `SKILL.md` 或相关文件
2. 重新加载 VSCode 窗口
3. 技能会自动重新加载（无需重新安装）

## 使用方法

安装后，您可以直接在对话中提到技能名称：

```
"使用 doc-auditor 技能来审计我的项目文档"

"使用 conversation-exporter 技能导出当前对话"

"使用 free-ai-chat-deployment 技能部署我的 AI 应用"

"使用 debug 技能分析这个问题"

"使用 first-principles 技能重新思考这个问题"

"使用 first-principles-planner 技能规划我的新项目"

"使用 ralph-wiggum 技能自动开发项目"
```

## 技能开发

每个技能都是自包含的，包含：
- `SKILL.md` - 技能定义文件（包含 YAML frontmatter 和详细说明）
- 相关资源文件（脚本、模板、文档等）

### 创建新技能

1. 在仓库中创建新目录
2. 创建 `SKILL.md` 文件，包含以下 frontmatter：

```yaml
---
name: your-skill-name
description: A clear description of what this skill does and when to use it
---
```

3. 添加技能的详细说明和使用指南
4. 更新 `.claude-plugin/marketplace.json`，添加新技能
5. 提交更改到仓库

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 作者

[@liuxiaoyusky](https://github.com/liuxiaoyusky)
