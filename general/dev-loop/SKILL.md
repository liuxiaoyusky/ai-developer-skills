---
name: dev-loop
description: Project Orchestrator - 读取 tasks.md（产品设计文档），生成 task-details.md（技术设计），通过文件协议调度 dev-flow subagent 逐个执行子任务，集成 git version control（checkpoint/commit/rollback）和 debug 保底回退机制。触发场景："开始迭代"、"启动迭代"、"dev-loop"。
---

# dev-loop Skill — Project Orchestrator

> **从产品设计到技术交付的全自动编排器**
>
> dev-loop 不再是简单的循环调度器。它是整个开发流程的大脑：
> 1. 读取 tasks.md（产品设计文档）→ 理解需求
> 2. 生成 task-details.md（技术设计）→ 拆解为可执行子任务
> 3. 逐个调度 dev-flow subagent → 进程级隔离，零上下文污染
> 4. 管理 version control → checkpoint/commit/rollback
> 5. 处理 debug 回退 → 保留错误记忆，换方向重试

---

## 核心架构

```
tasks.md (产品设计文档，用户维护)
    ↓ dev-loop 读取理解
task-details.md (技术设计，AI 生成)
    ↓ 逐个子任务
    ┌─────────────────────────────────────────┐
    │  For each Task in task-details.md:      │
    │                                         │
    │  1. [CHECKPOINT] git commit checkpoint  │
    │  2. [DISPATCH]   claude --print         │
    │     → dev-flow subagent 执行子任务       │
    │     → 写入 task-result.md               │
    │     → 写入 debug-log.md (如有 debug)     │
    │  3. [READ] 读取 task-result.md          │
    │  4. [BRANCH]                            │
    │     ├─ SUCCESS → git commit             │
    │     └─ ROLLBACK → git reset → 重试      │
    └─────────────────────────────────────────┘
    ↓
tasks.md 更新进度追踪
```

### 通信协议：文件即接口

所有 subagent 之间**零上下文共享**，通过文件通信：

| 文件 | 维护者 | 用途 |
|------|--------|------|
| `tasks.md` | 用户 | 产品设计文档，自由格式描述需求 |
| `task-details.md` | dev-loop | 技术设计，结构化子任务列表 |
| `task-result.md` | dev-flow subagent | 子任务执行结果（SUCCESS/ROLLBACK） |
| `debug-log.md` | dev-debug | 调试历史记录，rollback 后保留 |
| `caution.md` | 用户 | 项目约束和注意事项 |

---

## tasks.md 格式（产品设计文档）

tasks.md 是**产品设计文档**，不再强制 `- [ ]` 格式。用户可以自由描述：

```markdown
# 项目名称

## 背景与目标
描述项目背景、用户痛点、核心价值...

## 功能需求

### 需求1: 用户认证系统
用户需要能够注册、登录、注销。支持邮箱登录。
验收标准: 用户能完成注册并登录后看到个人主页。

### 需求2: 数据导出
管理员可以导出 CSV 格式的用户数据...

## 技术约束
- 使用 Python + FastAPI
- 数据库用 PostgreSQL

## 进度追踪
- [x] 需求1: 用户认证系统 (2025-02-10)
- [ ] 需求2: 数据导出
```

**关键原则**：
- 正文部分完全自由描述，不限制格式
- 底部的进度追踪用 `- [ ]` 但**可选**，不是强制格式
- dev-loop 读取**整个文档**理解上下文，而不是只解析 checkbox
- 使用模板创建：`cp templates/TASKS.template.md tasks.md`

---

## task-details.md 格式（技术设计文档）

由 dev-loop 的**第一个 subagent 调用**从 tasks.md 自动生成：

```markdown
# Technical Design: [当前需求名称]

## 来源
- 需求: tasks.md > [需求标题]
- 生成时间: YYYY-MM-DD HH:mm

## 子任务列表

### Task 1: [标题]
- **状态**: pending | in_progress | completed | failed | rolled_back
- **描述**: 具体做什么
- **涉及文件**: src/auth/routes.py, src/models/user.py
- **验收标准**: 明确的可测试标准
- **测试策略**: 单元测试 / 集成测试 / 手动验证
- **预计复杂度**: low | medium | high

### Task 2: [标题]
...

## 依赖关系
Task 2 依赖 Task 1 完成

## 技术决策记录
- 选择 JWT 而非 Session，因为...
```

