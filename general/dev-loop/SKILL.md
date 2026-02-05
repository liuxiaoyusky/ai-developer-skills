---
name: dev-loop
description: 自动迭代调度器 - 循环调用 dev-flow 完成所有任务。每次迭代 = 1 次 dev-flow 执行（5 步闭环）。仅 2 个组件：tasks.md（任务清单）、loop 脚本（5 行循环）。触发场景："开始迭代"、"启动迭代"、"dev-loop"。
---

# dev-loop Skill

> **极简自动迭代调度器** - 让 AI 持续迭代直到完成所有任务

## 核心设计

### 第一性原理分析

**基本真理**：
1. **需要多次迭代** → `while` 循环
2. **状态必须持久化** → tasks.md
3. **检测完成** → dev-flow 主动报告 `<promise>COMPLETE</promise>` 信号
4. **执行标准化** → 调用 dev-flow

**新架构**（推荐）：
```
dev-loop（调度器）
  ↓
Dev Flow（标准化执行）
  ↓
完成任务
```

**旧架构**（已弃用）：
```
dev-loop（直接实现）
  ↓
非标准化执行
  ↓
不可预测、难以调试
```

---

## loop.sh 源码（推荐）

**源码位置**：[templates/loop.sh](templates/loop.sh)

**版本**：2025-02-04

**⭐ 为什么推荐 bash 版本？**

