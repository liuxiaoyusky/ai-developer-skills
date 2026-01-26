# Ralph Wiggum Skill

基于 Bash 循环的 Ralph Wiggum 技术，让 AI 持续迭代直到完成所有任务。

## 什么是 Ralph Wiggum？

Ralph Wiggum 是一个 AI 开发方法论，通过简单的 Bash 循环让 Claude Code 持续迭代，自主完成开发任务。它由 Geoffrey Huntley 在 2025 年创造，已成为 AI 辅助开发的核心技术之一。

**核心思想**：
- **默认第一次不会写对** - 接受 AI 需要多次迭代
- **失败是有价值的数据** - 错误信息帮助 AI 改进
- **持续直到完成** - 自动重试，无需人工干预

## 核心特性

- ✅ **零交互运行** - 首次配置后，完全自动运行
- ✅ **跨平台支持** - Linux/macOS/Windows 全平台
- ✅ **深度调试集成** - 默认集成 debug skills，加速错误修复
- ✅ **自动完成检测** - 基于任务清单，自动停止
- ✅ **简单高效** - 保留原始 Bash 循环的简洁性

## 快速开始

### 5 分钟上手

#### 1. 创建项目

```bash
mkdir my-project && cd my-project
git init
```

#### 2. 启动 Plan 模式（首次配置）

```bash
/ralph-wiggum plan
```

**交互式配置**：
- 是否添加 debug skills marketplace？建议 `Y`
- 选择模型？建议 `4`（默认）
- 最大迭代次数？建议 `0`（无限）

Plan 模式会自动执行：
```bash
claude plugin marketplace add liuxiaoyusky/ai-developer-skills
```

这将提供强大的 `/debug` skill，包含：
- 根本原因分析（5 Whys）
- 生产环境验证指南
- 工具使用最佳实践
- 常见调试陷阱避免

#### 3. 编辑 AGENTS.md

添加你的任务清单：

```markdown
## Tasks

- [ ] 实现用户登录功能
- [ ] 添加数据持久化
- [ ] 编写单元测试
```

#### 4. 启动 Build 模式

```bash
/ralph-wiggum
```

Ralph 将持续工作，直到所有任务完成！

---

## 使用场景

### 场景 1：新项目开发

从零开始开发新项目，Ralph 自动完成所有任务。

```bash
mkdir new-project && cd new-project
/ralph-wiggum plan
# 编辑 AGENTS.md
/ralph-wiggum
```

### 场景 2：功能迭代

在现有项目中添加新功能。

```bash
cd existing-project
/ralph-wiggum plan  # 更新任务清单
/ralph-wiggum
```

### 场景 3：Bug 修复和重构

让 Ralph 持续修复问题，直到所有测试通过。

```bash
# 在 AGENTS.md 中添加：
# - [ ] 修复登录超时问题
# - [ ] 修复内存泄漏
# - [ ] 所有测试通过

/ralph-wiggum
```

---

## 工作模式

### Build 模式（默认）

一键启动，完全自动运行。

```bash
/ralph-wiggum
```

**适用场景**：
- 项目已配置好 AGENTS.md
- 需要立即开始迭代
- 希望零交互运行

### Plan 模式（交互式配置）

首次使用或需要重新配置时使用。

```bash
/ralph-wiggum plan
```

**适用场景**：
- 首次使用 Ralph Wiggum
- 需要选择特定的模型
- 需要更新任务清单
- 需要重新规划优先级

---

## 核心文件

### AGENTS.md（最重要）

**模板文件**：`templates/agents_template.md` → 复制到项目并重命名为 `AGENTS.md`

项目的**单一真相来源**，包含：
- 构建命令
- 验证命令（测试、类型检查、Lint）
- 任务清单（使用 `- [ ]` 格式）
- 项目运行注意事项
- Debug skills 引用

**示例**：
```markdown
## Build & Run

npm run build

## Validation

- Tests: `npm test`
- Typecheck: `npm run typecheck`
- Lint: `npm run lint`

## Tasks

- [ ] 实现用户登录
- [x] 设置项目结构
- [ ] 编写单元测试
```

### PROMPT_build.md

告诉 Claude 如何实现任务的关键指令。

### loop.sh / loop.bat

自动生成的循环脚本，持续调用 Claude CLI。

---

## 关键概念

### 任务清单

使用 Markdown checkbox 格式：
- `- [ ]` - 未完成
- `- [x]` - 已完成

Ralph 自动检测所有任务完成时停止循环。

### 完成检测

循环脚本检查 AGENTS.md 中是否还有未完成的任务：

