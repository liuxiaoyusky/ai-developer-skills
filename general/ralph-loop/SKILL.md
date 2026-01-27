---
name: ralph-loop
description: 极简 Ralph Loop - 让 AI 持续迭代直到完成任务。仅 3 个组件：TASKS.md（任务清单）、loop 脚本（8 行平台特定循环）、Claude CLI。基于第一性原理重构，移除了所有非必要复杂性。触发场景："开始 ralph"、"启动 ralph"、"ralph loop"、"使用 ralph 自动开发"。
---

# Ralph Loop Skill

基于第一性原理重构的极简 Ralph Loop，让 AI 持续迭代直到完成所有任务。

## 核心原则

### 第一性原理分析

**基本真理**（Ralph Loop 本质上做什么）：
1. **AI 需要多次尝试** → `while (true)` 循环
2. **状态必须持久化** → 单个文件存储
3. **必须检测完成** → 检查任务状态
4. **必须自动运行** → 无人干预执行

**除此之外的一切都是可选的。**

### 移除的"特性"（非本质）

- ❌ Plan 模式（规划 ≠ 迭代，分离关注点）
- ❌ IMPLEMENTATION_PLAN.md（双状态文件造成混乱）
- ❌ 跨平台 Node.js（用平台特定脚本更简洁）
- ❌ PROMPT 模板（复杂性不解决核心问题）
- ❌ 自动 Git 提交（可选增强，非核心）
- ❌ Marketplace 集成（文档化为可选）

### 保留的要素（本质）

- ✅ Checkbox 格式（简单、有效）
- ✅ 循环机制（基本真理 #1）
- ✅ 任务持久化（基本真理 #2）
- ✅ 完成检测（基本真理 #3）
- ✅ Claude CLI 调用（执行工作的 AI）

---

## 快速开始

### 30 秒上手

**macOS/Linux**:
```bash
# 1. 创建任务文件
cp TASKS.template.md TASKS.md

# 2. 复制 loop 脚本
cp loop.sample.sh loop.sh

# 3. 编辑任务（添加你的项目目标）
vim TASKS.md

# 4. 运行
chmod +x loop.sh
./loop.sh
```

**Windows**:
```powershell
# 1. 创建任务文件
copy TASKS.template.md TASKS.md

# 2. 复制 loop 脚本
copy loop.sample.ps1 loop.ps1

# 3. 编辑任务（添加你的项目目标）
notepad TASKS.md

# 4. 运行
.\loop.ps1
```

**就这么简单！** Ralph 会持续工作，直到所有任务完成。

---

## 核心文件

### TASKS.md（单一真相来源）

项目的唯一状态文件，包含任务清单和验证命令。

**格式**：
```markdown
# Project: [简要描述]

## Tasks
- [ ] Task 1: 描述 - 验收：标准
- [ ] Task 2: 描述 - 验收：标准
- [x] Task 3: 描述 - 验收：标准

## Validation
npm test
npm run lint
```

**关键特性**：
- `- [ ]` 未完成，`- [x]` 已完成
- 全部 `- [x]` 时循环自动停止
- 每次迭代都加载此文件（保持简洁）

### loop.sample.sh（macOS/Linux - 13 行）

完整的示例脚本位于 `loop.sample.sh`，包含使用说明：

```bash
#!/bin/bash
# Ralph Loop - macOS/Linux 示例脚本
# 使用方法：
# 1. 复制到你的项目目录: cp loop.sample.sh loop.sh
# 2. 确保 TASKS.md 文件存在
# 3. 运行: chmod +x loop.sh && ./loop.sh

iteration=0
while true; do
  iteration=$((iteration + 1))
  echo ""
  echo "=== Iteration $iteration ==="
  echo ""

  if ! grep -q '\[ \]' TASKS.md 2>/dev/null; then
    echo "✅ All tasks complete!"
    break
  fi

  claude -p "Implement the next incomplete task in TASKS.md. Update the checkbox to [x] when done."
done
```

### loop.sample.ps1（Windows - 17 行）

完整的示例脚本位于 `loop.sample.ps1`，包含使用说明：

```powershell
# Ralph Loop - Windows 示例脚本
# 使用方法：
# 1. 复制到你的项目目录: copy loop.sample.ps1 loop.ps1
# 2. 确保 TASKS.md 文件存在
# 3. 运行: .\loop.ps1

$iteration = 0
while ($true) {
    $iteration++
    Write-Host ""
    Write-Host "=== Iteration $iteration ==="
    Write-Host ""

    $tasks = Get-Content "TASKS.md" -Raw -ErrorAction SilentlyContinue
    if ($tasks -notmatch '\[ \]') {
        Write-Host "✅ All tasks complete!"
        break
    }

    claude -p "Implement the next incomplete task in TASKS.md. Update the checkbox to [x] when done."
}
```

**平台特定**：各平台使用原生脚本，更简洁高效。

---

## 为什么这么简单？

### 第一性原理思维

我们问：**"Ralph Loop 最少需要什么才能工作？"**

**不是**：
- ❌ "其他 Ralph Wiggum 实现有什么功能？"（类比思维）
- ❌ "用户可能想要什么额外功能？"（猜测需求）

**而是**：
- ✅ "基本物理限制是什么？"（第一性原理）
- ✅ "如果我们从零开始设计，最小系统是什么？"（从零重建）

**答案**：任务文件 + 循环脚本 + AI 调用。

**结果**：70% 代码减少，100% 功能保留。

### 对比：重构前 vs 重构后

