---
name: ralph-wiggum
description: 搭建用于 Ralph Wiggum 的 bash 文件和相关文件，适合长期自运行自迭代项目。支持 Build 模式（一键启动）和 Plan 模式（交互式配置），跨平台支持（Linux/macOS/Windows），默认集成 debug skills 加速迭代。触发场景："开始 ralph 循环"、"启动 ralph"、"ralph wiggum"、"使用 ralph 自动开发"。
---

# Ralph Wiggum Skill

基于 Bash 循环的 Ralph Wiggum 技术，让 AI 持续迭代直到完成所有任务。

## 核心原则

### 1. 零交互运行
- **首次运行** - 使用 plan 模式进行交互式配置
- **后续运行** - 使用 build 模式，完全自动，不再询问
- **直到完成** - 自动检测任务完成状态

### 2. 深度调试集成
- **默认启用** - 在 PROMPT.md 中自动引用本项目的 debug skills
- **加速迭代** - 当遇到错误时，自动调用 debug skill 诊断
- **无缝集成** - debug skill 作为 PROMPT 的一部分，无需额外配置

### 3. 跨平台支持
- **Linux/macOS** - 生成 loop.sh
- **Windows** - 生成 loop.bat
- **自动检测** - 根据 OS 生成对应脚本

### 4. 保留原始原则
- ✅ "study"（不是 "read"）
- ✅ "don't assume not implemented"
- ✅ "using parallel subagents" / "up to N subagents"
- ✅ "Ultrathink"
- ✅ "capture the why"
- ✅ "Let Ralph Ralph"

---

## 工作模式

### 模式一：Build 模式（一键启动，默认）

**使用场景**：
- 项目已配置好 AGENTS.md
- 已有明确的目标和任务
- 需要立即开始迭代

**特点**：
- ✅ **零交互** - 完全自动运行
- ✅ **无限循环** - 直到完成 AGENTS.md 中的所有任务
- ✅ **默认模型** - 使用 Claude Code 当前使用的模型（不指定 --model 参数）
- ✅ **深度调试集成** - 默认使用本项目的 debug skills
- ✅ **自动检测完成** - 当 AGENTS.md 中的所有任务完成时自动停止

**启动方式**：
```bash
/ralph-wiggum          # 或 /ralph-wiggum build
```

**工作流程**：
1. 检查 AGENTS.md 是否存在
2. 如果不存在，提示用户先运行 `/ralph-wiggum plan`
3. 生成 loop.sh 或 loop.bat（根据操作系统）
4. 启动循环
5. 自动检测任务完成，停止循环

---

### 模式二：Plan 模式（交互式配置）

**使用场景**：
- 首次使用 Ralph Wiggum
- 需要配置项目环境
- 需要选择特定的模型
- 需要生成或更新 IMPLEMENTATION_PLAN.md

**特点**：
- ✅ **交互式配置** - 引导用户完成设置
- ✅ **环境读取** - 自动检测系统环境（操作系统、Git 状态等）
- ✅ **跨平台支持** - 生成 Bash 或 Batch 脚本
- ✅ **模型选择** - 可指定使用哪个模型（opus/sonnet/haiku）
- ✅ **可选调试集成** - 询问是否使用本项目的 debug skills

**启动方式**：
```bash
/ralph-wiggum plan
```

**交互流程**：
1. 环境检测（操作系统、Git 状态、项目结构）
2. 交互式配置：
   - **Debug Skills Marketplace**：询问是否添加 `liuxiaoyusky/ai-developer-skills` marketplace（推荐）
   - **AGENTS.md 配置**：创建或更新任务清单
   - **模型选择**：opus/sonnet/haiku/默认
   - **最大迭代次数**：默认 0（无限）
3. 生成脚本和模板文件
4. 展示配置并询问是否立即启动

**默认集成 Debug Skills**：
Plan 模式会自动执行以下命令：
```bash
claude plugin marketplace add liuxiaoyusky/ai-developer-skills
```

这提供了强大的 `/debug` skill，包含：
- 根本原因分析（5 Whys 技术）
- 生产环境调试最佳实践
- 工具使用指南（Read/Grep/Bash）
- 常见调试陷阱避免