```bash
if grep -q '\- \[ \]' AGENTS.md; then
    # 还有未完成的任务，继续循环
else
    # 所有任务都完成了
    echo "✅ 所有任务已完成！"
    break
fi
```

### Debug Skills 集成

当遇到错误时，Ralph 自动调用 debug skill：

```
1. 尝试标准调试（最多 3 次）
2. 如果仍卡住，调用 /debug skill
3. Debug skill 分析并修复问题
4. 继续迭代
```

---

## 最佳实践

### 1. 任务拆分

**好的任务**：
- ✅ 实现用户登录功能（包含表单验证、JWT token）
- ✅ 添加数据持久化（使用 SQLite，CRUD 操作）

**不好的任务**：
- ❌ 实现完整应用（太大）
- ❌ 修复 bug（太模糊）

### 2. 编写有效的 AGENTS.md

**包含**：
- ✅ 清晰的构建命令
- ✅ 完整的验证命令
- ✅ 具体的任务描述（包含验收标准）

**避免**：
- ❌ 状态更新或进度记录
- ❌ 重复或模糊的信息

### 3. Let Ralph Ralph

- ✅ 信任 Ralph，让它自己决定如何实现
- ✅ 接受迭代，第一次可能不完美
- ✅ 观察和学习，注意 Ralph 如何解决问题
- ✅ 添加 guardrails，在 PROMPT 中添加关键规则

### 4. 何时重新规划

**应该**：
- ✅ 需求发生重大变化
- ✅ Ralph 持续实现错误功能
- ✅ 任务优先级需要调整

**不应该**：
- ❌ 遇到暂时错误（让 Ralph 自己解决）
- ❌ 对实现方式有不同意见

---

## 常见问题

### Q: 循环不前进怎么办？

A: 检查以下几点：
1. AGENTS.md 中的任务描述是否清晰
2. Validation 命令是否正确
3. PROMPT_build.md 中的指令是否明确
4. 如果问题持续，重新运行 `/ralph-wiggum plan`

### Q: 如何停止循环？

A: 按 `Ctrl+C` 停止循环。或者等待所有任务完成，循环会自动停止。

### Q: 支持哪些操作系统？

A: Linux、macOS 和 Windows。Skill 会自动检测操作系统并生成对应的脚本。

### Q: 可以选择使用哪个模型吗？

A: 可以！在 Plan 模式中可以选择 opus、sonnet、haiku 或使用默认模型。

### Q: 如何集成项目的 debug skills？

A: 在 AGENTS.md 的 "Debug Skills" 部分添加项目特定的 debug skills。PROMPT_build.md 会自动引用。

### Q: Ralph Wiggum 自带 debug skills 吗？

A: Plan 模式会自动添加 `liuxiaoyusky/ai-developer-skills` marketplace，提供系统化的 `/debug` skill。这个 skill 包含：
- 根本原因分析（5 Whys 技术）
- 生产环境调试最佳实践
- 工具使用指南（Read/Grep/Bash）
- 常见调试陷阱避免

---

## 与官方插件的区别

| 特性 | 本 Skill（Bash 版本） | 官方插件（Stop Hook） |
|------|---------------------|---------------------|
| **循环位置** | 外部 Bash 脚本 | 内部 Stop Hook |
| **上下文** | 每次全新 | 同一会话 |
| **状态传递** | 磁盘文件（AGENTS.md） | 会话记忆 |
| **完成检测** | 任务清单 | 完成标志文本 |
| **定制性** | 完全控制 | 受限于插件 |
| **简单性** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |

**为什么选择 Bash 版本？**
- ✅ 更简单 - 5 行代码的核心
- ✅ 更可控 - 完全掌控脚本
- ✅ 更透明 - 可以看到所有生成的内容
- ✅ 经过验证 - Geoffrey Huntley 和大量开发者使用

---

## 参考资源

- [Geoffrey Huntley 的原始实现](https://github.com/ghuntley/how-to-ralph-wiggum) - Ralph Wiggum 的权威指南
- [Claude Code 官方 Ralph Wiggum 插件](https://github.com/anthropics/claude-code/blob/main/plugins/ralph-wiggum/README.md) - 官方插件版本
- [Ralph Wiggum Guide - Awesome Claude AI](https://awesomeclaude.ai/ralph-wiggum) - 完整的 Ralph Wiggum 指南
- [A Brief History of Ralph](https://www.humanlayer.dev/blog/brief-history-of-ralph) - Ralph 的历史

---

## 许可证

MIT License - 详见 [LICENSE](LICENSE)

---

**版本**: v1.0.0
**最后更新**: 2025-01-26

**让 AI 自主开发，从 Ralph Wiggum 开始！** 🚀
