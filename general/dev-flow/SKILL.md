---
name: dev-flow
description: Task Executor - 接收单个子任务，完成 实现→测试→debug 闭环。由 dev-loop orchestrator 通过文件协议调度。读取 task-details.md 中的子任务，执行实现，调用 dev-verify 测试，失败时调用 dev-debug（最多3次），将结果写入 task-result.md。触发场景："实现XXX"、"添加功能"、"开发XXX"、"写代码"。
alwaysActivate: true
---

# Dev Flow Skill — Task Executor

> **单任务执行器**：接收一个子任务，交付一个结果。
>
> dev-flow 不再是 5 步闭环的全流程引擎。它是 dev-loop orchestrator 调度的 **subagent**，
> 专注于单个子任务的 **实现 → 测试 → debug** 闭环。
> 通过文件协议（task-details.md / task-result.md / debug-log.md）与 orchestrator 通信。

---

## 核心职责

```
输入：task-details.md 中的一个子任务
输出：task-result.md（SUCCESS 或 ROLLBACK）

执行闭环：
  Step 1: 读取上下文
  Step 2: 实现 + 测试
  Step 3: Debug 循环（如需要）
```

### 自动激活条件

- 💻 **功能开发**："实现XXX"、"添加功能"、"开发XXX"、"写代码"
- ✅ **Subagent 调度**：被 dev-loop orchestrator 调度时自动激活
- 🟢 **弱信号**（不激活）：纯技术问题咨询、代码解释

---

## 文件协议

### 输入文件（读取）

| 文件 | 用途 | 必需 |
|------|------|------|
| `task-details.md` | 技术设计，包含当前子任务详情 | 是 |
| `caution.md` | 项目约束和注意事项 | 否 |
| `debug-log.md` | 之前的调试失败记录（避免重蹈覆辙） | 否 |

### 输出文件（写入）

| 文件 | 用途 | 必需 |
|------|------|------|
| `task-result.md` | 执行结果（SUCCESS/ROLLBACK） | 是 |
| `debug-log.md` | 调试尝试记录（追加写入） | 仅 debug 时 |

---

## 三步执行流程

### Step 1: 读取上下文

**目标**：理解要做什么，以及要避开什么

```
1. 读取 task-details.md
   → 找到当前子任务（状态为 pending 或 in_progress 的任务）
   → 提取：描述、涉及文件、验收标准、测试策略

2. 读取 caution.md（如果存在）
   → 了解项目约束
   → 显示约束内容

3. 读取 debug-log.md（如果存在）
   → 了解之前的失败尝试
   → 提取排除方案列表
   → AI 内部标记：这些方案不要再试
```

**决策树**：

```
debug-log.md 存在？
  ├─ YES → 读取失败历史，标记排除方案
  │        AI: "检测到之前的失败记录，将避免以下方案：
  │             [方案列表]"
  └─ NO  → 正常执行（首次尝试）
```

---

### Step 2: 实现 + 测试

**目标**：实现子任务并验证

```
2.1 预备阶段
  → 读取涉及文件，理解现有代码
  → 使用 Grep/Glob 搜索相关代码模式
  → 确定实现方案

2.2 实现阶段
  → 按照描述和验收标准实现功能
  → 使用 Edit/Write 工具修改代码
  → 实时考虑 caution.md 中的约束

2.3 测试阶段
  → 根据测试策略执行测试
  → 优先使用 dev-verify 技能（自动检测框架并执行真实测试）
  → 如果无测试框架：手动验证核心功能

2.4 结果判定
  ├─ 所有测试通过 → 写入 task-result.md (SUCCESS) → 结束
  └─ 测试失败 → 进入 Step 3 (Debug 循环)
```

**工具使用策略**：

```
✅ 推荐工具：
- Read  - 阅读现有代码
- Edit  - 修改代码（优先使用）
- Write - 创建新文件
- Grep  - 搜索相关代码
- Glob  - 查找文件
- Bash  - 运行测试命令

❌ 避免使用：
- Bash echo - 使用文本回复代替
- sed/awk  - 使用 Edit 工具代替
```

---

### Step 3: Debug 循环

**目标**：测试失败时，调用 dev-debug 修复，最多 3 次

```
3.1 调用 dev-debug 技能
  → 传递错误信息、堆栈跟踪、测试上下文
  → dev-debug 自动：
    a. 读取 debug-log.md 检查已有尝试次数
    b. 如果 >= 3 次 → 直接返回 ROLLBACK 信号
    c. 如果 < 3 次 → 分析根因，尝试修复，记录到 debug-log.md

3.2 检查 dev-debug 结果
  ├─ FIXED → 回到 Step 2.3 重新测试
  └─ ROLLBACK → 写入 task-result.md (ROLLBACK) → 结束

3.3 循环条件
  → 最多调用 dev-debug 3 次（由 dev-debug 内部计数）
  → 每次修复后必须重新测试
  → 测试通过 → SUCCESS
  → 3 次都失败 → ROLLBACK
```