**状态值**：
- `pending` - 等待执行
- `in_progress` - 正在执行
- `completed` - 已完成并通过测试
- `failed` - 多次尝试后仍然失败，已跳过
- `rolled_back` - 已回退，等待重试

---

## 三阶段工作流程

### Phase 1: 产品设计 → 技术设计

**目标**：读取 tasks.md，生成 task-details.md

**执行**：
```
1. 检查 caution.md 是否存在（不存在则创建默认模板）
2. 读取 caution.md，显示项目约束
3. 读取 tasks.md 全文
4. 识别下一个未完成的需求
5. 调度第一个 subagent：
   claude --print "读取 tasks.md，为 [需求名称] 生成 task-details.md（技术设计）。
   使用 templates/TASK-DETAILS.template.md 格式。分析需求，拆解为 3-7 个可执行子任务。"
6. 验证 task-details.md 已生成
```

**完成检测**：
- 如果 tasks.md 中所有需求都已完成（进度追踪全为 `[x]`，或正文中无未处理需求）
- 输出 `<promise>COMPLETE</promise>` 信号，退出

### Phase 2: 逐个执行子任务

**目标**：按 task-details.md 中的顺序，逐个调度 dev-flow subagent

**对每个子任务执行**：

```
Step 1: [CHECKPOINT] 创建 git 检查点
  git add -A && git commit -m "checkpoint: before [task-name]" --allow-empty

Step 2: [PREPARE] 清空通信文件
  > task-result.md
  # 注意：debug-log.md 不清空（如果是重试，保留历史）

Step 3: [DISPATCH] 调度 dev-flow subagent
  claude --dangerously-skip-permissions --print \
    "你是 dev-flow task executor。
     读取 task-details.md 中的 Task N。
     读取 debug-log.md（如有历史失败，避免相同方案）。
     读取 caution.md（项目约束）。
     执行任务 → 测试 → 如有失败则 debug（最多 3 次）。
     完成后写入 task-result.md。"

Step 4: [READ] 读取 task-result.md，解析状态

Step 5: [BRANCH] 根据状态分支处理
  ├── SUCCESS:
  │   ├── 读取 task-result.md 中的建议 commit message
  │   ├── git add -A && git commit -m "$commit_msg"
  │   ├── 更新 task-details.md 中该任务状态为 completed
  │   └── 继续下一个子任务
  │
  └── ROLLBACK:
      ├── 保存 debug-log.md 到 /tmp/
      ├── git reset --hard HEAD~1（回到 checkpoint 前）
      ├── 恢复 debug-log.md（错误记忆）
      ├── 重新调度 subagent（带 "请避免以下方案" 上下文）
      ├── 如果二次仍 ROLLBACK → 标记为 failed，跳过
      └── 继续下一个子任务
```

### Phase 3: 收尾

**目标**：更新进度，报告结果

```
1. 统计完成情况（completed / failed / total）
2. 更新 tasks.md 进度追踪
3. 如果所有需求都已完成 → 输出 COMPLETE 信号
4. 如果还有未完成需求 → 等待下一次迭代
```

---

## Version Control 规范

### Commit Message 格式

| 类型 | 格式 | 说明 |
|------|------|------|
| 新功能 | `feat(模块): 描述` | 新增功能 |
| 修复 | `fix(模块): 描述` | Bug 修复 |
| 重构 | `refactor(模块): 描述` | 代码重构 |
| 检查点 | `checkpoint: before task-N [描述]` | 可被 squash |

- Commit message 由 dev-flow subagent 在 task-result.md 中建议
- loop.sh 直接使用 subagent 建议的 message

### Rollback 策略

```
第一次 ROLLBACK:
  1. 保存 debug-log.md（错误记忆）
  2. git reset --hard HEAD~1
  3. 恢复 debug-log.md
  4. 重新 dispatch subagent（带避坑上下文）

第二次 ROLLBACK（同一子任务）:
  1. 标记为 failed
  2. git reset --hard HEAD~1
  3. 跳过该子任务，继续下一个
  4. 在 task-details.md 中标记 failed
```

**关键原则**：debug-log.md 在 rollback 后**始终保留**，这是防止 subagent 重蹈覆辙的"错误记忆"。

---

## 快速开始