基于 Ralph ([snarktank/ralph](https://github.com/snarktank/ralph)) 的实践经验：

| 特性 | Bash (loop.sh) |
|------|----------------|
| **实时输出** | ✅ `2>&1 \| tee /dev/stderr` |
| **自动继续** | ✅ `\|\| true` 确保循环不中断 |
| **跨平台** | ✅ Windows(Git Bash)/macOS/Linux |
| **调试友好** | ✅ 每行输出可见 |

**关键实现**（类似 Ralph）：
```bash
# 同时实现实时输出 + 捕获
OUTPUT=$(claude --print 2>&1 | tee /dev/stderr) || true
```

**⚠️ 重要**：
- loop.sh 是**唯一的源码文件**
- dev-loop skill 激活时从 loop.sh 读取并生成 loop.sh
- 只需维护一份代码，符合 DRY 原则
- 支持 Windows(Git Bash)、macOS、Linux

---

## 快速开始

### 激活时的行为

**当用户说"开始迭代"、"启动迭代"、"dev-loop"时**：

1. **检查是否存在 tasks.md 和 loop.sh**
2. **如果 loop.sh 不存在** → 从 `templates/loop.sh` 读取并生成 loop.sh
3. **如果 loop.sh 已存在** → 检查版本，过时则提示更新
4. **如果 tasks.md 不存在** → 创建默认模板
5. **创建完成后立即停止** → 不要运行、不要检查、不要询问
6. **让用户自己决定何时运行** `chmod +x loop.sh && ./loop.sh`

**重要**：
- ✅ 生成文件后立即停止
- ❌ 不要自动运行 loop.sh
- ❌ 不要检查文件内容
- ❌ 不要询问"是否要开始"

**版本机制**：
- loop.sh 顶部包含 `# 版本：2025-02-04`
- 每次激活时检查版本，不匹配则警告用户重新生成
- **源码唯一来源**：templates/loop.sh

### 方式 1：自动生成（推荐）✅

```bash
# 1. 调用 dev-loop skill 自动生成
claude "开始迭代"  # 从 templates/loop.sh 读取并生成 loop.sh

# 2. 编辑任务
vim tasks.md  # 添加你的任务

# 3. 添加执行权限并运行
chmod +x loop.sh && ./loop.sh [--max N]
```

**优点**：
- ✅ 永远是最新版本（直接从 loop.sh 读取）
- ✅ 实时输出，调试友好（基于 Ralph 实践）
- ✅ 包含 caution.md 检测逻辑
- ✅ 自动继续，不会因单个错误中断

### 方式 2：手动复制（备用）

```bash
# 1. 复制模板文件
cp templates/TASKS.template.md tasks.md
cp templates/loop.sh loop.sh

# 2. 编辑任务
vim tasks.md  # 添加你的任务

# 3. 添加执行权限并运行
chmod +x loop.sh && ./loop.sh
```

**⚠️ 注意**：手动复制后，loop.sh 更新时需要手动同步。建议使用方式 1。

### 方式 3：直接使用（5 行核心代码）

```bash
# 1. 创建任务文件
cat > tasks.md << 'EOF'
# 开发任务清单

## 待处理 (TODO)
- [ ] 实现用户登录功能
- [ ] 添加数据导出功能

## 已完成 (DONE)
EOF

# 2. 运行
while grep -q "^\- \[ \]" tasks.md; do
  claude "使用 dev-flow 技能处理下一个任务"
done
```

---

## 核心文件

### 文件结构

```
dev-loop/
├── SKILL.md              # 技能定义（本文档）
├── README.md             # 用户文档
├── templates/            # 模板文件（源码）
│   ├── TASKS.template.md      # 任务清单模板
│   └── loop.sh                # ⭐ loop.sh 唯一源码文件（bash 版本）
└── LICENSE               # MIT License
```

**⚠️ 重要**：
- **loop.sh 是唯一的实现方式**（基于 Ralph 实践，支持实时输出）
- dev-loop skill 激活时默认生成 loop.sh
- 修改源码后，删除生成的文件重新生成即可应用更新
- 支持 Windows(Git Bash)、macOS、Linux

### tasks.md（任务清单）

使用模板创建：
```bash
cp templates/TASKS.template.md tasks.md
```

**格式**：
```markdown
## 待处理 (TODO)
- [ ] 任务1：描述
- [ ] 任务2：描述

## 已完成 (DONE)
- [x] 任务3：描述
```

**规则**：
- `- [ ]` 未完成
- `- [x]` 已完成
- 全部 `- [x]` 时循环自动停止

### loop.sh（推荐：跨平台 bash 脚本）

**源码位置**：[templates/loop.sh](templates/loop.sh)

**版本**：2025-02-04

**⚠️ 推荐生成方式**：
```bash
claude "开始迭代"  # 从 loop.sh 自动生成
```

**5 行核心版本**（简化参考）：
```bash
while grep -q "^\- \[ \]" tasks.md; do
  claude --print "使用 dev-flow 技能处理下一个任务" 2>&1 | tee /dev/stderr || true
done
```

**关键技巧**（类似 Ralph）：
```bash
# 同时实现实时输出 + 捕获输出
OUTPUT=$(claude --print 2>&1 | tee /dev/stderr) || true
```

- `2>&1` - 将 stderr 重定向到 stdout
- `| tee /dev/stderr` - 同时显示到终端和捕获到变量
- `|| true` - 无论成功失败都继续循环

**完整版特性**（见 loop.sh）：
- ✅ 迭代计数器
- ✅ 进度统计（待处理/已完成）
- ✅ 耗时显示
- ✅ 彩色输出（跨平台 ANSI）
- ✅ 错误处理（自动继续）
- ✅ Windows(Git Bash)/macOS/Linux 通用
- ✅ **实时流式输出**（类似 Ralph）
- ✅ **caution.md 检测**（启动时强制检查）

---

## 架构对比

### 传统方式（已弃用）

```
❌ dev-loop 直接实现
   - 每次执行逻辑不一致
   - 没有标准化流程
   - 难以追踪和调试
   - 错误处理依赖运气
```

### 新方式（推荐）

```
✅ dev-loop → Dev Flow
   - 每次执行都是标准化流程（5 步）
   - 自动日志记录（dev-flow.log）
   - 集成 first-principles + debug
   - 可预测、可调试、可恢复
```

**迭代语义**：

```
1 次迭代 = 1 次 CLI 调用 = 1 次 dev-flow 执行
  ↓
包括完整的 5 步：
  - Step 1: 读取 tasks.md，找到下一个任务
  - Step 2: 分析拆解（调用 first-principles）
  - Step 3: 执行任务（实时更新进度）
  - Step 4: 测试验证
  - Step 5: 错误处理（调用 debug）
  - 成功：更新 tasks.md，任务移到 DONE
  - 失败：保持在 TODO，下次继续
  ↓
CLI 退出，loop.sh 继续下一次迭代
```

### 完成检测机制

**dev-flow 主动报告**：
- dev-flow 在 Step 1 检测 tasks.md
- 发现无待处理任务时输出 `<promise>COMPLETE</promise>` 信号
- loop.sh 检测到信号后立即退出

**流程图**：
```
dev-flow 执行
  ↓
Step 1: 检测 tasks.md
  ├─ 有待处理任务 → 继续执行 5 步
  └─ 无待处理任务 → 输出 <promise>COMPLETE</promise>
      ↓
loop.sh 检测到信号 → 退出
```

**优势**：
- ✅ 更早发现：dev-flow 启动时立即检查
- ✅ 语义清晰：dev-flow 主动报告"我完成了"
- ✅ 代码简洁：单一检测点，易于维护

---

## 可选增强

### 显示迭代进度

```bash
#!/bin/bash
iteration=0
while grep -q "^\- \[ \]" tasks.md; do
  iteration=$((iteration + 1))
  echo "=== 迭代 #$iteration ==="
  claude "使用 dev-flow 技能处理下一个任务"
done
echo "✅ 完成！共 $iteration 次迭代"
```

### Git 自动提交

```bash
#!/bin/bash
iteration=0
while grep -q "^\- \[ \]" tasks.md; do
  iteration=$((iteration + 1))
  claude "使用 dev-flow 技能处理下一个任务"
  git add -A && git commit -m "iteration $iteration"
done
```

---

## 版本管理

### 版本检测机制

**源码版本**：loop.sh 顶部包含版本标识：
```bash
# 版本：2025-02-04
```

**更新流程**：
1. 修改 loop.sh 时递增版本号
2. 运行 dev-loop 时自动检测版本
3. 如果版本过旧，显示警告：
   ```
   ⚠️  loop.sh 版本过时（当前：2025-01-30，最新：2025-02-04）
      请运行：claude "开始迭代" 重新生成
   ```

### 强制更新

如果需要强制更新 loop.sh：
```bash
# 删除旧版本
rm loop.sh

# 重新生成（从 templates/loop.sh 读取）
claude "开始迭代"
```

### 修改 loop.sh

**⚠️ 不要直接修改生成的 loop.sh**（重新生成时会丢失）：

**正确做法**：
1. 修改 `templates/loop.sh`
2. 删除生成的 `loop.sh`
3. 运行 `claude "开始迭代"` 重新生成

---

## 使用场景

| 场景 | 使用方法 |
|------|----------|
| 单次任务 | `claude "使用 dev-flow 技能"` |
| 长期项目 | `./loop.sh` |
| 自动迭代 | dev-loop + Dev Flow |

---

## 最佳实践

### ✅ 推荐做法

- 保持 tasks.md 简洁
- 每个任务足够清晰
- 信任 dev-flow 的标准化流程
- 查看 dev-flow.log 了解执行细节

### ❌ 避免

- 在 tasks.md 中写详细实现细节
- 任务过于宽泛（"实现完整应用"）
- 手动干预循环

---

## 故障排除

**Q: 循环卡住怎么办？**
A: 检查 `dev-flow.log` 查看详细日志，找出卡住的步骤

**Q: 如何停止循环？**
A: 按 `Ctrl+C`

**Q: 任务失败会怎样？**
A: 任务保持在 TODO，下次继续；debug 技能会记录错题集

**Q: 实时输出不工作怎么办？**
A: 确保使用 loop.sh，并确认 claude 命令包含 `--print` 参数

**Q: 如何更新 loop.sh 到最新版本？**
A:
```bash
rm loop.sh  # 删除旧版本
claude "开始迭代"  # 重新生成
```

**Q: loop.sh 和 templates/loop.sh 有什么区别？**
A:
- `templates/loop.sh`：**唯一的源码文件**，所有修改都在这里进行
- `loop.sh`：运行文件，从 templates/loop.sh 自动生成
- **推荐**：不要直接修改 loop.sh，修改 templates/loop.sh 后重新生成

**Q: 如何修改 loop.sh？**
A:
```bash
# 1. 修改源码
vim templates/loop.sh

# 2. 删除旧版本
rm loop.sh

# 3. 重新生成
claude "开始迭代"
```

---

## 为什么这么简单？

### 第一性原理

**问题**：自动迭代最少需要什么？

**答案**：
1. 循环（`while`）
2. 状态（tasks.md）
3. 执行（dev-flow）

**结果**：3 个组件，5 行代码。

### 对比

| 指标 | 旧版 dev-loop | 新版（Ralph → Dev Flow） |
|------|-----------------|--------------------------|
| 核心代码 | 66 行 | 5 行 |
| 标准化 | ❌ | ✅ 5 步固定 |
| 可调试性 | ❌ | ✅ dev-flow.log |
| 错误处理 | ❌ | ✅ 自动 debug |
| 测试验证 | ❌ | ✅ 强制测试 |

---

## 与 Dev Flow 的关系

```
┌─────────────────────────────────────────────────────────┐
│  dev-loop（调度器）                                     │
│  - 职责：循环调用 CLI                                      │
│  - 不关心：如何实现任务                                    │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  Dev Flow（执行引擎）                                      │
│  - 职责：标准化执行流程（5 步）                             │
│  - 包含：任务识别、拆解、执行、测试、调试                    │
└─────────────────────────────────────────────────────────┘
```

**职责分离**：
- dev-loop: **何时**执行（循环）
- Dev Flow: **如何**执行（流程）

---

**版本**: v6.0.0 (bash 版本，基于 Ralph 实践)
**最后更新**: 2025-02-04
**loop.sh 版本**: 2025-02-04

**极简即是强大！** 🚀