---

## 关键文件说明

### AGENTS.md（核心文件）

**注意**：
- 模板文件位于 `templates/agents_template.md`
- 使用时复制到项目根目录并重命名为 `AGENTS.md`

这是项目的**单一真相来源**，包含：

1. **Build & Run** - 如何构建项目
2. **Validation** - 验证命令（测试、类型检查、Lint）
3. **Tasks** - 任务清单（使用 `- [ ]` 和 `- [x]` 标记完成状态）
4. **Operational Notes** - 项目运行相关的注意事项
5. **Debug Skills** - 本项目集成的 debug skills

**示例格式**：
```markdown
## Build & Run

构建项目：
npm run build

## Validation

实现后运行这些命令进行验证：
- Tests: `npm test`
- Typecheck: `npm run typecheck`
- Lint: `npm run lint`

## Tasks

任务清单（完成时标记 ✅）：

- [ ] Task 1: 实现用户认证
- [x] Task 2: 设置项目结构
- [ ] Task 3: 编写单元测试

## Operational Notes

项目运行相关的注意事项...

### Debug Skills

本项目集成的 debug skills:
- /debug-error - 分析错误并提供修复建议
- /debug-tests - 测试失败分析
```

**关键特性**：
- ✅ **任务清单** - 使用 Markdown checkbox 格式
- ✅ **完成检测** - 循环脚本检查所有任务是否标记为完成
- ✅ **简洁** - 只包含必要信息

---

### PROMPT_build.md（构建模式提示词）

告诉 Claude 如何实现任务。

**关键内容**：
1. **Phase 0** - Orientation（study specs, AGENTS.md, source code）
2. **Phase 1-4** - Main instructions（implement, validate, commit）
3. **999...** - Guardrails（invariants, critical rules）
4. **Debug Skill Integration** - 错误处理和 debug skill 调用

**关键指令**（保留原始语言模式）：
- "study"（不是 "read" 或 "look at"）
- "don't assume not implemented"
- "using parallel subagents" / "up to N subagents"
- "Ultrathink"
- "capture the why"

---

### PROMPT_plan.md（规划模式提示词）

告诉 Claude 如何生成/更新 IMPLEMENTATION_PLAN.md。

**使用场景**：
- 需求发生变化
- 需要重新规划任务优先级
- 发现新的任务或依赖关系

---

### loop.sh / loop.bat（循环脚本）

**功能**：
- 无限循环，直到所有任务完成
- 每次迭代：
  1. 启动 Claude CLI
  2. 读取 PROMPT_build.md
  3. Claude 实现一个任务
  4. 更新 AGENTS.md（标记任务完成）
  5. Git commit 和 push
  6. 检查是否所有任务完成
  7. 如果未完成，继续循环

**完成检测机制**：
```bash
# 检查 AGENTS.md 中是否所有任务都标记为完成
if grep -q '\- \[ \]' AGENTS.md; then
    # 还有未完成的任务，继续循环
else
    # 所有任务都完成了
    echo "✅ 所有任务已完成！"
    break
fi
```

---

## 使用示例

### 示例 1：新项目首次设置

```bash
# 1. 创建项目目录
mkdir my-project && cd my-project

# 2. 初始化 Git
git init

# 3. 启动 Plan 模式
/ralph-wiggum plan

# 交互式配置：
# - 是否使用 debug skills？Y
# - 选择模型？4（默认）
# - 最大迭代次数？0（无限）

# 4. Ralph 生成所有文件
# ✅ loop.sh
# ✅ PROMPT_build.md
# ✅ AGENTS.md

# 5. 编辑 AGENTS.md，添加任务
# - [ ] 实现用户登录
# - [ ] 实现数据持久化
# - [ ] 添加单元测试

# 6. 启动 Build 模式
/ralph-wiggum

# Ralph 开始工作...
```

### 示例 2：已有项目，直接启动

```bash
# 项目已有 AGENTS.md，直接启动
/ralph-wiggum

# Ralph 自动：
# 1. 检测操作系统
# 2. 生成对应的循环脚本
# 3. 启动循环
# 4. 持续迭代直到完成
```

### 示例 3：选择特定模型

