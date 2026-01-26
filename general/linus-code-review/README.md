# Linus Code Review

> **"Talk is cheap. Show me the code."** - Linus Torvalds

基于 Linus Torvalds 的代码哲学，通过5层分析框架评估代码质量。

## ✨ 新特性

### 🚀 默认启用 + Ralph Wiggum 智能集成

**1. 自动应用 Linus 思维**
- 代码审查、编写、API 设计时**自动启用**
- 无需显式触发，Linus 的质量标准成为默认
- 检测破坏性变更、过度工程化、边界情况

**2. 智能建议 Ralph Wiggum**
当检测到以下情况时，自动建议使用 `/ralph-wiggum`：
- 需要修改 5+ 个文件
- 需要编写/修改 500+ 行代码
- 复杂重构任务（需要多次迭代）
- API 破坏性变更（需要迁移多个调用点）

**3. 项目级配置**
复制 `CLAUDE.project.example.md` 到项目根目录，让整个项目默认使用 Linus 标准。

---

## 核心价值

在"代码能跑"和"代码优雅"之间架起桥梁，追求"好品味"(Good Taste)。

**典型效果**：
- 发现隐藏的边界情况
- 识别破坏性 API 变更
- 消除不必要的特殊情况
- 简化过度抽象的设计

## 核心哲学

### 1. Good Taste - 消除边界情况

> "有时你可以从不同角度看问题，重写它让特殊情况消失，变成正常情况。"

经典案例：链表删除操作，从10行带if判断优化为4行无条件分支。

### 2. Never break userspace - 向后兼容

> "我们不破坏用户空间！"

任何导致现有程序崩溃的改动都是bug，无论多么"理论正确"。

### 3. Pragmatism - 实用主义

> "我是个该死的实用主义者。"

解决实际问题，而不是假想的威胁。拒绝微内核等"理论完美"但实际复杂的方案。

### 4. Simplicity - 简洁执念

> "如果你需要超过3层缩进，你就已经完蛋了，应该修复你的程序。"

函数必须短小精悍，只做一件事并做好。复杂性是万恶之源。

---

## 如何使用

### 触发方式

```bash
/linus-code-review
"审查这段代码"
"Linus code review this"
"从 Linus 的视角看这段代码"
```

### 工作流程

1. **代码上下文识别**（自动）
   - 识别代码范围（文件、函数、片段）
   - 检测编程语言
   - 评估代码规模

2. **审查目标确认**（1个问题）
   - "主要关注点是什么？"
     - 代码质量 / 架构设计 / 向后兼容性 / 性能 / 全部

3. **审查深度确认**（可选）
   - "需要多详细的审查？"
     - 快速扫描 / 标准审查 / 深度审查

4. **5层分析**
   - Layer 1: 数据结构分析
   - Layer 2: 特殊情况识别
   - Layer 3: 复杂度审查
   - Layer 4: 破坏性分析
   - Layer 5: 实用性验证

5. **输出报告**
   - 品味评分 (1-10分)
   - 致命问题（P0优先级）
   - 改进方向（P0-P3）

---

## 输出示例

```markdown
# 品味评分: 6/10

## 评分维度
- 数据结构设计: 5/10
- 特殊情况处理: 6/10
- 代码复杂度: 7/10
- 向后兼容性: 8/10
- 实用性: 6/10

## 致命问题

### 🔴 #1: 数据结构导致特殊情况泛滥

**位置**: `src/user_service.py:45-52`
**原因**: 使用大量 if/else 处理不同用户类型
**影响**: 添加新用户类型需要修改多处代码
**修复**: 使用多态或策略模式替代条件分支

## 改进方向

### P0 - 必须修复
1. 重构用户类型处理逻辑
2. 修复破坏性 API 变更（user_id → userId）

### P1 - 强烈建议
1. 简化过度抽象的验证器工厂
2. 减少嵌套深度（当前5层，应<3层）

### P2 - 建议改进
1. 统一命名风格（camelCase vs snake_case）
2. 添加类型注解

### P3 - 可选优化
1. 性能优化：缓存用户查询结果
```

---

## 5层分析框架

### Layer 1: 数据结构分析

**核心问题**: "Bad programmers worry about the code. Good programmers worry about data structures."

- 数据结构是否自然表达问题？
- 能否通过更好的数据结构消除特殊情况？
- 有没有不必要的数据复制或转换？

### Layer 2: 特殊情况识别

**核心问题**: "Good taste is about eliminating special cases."

- 代码中有多少 if/else 分支？
- 哪些边界情况可以避免？
- 能否用统一逻辑处理所有情况？

### Layer 3: 复杂度审查

**核心问题**: "Controlling complexity is the essence of computer programming."

- 代码是否过度抽象？
- 是否有不必要的间接层？
- 可读性和性能的平衡点在哪里？

### Layer 4: 破坏性分析

**核心问题**: "I will NOT break userspace!"

- API 变更是否破坏向后兼容性？
- 行为变更是否会影响现有代码？
- 是否提供了迁移路径？

### Layer 5: 实用性验证

**核心问题**: "Theory is where you know everything but nothing works."

- 这段代码解决实际问题了吗？
- 是否过度工程化？
- 简单粗暴的方案是否更好？

---

## 适用场景

### ✅ 使用 linus-code-review

- **代码审查** - Pull Request review, 代码走查
- **重构前评估** - 评估代码质量，决定是否重构
- **设计评审** - 架构设计、API 设计评审
- **学习提高** - 想了解"好品味"代码是什么样的
- **代码质量检查** - 定期代码健康检查

### ❌ 使用其他技能

| 场景 | 使用技能 |
|------|---------|
| 系统调试/故障 | [debug](../debug/) - 5 Whys 根因分析 |
| 产品设计/MVP | [first-principles-planner](../first-principles-planner/) - 产品规划 |
| 文档审计 | [doc-auditor](../../doc-auditor/) - 文档质量检查 |
| 通用创新 | [first-principles](../first-principles/) - 第一性原理思维 |

---

## Linus 式问题清单

在审查过程中持续问：

1. **"What's the data structure here?"**
2. **"Can we eliminate this special case?"**
3. **"Does this break userspace?"**
4. **"Is this practical or just clever?"**
5. **"Can we make it simpler?"**
6. **"What's the ACTUAL problem we're solving?"**
7. **"Why does this exist? What problem does it solve?"**

---

## 安装

```bash
claude plugin install linus-code-review
```

---

## 关键洞察

1. **Good Taste = Eliminating Special Cases** - 优雅代码通过更好的数据结构避免特殊情况
2. **Userspace is Sacred** - 向后兼容是API设计的铁律
3. **Pragmatism Over Theory** - 解决实际问题，不过度工程化
4. **Simplicity Wins** - 短小精悍 > 复杂抽象
5. **Directness** - 直接地指出问题，不要拐弯抹角

---

## 更多信息

- [SKILL.md](./SKILL.md) - 完整技能定义
- [其他技能](../..) - 更多 AI 辅助开发技能

---

**"Talk is cheap. Show me the code."**