**流程图**：

```
测试失败
  ↓
调用 dev-debug
  ↓
dev-debug 检查 debug-log.md
  ├─ 已有 3 次尝试 → 返回 ROLLBACK
  └─ 还有尝试机会 → 分析根因 → 修复
      ↓
    记录到 debug-log.md
      ↓
    重新测试
      ├─ 通过 → SUCCESS
      └─ 失败 → 再调用 dev-debug（循环）
```

---

## task-result.md 输出格式

### SUCCESS 格式

```markdown
# Task Result

## 状态: SUCCESS

## 任务: [子任务标题]

## 时间: YYYY-MM-DD HH:mm

---

## 变更摘要

- 修改了 src/auth/routes.py: 添加了登录 API endpoint
- 新增了 tests/test_auth.py: 登录功能的单元测试
- 修改了 src/models/user.py: 添加了密码哈希方法

## 建议 Commit Message

feat(auth): implement login API with JWT token

## 测试结果

- 单元测试: 15/15 passed
- 集成测试: 8/8 passed
- 启动测试: passed
```

### ROLLBACK 格式

```markdown
# Task Result

## 状态: ROLLBACK

## 任务: [子任务标题]

## 时间: YYYY-MM-DD HH:mm

---

## 变更摘要

- 尝试修改了 src/auth/routes.py（将被回退）

## 建议 Commit Message

N/A (rollback)

## 测试结果

- 单元测试: 12/15 failed
- 集成测试: 未执行

---

## 失败原因

debug 3次均未能解决：
1. 尝试1: 修改了数据库连接配置 → 仍然超时
2. 尝试2: 添加了连接池 → 内存溢出
3. 尝试3: 换用异步连接 → 兼容性问题

根本问题：当前数据库驱动不支持异步操作

## 建议方向

下次尝试时建议：
- 换用支持异步的数据库驱动（如 asyncpg）
- 或者不用异步，改用连接池 + 超时重试策略
```

---

## 独立使用（不通过 dev-loop）

当用户直接请求开发任务时，dev-flow 也可以独立运行：

```
用户: "帮我实现用户登录功能"
  ↓
dev-flow 自动激活
  ↓
Step 1: 读取上下文
  → 检查 task-details.md（如不存在，根据用户请求自动生成简化版）
  → 检查 caution.md

Step 2: 实现 + 测试
  → 实现功能
  → 运行测试

Step 3: Debug（如需要）
  → 调用 dev-debug

完成后：
  → 如果在 dev-loop 中：写入 task-result.md
  → 如果独立运行：直接报告结果给用户
```

**判断是否在 subagent 模式**：
- 如果 task-details.md 存在且包含当前任务 → subagent 模式，写 task-result.md
- 否则 → 独立模式，直接回复用户

---

## 与 dev 技能生态的协作

```
dev-loop (orchestrator)
  ↓ 调度
dev-flow (task executor) ← 你在这里
  ├── 调用 dev-verify (测试验证)
  ├── 调用 dev-debug  (调试修复, 最多 3 次)
  └── 调用 dev-review  (代码审查, 自动激活)
```

| 协作技能 | 调用时机 | 说明 |
|----------|----------|------|
| dev-verify | Step 2 测试阶段 | 自动检测框架，执行真实测试 |
| dev-debug | Step 3 测试失败时 | 根因分析 + 修复，最多 3 次 |
| dev-review | 代码变更时自动激活 | Linus 5 层代码审查 |
| first-principles | 复杂子任务需分析时 | 第一性原理拆解 |

---

## 严禁行为

- ❌ **禁止跳过测试** - 必须通过测试才能写 SUCCESS
- ❌ **禁止 AI 模拟测试** - 必须真实执行测试命令
- ❌ **禁止无限 debug** - 最多 3 次，超过必须 ROLLBACK
- ❌ **禁止不写 task-result.md** - subagent 模式下必须写入结果
- ❌ **禁止修改 tasks.md** - tasks.md 由用户和 dev-loop 维护
- ✅ **必须读取 debug-log.md** - 如果存在，必须了解之前的失败
- ✅ **必须遵守 caution.md** - 如果存在，必须遵守约束

---

**版本**: v7.0.0 (Task Executor + 文件协议 + Debug 回退)
**最后更新**: 2026-02-13