```bash
/ralph-wiggum plan

# 交互式配置：
# - 选择模型？1（opus - 推理能力强）
# - 最大迭代次数？50

# 生成包含 --model opus 的 loop.sh
```

---

## Debug Skills 集成

### 默认集成

PROMPT_build.md 中包含 debug skill 调用逻辑：

```
DEBUG SKILL INTEGRATION:
When encountering errors:
1. First attempt: Try to fix using standard debugging
2. If stuck after 3 attempts: Invoke /debug skill
3. The debug skill will analyze and fix the issue
4. Resume iteration

Example:
/debug "Tests failing: TypeError: Cannot read property 'x' of undefined in src/auth.ts:45"
```

### 自定义 Debug Skills

在 AGENTS.md 中添加项目特定的 debug skills：

```markdown
### Debug Skills

本项目集成的 debug skills:
- /debug-error - 通用错误分析
- /debug-tests - 测试失败分析
- /debug-performance - 性能问题诊断
- /my-custom-debug - 项目特定的调试工具
```

---

## 最佳实践

### 1. 任务拆分

**好的任务**：
- ✅ 实现用户登录功能（包含表单验证、JWT token 生成）
- ✅ 添加数据持久化（使用 SQLite，包含 CRUD 操作）

**不好的任务**：
- ❌ 实现完整的应用（太大，难以完成）
- ❌ 修复 bug（太模糊，缺少上下文）

### 2. 编写有效的 AGENTS.md

**包含内容**：
- ✅ 清晰的构建命令
- ✅ 完整的验证命令（测试、类型检查、Lint）
- ✅ 具体的任务描述（包含验收标准）
- ✅ 项目的代码模式说明

**避免内容**：
- ❌ 状态更新或进度记录（这些应该在 Git commit 中）
- ❌ 重复的信息（保持简洁）

### 3. 让 Ralph Ralph

- ✅ **信任 Ralph** - 让它自己决定如何实现
- ✅ **接受迭代** - 第一次可能不完美，但会逐步改进
- ✅ **观察和学习** - 注意 Ralph 如何解决问题
- ✅ **添加 guardrails** - 在 PROMPT 中添加关键规则

### 4. 何时重新规划

**应该重新规划**：
- ✅ 需求发生重大变化
- ✅ Ralph 持续实现错误的功能
- ✅ 任务优先级需要调整
- ✅ 发现遗漏的重要任务

**不应该重新规划**：
- ❌ 遇到暂时的错误（让 Ralph 自己解决）
- ❌ 对实现方式有不同意见（Let Ralph Ralph）

---

## 故障排除

### 问题 1：循环不前进

**症状**：Ralph 重复实现相同的功能，或无法完成任务。

**解决方案**：
1. 检查 AGENTS.md 中的任务描述是否清晰
2. 检查 Validation 命令是否正确
3. 检查 PROMPT_build.md 中的指令是否明确
4. 如果问题持续，重新运行 `/ralph-wiggum plan`

### 问题 2：生成的 loop.sh 无法执行

**症状**：`bash: ./loop.sh: Permission denied`

**解决方案**：
```bash
chmod +x loop.sh
./loop.sh
```

### 问题 3：Claude CLI 未找到

**症状**：`claude: command not found`

**解决方案**：
确保已安装 Claude CLI 并在 PATH 中：
```bash
which claude  # 检查是否安装
```

---

## 参考资源

- [Geoffrey Huntley 的原始实现](https://github.com/ghuntley/how-to-ralph-wiggum)
- [Claude Code 官方 Ralph Wiggum 插件](https://github.com/anthropics/claude-code/blob/main/plugins/ralph-wiggum/README.md)
- [Ralph Wiggum Guide - Awesome Claude AI](https://awesomeclaude.ai/ralph-wiggum)
- [A Brief History of Ralph](https://www.humanlayer.dev/blog/brief-history-of-ralph)

---

## 版本历史

- **v1.0.0** (2025-01-26) - 初始版本
  - 支持 Build 模式和 Plan 模式
  - 跨平台支持（Linux/macOS/Windows）
  - Debug skills 集成
  - 基于任务清单的完成检测

---

**许可**: MIT License - 详见 [LICENSE](LICENSE)