| 指标 | 重构前 | 重构后 | 减少 |
|------|--------|--------|------|
| 核心文件 | 7 | 4 | 43% |
| 状态文件 | 2 | 1 | 50% |
| 循环代码 | 66 行 | 8-12 行 | 85% |
| 设置复杂度 | 交互式 5+ 问题 | 编辑 1 个文件 | 复杂 → 简单 |
| 模式 | 2 | 1 | 50% |
| 核心概念 | 10+ | 3 | 70% |

---

## 可选增强（非核心）

这些不是重构的一部分，但用户可以按需添加：

### Git 自动提交

在每次迭代后自动提交代码：

**macOS/Linux** - 在 `loop.sh` 中，`claude` 调用后添加：
```bash
git add -A && git commit -m "iteration $iteration" && git push
```

**Windows** - 在 `loop.ps1` 中，`claude` 调用后添加：
```powershell
git add -A; git commit -m "iteration $iteration"; git push
```

### Debug Skills

安装 marketplace 并在卡住时使用：

```bash
claude plugin marketplace add liuxiaoyusky/ai-developer-skills
```

在 `TASKS.md` 中：
```markdown
## Tasks
- [ ] 修复 Bug - 卡住时使用 /debug "错误详情"
```

### 模型选择

通过环境变量指定模型：

**macOS/Linux**:
```bash
CLAUDE_MODEL=opus ./loop.sh
```

**Windows**:
```powershell
$env:CLAUDE_MODEL="opus"; .\loop.ps1
```

---

## 使用示例

### 新项目

**macOS/Linux**:
```bash
mkdir my-project && cd my-project
git init
cp /path/to/ralph-loop/TASKS.template.md TASKS.md
cp /path/to/ralph-loop/loop.sample.sh loop.sh
vim TASKS.md  # 添加任务
chmod +x loop.sh
./loop.sh
```

**Windows**:
```powershell
mkdir my-project; cd my-project
git init
copy C:\path\to\ralph-loop\TASKS.template.md TASKS.md
copy C:\path\to\ralph-loop\loop.sample.ps1 loop.ps1
notepad TASKS.md  # 添加任务
.\loop.ps1
```

### 现有项目

**macOS/Linux**:
```bash
cd existing-project
# 创建 TASKS.md
vim TASKS.md
# 复制 loop 脚本
cp /path/to/ralph-loop/loop.sample.sh loop.sh
chmod +x loop.sh
# 运行
./loop.sh
```

**Windows**:
```powershell
cd existing-project
# 创建 TASKS.md
notepad TASKS.md
# 复制 loop 脚本
copy C:\path\to\ralph-loop\loop.sample.ps1 loop.ps1
# 运行
.\loop.ps1
```

---

## 迁移指南（从旧版本）

### 如果你有 AGENTS.md：

```bash
# 重命名为 TASKS.md
mv AGENTS.md TASKS.md

# 可选：删除 Build & Run、Operational Notes、Debug Skills 部分
# （仅保留 Tasks 和 Validation）
```

### 如果你有 loop.js：

**macOS/Linux**:
```bash
# 替换为 loop.sh
cp loop.sample.sh loop.sh
chmod +x loop.sh
# 无需其他更改 - 直接运行 loop.sh 即可
```

**Windows**:
```powershell
# 替换为 loop.ps1
copy loop.sample.ps1 loop.ps1
# 无需其他更改 - 直接运行 loop.ps1 即可
```

### 如果你使用 Plan 模式：

```bash
# 旧工作流：
/ralph-wiggum plan  # 交互式配置

# 新工作流：
vim TASKS.md  # 直接编辑（或使用 first-principles-planner skill）
./loop.sh     # 运行（macOS/Linux）
# 或
.\loop.ps1    # 运行（Windows）
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

### 2. Let Ralph Ralph

- ✅ 信任 Ralph，让它自己决定如何实现
- ✅ 接受迭代，第一次可能不完美
- ✅ 观察和学习，注意 Ralph 如何解决问题

### 3. 保持 TASKS.md 简洁

- ✅ 定期删除已完成的任务
- ✅ 只包含必要信息
- ❌ 不要在文件中记录状态更新（用 Git commit）

---

## 故障排除

### Q: 循环不前进怎么办？

A: 检查以下几点：
1. TASKS.md 中的任务描述是否清晰
2. Validation 命令是否正确
3. 如果问题持续，手动修改 TASKS.md

### Q: 如何停止循环？

A: 按 `Ctrl+C` 停止循环。或者等待所有任务完成，循环会自动停止。

### Q: 支持哪些操作系统？

A: Linux、macOS 和 Windows。各平台使用原生脚本。

### Q: 可以选择使用哪个模型吗？

A: 可以！通过环境变量：
- **macOS/Linux**: `CLAUDE_MODEL=opus ./loop.sh`
- **Windows**: `$env:CLAUDE_MODEL="opus"; .\loop.ps1`

---

## 参考资源

- [第一性原理思维](https://github.com/anthropics/claude-code/blob/main/docs/guides/first-principles.md)
- [Geoffrey Huntley 的原始实现](https://github.com/ghuntley/how-to-ralph-wiggum)
- [Ralph Wiggum Guide - Awesome Claude AI](https://awesomeclaude.ai/ralph-wiggum)

---

## 许可证

MIT License - 详见 [LICENSE](LICENSE)

---

**版本**: v3.0.0 (Platform-Native Scripts)
**最后更新**: 2025-01-27

**极简即是强大！** 🚀