### 激活时的行为

**当用户说"开始迭代"、"启动迭代"、"dev-loop"时**：

1. **检查是否存在 tasks.md 和 loop.sh**
2. **如果 loop.sh 不存在** → 从 `templates/loop.sh` 读取并生成 loop.sh
3. **如果 loop.sh 已存在** → 检查版本，过时则提示更新
4. **如果 tasks.md 不存在** → 从 `templates/TASKS.template.md` 创建
5. **创建完成后立即停止** → 不要运行、不要检查、不要询问
6. **让用户自己决定何时运行** `chmod +x loop.sh && ./loop.sh`

**重要**：
- ✅ 生成文件后立即停止
- ❌ 不要自动运行 loop.sh
- ❌ 不要检查文件内容
- ❌ 不要询问"是否要开始"

### 运行

```bash
# 1. 调用 dev-loop skill 生成文件
claude "开始迭代"

# 2. 编辑 tasks.md（写产品设计文档）
vim tasks.md

# 3. 运行
chmod +x loop.sh && ./loop.sh [--max N]
```

---

## 文件结构

```
project-root/
├── tasks.md                # 产品设计文档（用户维护）
├── task-details.md         # 技术设计文档（dev-loop 生成）
├── task-result.md          # 子任务执行结果（dev-flow subagent 写入）
├── debug-log.md            # 调试历史记录（dev-debug 写入）
├── caution.md              # 项目约束（用户维护）
├── loop.sh                 # 迭代脚本（从 templates/loop.sh 生成）
└── .claude/
    └── debug-experiences/  # 长期调试经验（dev-debug 维护）

dev-loop/
├── SKILL.md                # 本文档
├── README.md               # 用户文档
├── templates/
│   ├── TASKS.template.md        # tasks.md 产品设计文档模板
│   ├── TASK-DETAILS.template.md # task-details.md 技术设计模板
│   ├── TASK-RESULT.template.md  # task-result.md 结果输出模板
│   ├── DEBUG-LOG.template.md    # debug-log.md 调试日志模板
│   └── loop.sh                  # loop.sh 源码
└── LICENSE
```

---

## 与 dev 技能生态的协作

```
dev-loop (Project Orchestrator)
  │
  ├── 读取 tasks.md → 生成 task-details.md
  │   └── 可调用 first-principles 拆解复杂需求
  │
  ├── 调度 dev-flow subagent（每个子任务）
  │   ├── dev-flow 实现子任务
  │   ├── dev-flow 调用 dev-verify 测试
  │   └── dev-flow 调用 dev-debug 调试（最多 3 次）
  │
  ├── 管理 version control
  │   ├── checkpoint → commit (成功)
  │   └── checkpoint → rollback → retry (失败)
  │
  └── dev-review 自动激活（代码变更时）
```

| 场景 | 推荐方式 |
|------|----------|
| 单次简单任务 | 直接用 dev-flow |
| 多任务项目 | dev-loop + loop.sh |
| 遇到 bug | dev-debug 自动调用 |
| 代码审查 | dev-review 自动激活 |

---

## caution.md 默认模板

```markdown
# ⚠️ 开发注意事项

## 强制规则

在此文件中添加开发过程中必须遵守的规则。
这些规则将在每次 dev-flow subagent 启动时读取。

## 示例规则

- 禁止未测试就标记任务完成
- 禁止直接修改核心配置文件
- 禁止提交包含 console.log 的代码
- 所有 API 变更必须更新文档

---
请根据项目需求修改上述内容。
```

---

## 故障排除

**Q: 循环卡住怎么办？**
A: 检查 `task-result.md` 查看最后一个 subagent 的执行结果

**Q: rollback 后状态不对？**
A: 检查 `debug-log.md` 是否正确恢复，确认 git log 中 checkpoint 是否存在

**Q: subagent 没有正确写入 task-result.md？**
A: 确认 loop.sh 中的 prompt 包含了写入 task-result.md 的指令

**Q: 如何强制跳过某个子任务？**
A: 手动编辑 task-details.md，将该任务状态改为 `failed`

**Q: 如何更新 loop.sh？**
A: `rm loop.sh && claude "开始迭代"` 重新生成

---

**版本**: v7.0.0 (Project Orchestrator + Version Control + Subagent)
**最后更新**: 2026-02-13
