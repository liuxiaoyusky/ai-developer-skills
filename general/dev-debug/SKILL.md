---
name: dev-debug
description: 系统化问题解决技能 - 整合 5 Whys 根因分析、第一性原理重建思维、本地错题集和保底回退机制。**自动激活**：遇到错误、异常、故障、性能问题时自动启动调试流程。触发场景："报错"、"bug"、"调试"、"debug"、"异常"、"错误"、"性能慢"、"不工作"、"出问题"、"故障"、"崩溃"、"内存泄漏"。**语义信号**：🔴强信号（错误代码/堆栈跟踪）、🟡中等信号（性能问题/行为异常）。**保底机制**：debug 超过 3 次未解决 → 输出 ROLLBACK 信号 → 触发 dev-loop 回退到上一版本重新实现。
alwaysActivate: true
---

# Dev-Debug Skill

> **触发条件**（满足任一即自动激活）：
> - 🔴 **强信号**（立即激活）：错误代码/堆栈跟踪、"报错"、"bug"、"调试"、"debug"、"Exception"、"Error"、"Failed"
> - 🟡 **中等信号**（询问确认）："性能慢"、"卡顿"、"不工作"、"出问题"、"异常"、"崩溃"
> - 🟢 **弱信号**（不触发）：理论学习、代码解释、咨询性问题（如"什么是XXX"）
>
> **CRITICAL**: 在提出任何解决方案之前，必须通过此框架进行问题分析和路径选择。
>
> **错题集系统**：自动维护项目的"错题集"（`.claude/debug-experiences/`），记录每次调试的成功和失败经验，持续积累项目特定的 debug 智慧。
>
> **保底回退机制**：每次 debug 尝试记录到 `debug-log.md`，超过 MAX_DEBUG_RETRIES (3次) 未解决则输出 ROLLBACK 信号，触发 dev-loop 回退到 git checkpoint 并换方向重试。

---

## 🛡️ 保底回退机制（v7.0 新增）

### 核心概念

当 debug 多次尝试仍无法解决问题时，不应该无限循环，而是**果断回退**：

```
MAX_DEBUG_RETRIES = 3

debug 尝试 1 → 失败 → 记录到 debug-log.md
debug 尝试 2 → 失败 → 记录到 debug-log.md
debug 尝试 3 → 失败 → 记录到 debug-log.md → 输出 ROLLBACK 信号
```

### debug-log.md 协议

**每次 debug 尝试必须追加记录到 `debug-log.md`**：

```markdown
## Attempt N/3

- **时间**: YYYY-MM-DD HH:mm
- **错误描述**: [错误信息/堆栈跟踪]
- **分析方法**: [5 Whys | First Principles]
- **根因分析**: [分析过程和结论]
- **尝试方案**: [具体做了什么修改]
- **修改文件**: [file1.py:L42, file2.py:L15]
- **结果**: [FIXED | FAILED]
- **失败原因**: [如果 FAILED，为什么这个方案不行]
```

### Phase 0: 重试检查（每次 debug 入口必执行）

**在任何分析之前**，先检查 debug-log.md：

```
读取 debug-log.md
  ├─ 不存在 → 首次尝试，创建文件，继续正常流程
  ├─ 存在但尝试次数 < 3 → 读取之前的失败记录，
  │   标记排除方案，继续正常流程
  └─ 存在且尝试次数 >= 3 → 直接输出 ROLLBACK：

      AI: "🛑 已达最大 debug 重试次数 (3/3)
           之前的尝试均失败：
           1. [方案1] - [失败原因]
           2. [方案2] - [失败原因]
           3. [方案3] - [失败原因]

           建议 ROLLBACK 并换方向重试。
           SIGNAL: ROLLBACK"
```

### ROLLBACK 后的行为

当 dev-loop 收到 ROLLBACK 信号：
1. **git reset** 回到 checkpoint
2. **保留 debug-log.md**（错误记忆）
3. **重新调度 subagent**，prompt 中包含"请避免以下方案"
4. 新 subagent 读取 debug-log.md，了解什么路不通，换条路走

**关键**：debug-log.md 是跨 rollback 的"错误记忆"，防止 subagent 重蹈覆辙。

---

## 🎯 核心框架：三层问题解决模型

### Layer 1: 问题分类（决定解决路径）

在开始调查之前，先回答 3 个核心问题：

1. **"这是'系统行为错误'还是'设计理解错误'？"**
   - 行为错误：系统做了不该做的事，或没做该做的事
   - 设计理解错误：我们对系统的假设是错的

2. **"这是'在现有框架内修复'还是'需要质疑框架'？"**
   - 框架内修复：使用 5 Whys + 修复
   - 质疑框架：使用第一性原理 + 重建

3. **"用户的真实目标是什么？"**
   - 不是修复 bug，而是实现目标
   - 目标可能通过不同路径实现

### Layer 2: 调查方法（双轨制）

#### 轨道 A: 5 Whys 根因分析（自顶向下）

**什么是 5 Whys？**

5 Whys 是由丰田佐吉提出的根因分析方法。核心是通过**连续问至少 5 次"为什么"**，层层深入，从现象到根本原因。

**5 Whys 的本质**：
```
不是: 问"为什么错了5次"（这是误解）
而是: 通过问5次为什么，找到可以采取行动的根因

第1个Why → 症状/现象（表面问题）
第2个Why → 直接原因
第3个Why → 间接原因
第4个Why → 深层原因
第5个Why → 根本原因（可采取行动）
```

**适用于**：
- ✅ 明确的错误/异常
- ✅ 系统行为与设计意图不符
- ✅ 需要快速定位实现问题
- ✅ 已知设计是正确的

**方法示例**：
```
问题: API 返回 500 错误

Why 1? → 为什么返回 500？数据库查询超时
Why 2? → 为什么超时？连接池耗尽
Why 3? → 为什么耗尽？连接未关闭
Why 4? → 为什么未关闭？错误路径没调用 close()
Why 5? → 为什么没调用？缺少 finally 块

ROOT CAUSE: 缺少 finally 块来关闭连接
SOLUTION: 添加 finally 块
```

**关键要点**：
1. **每一层的答案都是下一层的问题**
   - "数据库查询超时" → "为什么超时？"

2. **第5个Why后必须能采取行动**
   - 如果第5个Why后还是"不知道"，继续问Why 6、Why 7...
   - 直到找到可以行动的根本原因

3. **区分症状和根本原因**
   - ❌ Symptom: "API返回500"（第1层）
   - ✅ Root cause: "缺少finally块"（第5层）

4. **避免推诿式"Why"**
   - ❌ "为什么没人检查代码？" → 这是责怪，不是根因
   - ✅ "为什么缺少finally块？" → 这是技术根因

#### 轨道 B: 第一性原理重建（自底向上）

**适用于**：
- ✅ 性能问题（慢、卡顿）
- ✅ 复杂交互问题
- ✅ 设计本身可能有问题
- ✅ 需要创新突破
- ✅ 5 Whys 找不到满意答案

**方法**：
```
问题: API 响应慢（需要 10 秒）

第一性原理拆解:
基本真理:
- 网络延迟: 50ms (物理限制)
- 数据库查询: 5ms (简单查询)
- 数据传输: 1MB/10Mbps = 0.8s

质疑假设:
- 我们需要传输这么多数据吗？
  → 实际: 返回 1000 条完整记录
  → 质疑: 用户真的需要一次看到 1000 条吗？
  → 真理: 人眼只能同时处理 10-20 条

重建方案:
- 不修复查询性能
- 改用分页（每页 20 条）
- 结果: 响应时间 10s → 0.5s（降低 95%）
```

### Layer 3: 解决路径（四重选择）

找到问题本质后，选择解决路径：

1. **修复系统**（使实际 = 期望）
   - 适用于：实现错误
   - 方法: 修复 bug

2. **修改期望**（使期望 = 实际）
   - 适用于：需求理解错误
   - 方法: 更新文档/用户沟通

3. **重构系统**（设计新系统）
   - 适用于：设计本身有问题
   - 方法: 第一性原理重建

4. **接受差异**（差异不重要）
   - 适用于：非关键问题
   - 方法: 技术债务记录

---

## 🔍 调查流程（整合版）

### Phase 0: 重试检查（入口必执行）

**在任何分析之前，首先检查 debug-log.md**：

```bash
# 检查 debug-log.md 是否存在
if [ -f "debug-log.md" ]; then
  # 计算已有尝试次数
  attempt_count=$(grep -c "^## Attempt" debug-log.md)
  
  if [ $attempt_count -ge 3 ]; then
    # 已达上限，直接输出 ROLLBACK
    echo "SIGNAL: ROLLBACK"
    exit 0
  fi
  
  # 读取之前的失败方案，标记为排除项
  echo "检测到之前的 $attempt_count 次失败尝试"
  echo "将避免以下方案："
  grep "尝试方案" debug-log.md
fi
```

**执行逻辑**：

```
1. 读取 debug-log.md
   ├─ 不存在 → 创建文件头部，设置 attempt = 1，继续 Phase 1
   ├─ 尝试次数 < 3 → 读取排除方案列表，设置 attempt = N+1，继续 Phase 1
   └─ 尝试次数 >= 3 → 输出 ROLLBACK 信号，结束

2. 如果继续：在 debug-log.md 末尾追加新的 Attempt 块头部
   ## Attempt N/3
   - **时间**: [当前时间]
   - **错误描述**: [待填充]
```

**ROLLBACK 输出格式**：

```markdown
🛑 Debug 重试次数已耗尽 (3/3)

之前的尝试：
1. [Attempt 1 方案] → [失败原因]
2. [Attempt 2 方案] → [失败原因]
3. [Attempt 3 方案] → [失败原因]

汇总结论：[根本问题是什么]
建议方向：[下次应尝试的不同路径]

SIGNAL: ROLLBACK
```

---

### Phase 1: 信息收集（所有情况通用）

**提出澄清问题**：
- 具体的错误信息或行为是什么？
- 何时发生？（时间、上下文、触发条件）
- 能否分享错误日志、堆栈跟踪、截图？

**使用工具调查**：
- **Read** - 检查实际代码/配置（绝不猜测）
- **Grep** - 搜索模式、相关代码
- **Glob** - 查找所有相关文件
- **Bash** - 检查日志、进程、测试行为

### Phase 1.5: 经验检索（智能激活）

**语义信号检测**：

当检测到以下信号时，**自动激活 dev-debug skill + 查询错题集**：

#### 🔴 强信号（立即激活，不询问）

1. **错误代码/堆栈跟踪**
   ```
   Error: API returned 500
       at API.handler (api.js:123)
   TypeError: Cannot read property 'data'
   ```

2. **明确的 debug 关键词**
   ```
   "帮我 debug 一下"
   "这个 bug 怎么修复"
   "为什么会报这个错误"
   "遇到了奇怪的问题"
   ```

3. **错误日志片段**
   ```
   [ERROR], [WARN], Exception, Failed, Timeout
   ```

#### 🟡 中等信号（询问后激活）

1. **性能/行为问题**
   ```
   "API 响应太慢"
   "页面加载卡顿"
   "内存占用持续增长"
   "间歇性出现错误"
   ```

**AI 行为**：询问"看起来是性能/行为问题，是否启动 dev-debug skill？[Y/n]"

#### 🟢 弱信号（不激活）

- 开发任务："如何实现用户登录？"
- 咨询学习："什么是 N+1 问题？"

**错题集查询流程**：

```
Step 1: 检查错题集是否存在
├─ 如果不存在 → 跳到 Phase 2（首次使用）
└─ 如果存在 → 继续

Step 2: 读取 INDEX（轻量级）
├─ 使用 head -n 50 读取前 50 行（< 100 tokens）
└─ 提取高频问题 + 最近 7 天经验

Step 3: 相关性匹配
├─ 提取当前问题特征（错误类型、组件、标签）
├─ 计算 similarity score（频率 40% + 时间 30% + 标签 30%）
└─ 选择 Top 3-5 条相关经验

Step 4: 展示相关经验
├─ ⭐ 高频错误（≥ 3 次）→ 总是展示
├─ 📅 最近 7 天 → 总是展示
├─ 🏷️ 标签匹配度 ≥ 50% → 展示
└─ ⚠️  失败经验标记为"避免此路径"

Step 5: 用户交互
AI: "🔍 发现 3 条相关经验：
     [SUCCESS] API Timeout (高频，第 5 次)
     [FAILURE] Redis Cache（避免此路径）
     是否参考这些经验？[Y/n] (默认: Y)"
```

**智能匹配逻辑**：

```bash
# 示例：用户遇到 API 超时问题
current_tags = ["api", "timeout", "performance"]

# 搜索 INDEX 中的相关经验
grep -E "(api|timeout|performance)" .claude/debug-experiences/INDEX.md

# 优先级排序
1. 频率优先（出现 5 次的 > 出现 1 次的）
2. 时间优先（最近 7 天 > 1 个月前）
3. 标签匹配（3 个标签都匹配 > 1 个标签匹配）

# 最多展示 5 条，避免信息过载
```

**分层架构**（避免 token 浪费）：

```
.claude/debug-experiences/
├── INDEX.md                    # 轻量级索引（高频 + 最近）
│   ├── ## 🔥 High-Frequency Issues
│   └── ## 📅 Last 7 Days
├── 2025-01-15-api-timeout.md   # 详细经验（按需读取）
└── 2025-01-10-redis-cache.md   # 失败经验（避免路径）
```

**查询工具使用**：

```bash
# 快速扫描 INDEX（只读前 50 行）
head -n 50 .claude/debug-experiences/INDEX.md

# 搜索特定标签
grep -i "api.*timeout" .claude/debug-experiences/INDEX.md

# 按需读取详细经验（仅读相关的 3-5 条）
Read .claude/debug-experiences/2025-01-15-api-timeout.md
```

**首次使用**：

- 如果 `.claude/debug-experiences/` 不存在
- 自动跳过经验查询
- 正常执行 Phase 2
- 在 Phase 5.5 自动创建错题集

**可选禁用**：

- 用户可使用 `--no-history` flag 强制跳过错题集查询
- 或直接回答 'n' 跳过经验参考

### Phase 2: 问题分类（选择轨道）

**使用决策树**：

```
开始
  ↓
是否有明确错误/异常？
  YES → 使用轨道 A (5 Whys)
  NO  ↓

是否是性能/设计问题？
  YES → 使用轨道 B (第一性原理)
  NO  ↓

5 Whys 是否找到满意答案？
  NO  → 切换到轨道 B (第一性原理)
  YES → 继续用轨道 A
```

### Phase 3: 深度分析（轨道选择）

#### 轨道 A: 5 Whys 根因分析

**应用 5 Whys 技术** - 通过连续问 5 次"为什么"，从现象深入到根本原因：

```
PROBLEM: API returns 500 error

Why 1? 为什么返回 500？
→ Database query times out（数据库查询超时）

Why 2? 为什么超时？
→ Connection pool is exhausted（连接池耗尽）

Why 3? 为什么耗尽？
→ Connections aren't being closed（连接没有被关闭）

Why 4? 为什么没有被关闭？
→ Error path doesn't call connection.close()（错误路径没有调用关闭方法）

Why 5? 为什么没有调用关闭方法？
→ Missing finally block in error handling（缺少 finally 块）

ROOT CAUSE: Missing finally block to close connections
（可以通过添加 finally 块来解决的根因）
```

**关键原则**：
1. 每一层的答案都是下一层的"为什么"问题
2. 第 5 个 Why 后必须能采取行动（继续问直到找到可行动的根因）
3. 区分症状（第 1 层）和根本原因（第 5 层）
- ❌ Symptom: "页面加载缓慢"
- ✅ Root cause: "未优化的 N+1 数据库查询"

#### 轨道 B: 第一性原理分析

**三步法**：

1. **拆解到基本真理**
   ```
   问题: 页面加载需要 10 秒

   基本真理分析:
   - 网络传输: 1MB / 10Mbps = 0.8s
   - DOM 渲染: 1000 个元素 = 1-2s
   - JavaScript 执行: 5s

   → 问题不在网络，在 JavaScript
   ```

2. **质疑所有假设**
   ```
   假设质疑:
   - "我们需要加载 1000 条数据吗？"
     → 用户实际只看前 20 条

   - "我们需要在客户端渲染吗？"
     → 可以服务端渲染

   - "我们需要实时更新吗？"
     → 可以缓存 5 分钟
   ```

3. **从零重建**
   ```
   重建方案:
   - 分页加载（每页 20 条）
   - 服务端渲染
   - 添加缓存

   → 不修复 JavaScript，而是减少数据量
   → 结果: 10s → 0.5s
   ```

### Phase 4: 解决方案设计

**基于 Layer 3 的四重选择**：

1. **修复系统**：修改代码使行为符合期望
2. **修改期望**：更新需求/文档，使期望符合实际
3. **重构系统**：用第一性原理重新设计
4. **接受差异**：记录为技术债务

### Phase 5: 验证计划

**标准验证**：
1. 阅读修改的代码
2. 使用 Grep 检查类似问题
3. 运行测试
4. 测试特定的错误行为

**🔴 生产环境验证**（适用于已部署的应用）：

```bash
# Step 1: 从用户错误中提取确切的文件名
# 用户错误: "index-FPRo3oei.js:18 API call failed"

# Step 2: 检查 HTML 引用了什么
curl -s https://domain.com/ | grep -o "assets/index-.*\.js"

# Step 3: 验证那个特定文件（不是你的本地构建！）
curl -s https://domain.com/assets/index-FPRo3oei.js | grep "PATTERN"

# Step 4: 如需要，清除缓存
curl -H "Cache-Control: no-cache" https://domain.com/assets/index-FPRo3oei.js
```

**关键原则**：
- 错误信息包含关于生产环境的唯一真相
- 错误中的文件名/URL/行号是事实
- 工具成功 ≠ 生产现实（CDN/缓存会产生差距）
- 验证用户实际看到的内容，而不是你认为他们看到的

### Phase 5.5: debug-log.md 更新（每次必执行）

**在 Phase 5 验证之后，无论成功还是失败，都必须更新 debug-log.md**：

```markdown
# 追加到 debug-log.md 当前 Attempt 块

- **根因分析**: [Phase 3 的分析结论]
- **尝试方案**: [Phase 4 的解决方案]
- **修改文件**: [具体文件和行号]
- **结果**: [FIXED | FAILED]
- **失败原因**: [如果 FAILED，具体原因]
```

**结果处理**：

```
Phase 5 验证结果：
  ├─ 测试通过 (FIXED)
  │   → 更新 debug-log.md: 结果 = FIXED
  │   → 返回 FIXED 信号给 dev-flow
  │   → 继续 Phase 5.6 记录经验
  │
  └─ 测试失败 (FAILED)
      → 更新 debug-log.md: 结果 = FAILED
      → 检查当前 attempt 是否 >= MAX_DEBUG_RETRIES (3)
        ├─ 是 → 在 debug-log.md 追加 EXHAUSTED 汇总块
        │       → 返回 ROLLBACK 信号给 dev-flow
        └─ 否 → 返回 FAILED 信号，等待 dev-flow 再次调用
```

**EXHAUSTED 汇总块格式**（当 attempt >= 3 时追加）：

```markdown
---

## 汇总 - EXHAUSTED

- **结论**: 已达最大重试次数 (3/3)，建议 ROLLBACK
- **失败原因汇总**: [综合 3 次尝试的关键洞察]
- **排除的方案**: [列出已尝试但失败的方案]
- **下次建议**: [基于失败经验，建议换什么方向]
```

---

### Phase 5.6: 经验记录（持续积累）

**记录时机**：
- Debug 完成后（验证通过，即 FIXED）
- 记录到 `.claude/debug-experiences/`
- 首次使用时自动创建目录结构

**目录结构**：

```bash
# 首次使用时创建
mkdir -p .claude/debug-experiences

# 创建 INDEX.md（如果不存在）
touch .claude/debug-experiences/INDEX.md

# 创建新的经验文件
touch .claude/debug-experiences/YYYY-MM-DD-short-description.md
```

**记录模板**：

```markdown
# [SUCCESS/FAILURE] YYYY-MM-DD: Short Description

**Problem**
- What happened?
- Error messages?
- Impact on users?

**Tags**
- type: error | performance | design | behavior
- component: api | database | frontend | worker | cache
- method: 5-whys | first-principles
- impact: high | medium | low

**Investigation Method**
- Track A (5 Whys) or Track B (First Principles)?
- Why did you choose this method?

**Root Cause**
- What was the actual underlying issue?

**Solution Path**
- Fix System | Modify Expectations | Reconstruct System | Accept Difference
- Why this path?

**Solution Details**
- What did you change?
- Code changes?
- Configuration changes?
- Architecture changes?

**Verification**
- How did you verify it worked?
- Metrics before/after?
- Test results?

**Lessons Learned** (for FAILURE)
- Why did this approach fail?
- What should be avoided in the future?
- What would you do differently?

**Related Files**
- Files modified
- Documentation updated
- Related issues

**Occurrences**
- First occurrence: YYYY-MM-DD
- Last occurrence: YYYY-MM-DD
- Frequency: X times
```

**INDEX.md 更新**：

每次记录新经验后，更新 `INDEX.md`：

```markdown
# Debug Experiences Index

## 🔥 High-Frequency Issues (≥ 3 occurrences)

### [Type] Component Issue - X occurrences
**Last**: YYYY-MM-DD
**Pattern**: Quick pattern description
**Quick Fix**: One-line solution
**Recent File**: [detail](YYYY-MM-DD-issue.md)

---

## 📅 Last 7 Days

### [SUCCESS] YYYY-MM-DD: Issue Description
**Tags**: tag1, tag2, tag3
**Method**: 5 Whys / First Principles
**Lesson**: One-line lesson
→ [Read more](YYYY-MM-DD-issue.md)

### [FAILURE] YYYY-MM-DD: Failed Attempt
**Why Failed**: Brief reason
**Lesson**: What to avoid
→ [Read more](YYYY-MM-DD-failure.md)

---

## 🏷️ By Tag

### performance (X)
- [Issue 1] YYYY-MM-DD
- [Issue 2] YYYY-MM-DD

### api (Y)
- [Issue 3] YYYY-MM-DD

### database (Z)
- [Issue 4] YYYY-MM-DD
```

**成功经验示例**：

```markdown
# [SUCCESS] 2025-01-15: API Timeout (N+1 Query)

**Problem**
- API calls to `/api/posts` timeout after 30 seconds
- Users experiencing errors, 500 status
- Impact: High (core feature affected)

**Tags**
- type: error
- component: api, database
- method: 5-whys
- impact: high

**Investigation Method**
- Track A (5 Whys) - Clear error with stack trace
- Chose 5 Whys because explicit error indicated implementation issue

**Root Cause**
- N+1 query problem
- Fetching posts (1 query) + user for each post (N queries)
- Total: 1 + 1000 = 1001 queries for 1000 posts

**Solution Path**
- Fix System - Implementation error, design was correct
- Added eager loading with `.include('user')`

**Solution Details**
- Changed: `Post.findAll()` → `Post.findAll({ include: ['user'] })`
- Reduced queries: 1001 → 2
- Files modified: `api/posts.js`

**Verification**
- Before: 30s timeout, 1001 queries
- After: 200ms response, 2 queries
- Tested with 1000 posts
- Production verified: no errors in 24h

**Lessons Learned**
- Always check for N+1 queries first when dealing with performance
- ORM eager loading is simpler than caching

**Occurrences**
- First occurrence: 2025-01-02
- Last occurrence: 2025-01-15
- Frequency: 5 times (same pattern in different endpoints)
```

**失败经验示例**：

```markdown
# [FAILURE] 2025-01-10: Redis Cache for API

**Problem**
- API response slow (10 seconds)
- Attempted to add Redis caching layer

**Tags**
- type: performance
- component: api, cache
- method: first-principles
- impact: medium

**Investigation Method**
- Track B (First Principles) - Performance issue, unclear root cause
- Questioned: "Do we need to query database every time?"

**Attempted Solution**
- Added Redis cache with 5-minute TTL
- Cache-aside pattern implementation

**Why It Failed**
1. **Cache Invalidation Complexity**
   - Data changes frequently
   - Stale data caused user complaints
   - Complex invalidation logic required

2. **Operational Overhead**
   - Redis maintenance
   - Cache debugging complexity
   - Increased system complexity

3. **Rollback Required**
   - Users reported data inconsistency
   - Rolled back after 1 week
   - Lost development time

**Lessons Learned**
- Always plan cache invalidation strategy BEFORE implementation
- N+1 query fix (0.2s) was simpler than cache (complexity)
- Cache introduces operational costs

**Avoid**
- Using Redis for this use case (frequently changing data)
- Caching without clear invalidation strategy

**Better Alternative**
- Fixed N+1 query instead: 30s → 0.2s
- No cache needed, simpler solution

**Occurrences**
- First occurrence: 2025-01-10
- Frequency: 1 (attempted once, learned lesson)
```

**记录工具使用**：

```bash
# 创建新经验文件
cat > .claude/debug-experiences/2025-01-15-api-timeout.md << 'EOF'
[Paste template]
EOF

# 更新 INDEX.md
# 在 ## 🔥 High-Frequency Issues 添加（如果频率 ≥ 3）
# 在 ## 📅 Last 7 Days 添加
# 在 ## 🏷️ By Tag 添加

# 提交到 Git（可选）
git add .claude/debug-experiences/
git commit -m "docs: add debug experience - API timeout"
```

**自动创建流程**：

```
首次 Debug:
1. Phase 1.5: 检测到 `.claude/debug-experiences/` 不存在
2. 跳过错题集查询
3. 执行 Phase 2-5 正常流程
4. Phase 5.5: 自动创建目录 + INDEX.md + 第一条经验

后续 Debug:
1. Phase 1.5: 读取 INDEX，查询相关经验
2. Phase 2-5: 参考历史经验进行 debug
3. Phase 5.5: 记录新经验，更新 INDEX
```

**团队协作**：

- 错题集可以通过 Git 共享
- 团队成员可以互相参考经验
- 形成团队的"知识库"
- 建议在 `.gitignore` 中**不忽略** `.claude/debug-experiences/`

**向后兼容**：

- ✅ 首次使用无感知（自动创建）
- ✅ 老项目可以手动创建（可选）
- ✅ 不影响现有 debug 流程
- ✅ 可通过 `--no-history` 禁用

---

## 📋 案例对比：5 Whys vs 第一性原理

### 案例 1: API 查询慢

#### ❌ 错误的方法选择（误用 5 Whys）

```
问题: API 查询需要 10 秒

错误地使用 5 Whys:
- 慢？ → 返回 1000 条记录
- 1000 条？ → 没有分页
- 没有分页？ → 产品要求显示全部
- 产品要求？ → 需求文档这么写的

错误结论: "添加分页"（但这是需求/设计问题，不是实现错误）
```

**问题分析**：
- ❌ **这不是 5 Whys 的问题，而是方法选择错误**
- ❌ "性能问题"应该用第一性原理，而不是 5 Whys
- ❌ 当 5 Whys 推导到"需求文档这么写"时，说明已经超出了 5 Whys 的适用范围
- ✅ **正确的做法**：在 Phase 1 就识别出这是"性能问题"，直接使用轨道 B（第一性原理）

#### ✅ 用第一性原理（突破）

```
问题: API 查询需要 10 秒

第一性原理分析:

基本真理:
- 数据库查询: 1000 条记录 = 5s
- 网络传输: 1MB / 10Mbps = 0.8s
- 人眼处理: 只能同时看 10-20 条

质疑假设:
- "用户真的需要 1000 条吗？"
  → 观察: 99% 用户只看前 20 条

- "为什么是一次性查询？"
  → 假设: 用户需要浏览全部
  → 真相: 用户需要搜索/筛选，而不是浏览

重建方案:
- 方案 A: 添加搜索/筛选（不是分页）
- 方案 B: 无限滚动（不是一次性加载）
- 方案 C: 懒加载（按需加载）

结果: 不是"修复查询性能"，而是"重新设计交互"
```

### 案例 2: 数据库连接耗尽

#### ✅ 用 5 Whys（合适）

```
问题: API 500 错误，数据库连接池耗尽

5 Whys 分析:
- 耗尽？ → 连接未关闭
- 未关闭？ → 错误路径没调用 close()
- 没调用？ → 缺少 finally 块

SOLUTION: 添加 finally 块确保连接关闭
```

**为什么 5 Whys 合适？**
- 明确的错误（异常）
- 实现问题，不是设计问题
- 修复路径清晰

### 案例 3: 系统内存泄漏

#### ✅ 正确的方法选择（直接用第一性原理）

```
问题: 运行 1 小时后内存溢出

Phase 1 分类:
1. 这是"系统行为错误"还是"设计理解错误"？
   → 行为错误（内存溢出）
2. 这是"在现有框架内修复"还是"需要质疑框架"？
   → 需要质疑框架（缓存设计本身有问题）
3. 用户的真实目标是什么？
   → 系统稳定运行，不希望内存溢出

结论: 使用轨道 B（第一性原理）

第一性原理分析:
基本真理:
- 缓存是为了加速
- 但缓存有内存成本
- 内存是有限的

质疑假设:
- "我们需要缓存所有数据吗？"
  → 观察: 只缓存热点数据（20/80 法则）

- "为什么是内存缓存？"
  → 可以用 Redis

重建方案:
- 不修复"清理机制"（这只是在错误的基础上修补）
- 改用 LRU 淘汰策略
- 或迁移到 Redis

结果: 不是"修复泄漏"，而是"重新设计缓存策略"
```

**为什么不用 5 Whys？**
- ❌ 5 Whys 会推导到"没清理机制" → "添加清理机制"
- ❌ 这是在错误的设计上修补，而不是质疑设计本身
- ✅ 正确做法：识别这是"设计问题"，直接用第一性原理

**错误示例**（如果误用 5 Whys）：
```
5 Whys（错误的方法选择）:
- 溢出？ → 缓存无限增长
- 增长？ → 没有清理机制
- 没清理？ → 设计时没考虑

结论: "添加清理机制"（治标不治本）
```

---

## 🎯 决策指南：何时用哪种方法

### 使用 5 Whys（轨道 A）：

- ✅ 明确的错误/异常
- ✅ 系统行为符合设计，但实现有误
- ✅ 快速故障排查
- ✅ 生产环境事故

**示例**：
- NPE、500 错误、超时
- 权限错误、配置错误
- 数据丢失、损坏

### 使用第一性原理（轨道 B）：

- ✅ 性能问题（慢、卡顿）
- ✅ 复杂交互问题
- ✅ 设计可能有问题
- ✅ 5 Whys 找不到满意答案
- ✅ 需要 10x 优化而非 10% 优化

**示例**：
- 页面加载慢
- 数据处理慢
- 系统复杂度高
- 需要创新突破

### 混合使用（先 A 后 B）：

**注意**：这不是"先用 5 Whys，不行再换第一性原理"，而是：
1. **在 Phase 1 就正确分类**，直接选择合适的方法
2. **如果不确定，可以先用 5 Whys 快速试探**（5 分钟内）
   - 如果 5 Whys 推导到"需求"、"产品决策"等非实现层面
   - **立即停止，切换到第一性原理**（说明这不是实现错误）
   - 如果找到明确的代码/配置错误 → 继续用 5 Whys

**关键判断**：
- ✅ 5 Whys 第 3-5 问就能到代码层面 → 继续用 5 Whys
- ❌ 5 Whys 第 2-3 问就到"产品/需求"层面 → 应该用第一性原理

---

## ⚠️ 常见误区

### ❌ 误区 1: 滥用 5 Whys（用错方法）

**错误做法**：
```
问题: API 响应慢（10 秒）
直接用 5 Whys:
- 慢？ → 返回 1000 条
- 1000 条？ → 没有分页
- 没分页？ → 产品要求
→ 结论: "添加分页"（但这不是实现错误！）
```

**问题分析**：
- ❌ **这是方法选择错误，不是 5 Whys 的问题**
- ❌ 性能问题应该用第一性原理，而不是 5 Whys
- ❌ 当 5 Whys 推导到"产品/需求"层面时，说明选错方法了

**正确做法**：
```
Phase 1 先分类:
- 明确错误？ → NO（没有错误信息）
- 性能问题？ → YES
→ 直接用第一性原理（轨道 B）
```

**判断标准**：
- ✅ 5 Whys 第 3-5 问能到代码层面 → 继续用
- ❌ 5 Whys 第 2-3 问就到"需求/产品" → 应该用第一性原理

### ❌ 误区 2: 第一性原理 = 5 Whys

| **5 Whys** | **第一性原理** |
|---|---|
| 方向: 自顶向下 | 方向: 自底向上 |
| 目标: 找到根本原因 | 目标: 从零重建 |
| 提问: "为什么？" | 提问: "基本真理是什么？" |
| 适用: 调试、故障排查 | 适用: 创新、突破、性能优化 |
| 示例: 找出为什么页面加载慢 | 示例: 重新设计数据传输方式 |

### ❌ 误区 3: 第一性原理 = 忽略现有系统

```
错误: "假设没有限制，从零设计"
正确: "理解现有系统，但质疑其设计假设"
```

### ❌ 误区 4: 所有问题都用第一性原理

```
错误: "简单的 NPE 也要质疑整个系统设计"
正确: "明确的实现错误用 5 Whys，设计问题用第一性原理"
```

---

## 🛠️ 工具使用指南

### 调查阶段（所有方法通用）

**Read 工具**：
- ✅ 读取实际代码/配置
- ❌ 不要基于记忆或假设

**Grep 工具**：
- ✅ 搜索相关代码模式
- ✅ 检查类似问题

**Bash 工具**：
- ✅ 查看日志、进程
- ✅ 测试假设
- ✅ 验证生产环境

### 第一性原理专用技巧

**使用 Bash 测试基本真理**：
```bash
# 测试网络延迟基本限制
time curl https://api.example.com/endpoint

# 测试数据库查询基本性能
time mysql -e "SELECT * FROM large_table LIMIT 1000"

# 测试数据传输基本速度
dd if=/dev/zero of=test.dat bs=1M count=100
```

**使用 Read 理解设计假设**：
- 查看注释、文档、需求
- 理解"为什么这样设计"
- 找到可以质疑的假设

---

## 🔄 工作流程总结

### 完整流程图

```
0. [Phase 0] 重试检查（入口必执行）⭐ v7.0
   ├─ 读取 debug-log.md
   ├─ 尝试次数 >= 3 → ROLLBACK 信号 → 结束
   ├─ 尝试次数 < 3 → 读取排除方案列表
   └─ 不存在 → 首次尝试，创建文件
   ↓
1. [Phase 1] 信息收集 (Read/Grep/Bash)
   ↓
1.5. [Phase 1.5] 经验检索（智能激活）
   ├─ 检测错题集是否存在？
   │  ├─ 不存在 → 跳到 Phase 2
   │  └─ 存在 → 继续
   ├─ 读取 INDEX 前 50 行
   ├─ 相关性匹配（标签/关键词/频率）
   ├─ 展示 Top 3-5 条相关经验
   │  ├─ ⭐ 高频错误（≥ 3 次）
   │  ├─ 📅 最近 7 天
   │  └─ ⚠️  失败经验（避免此路径）
   └─ 询问用户是否参考 [Y/n]
   ↓
2. [Phase 2] 问题分类决策
   ↓
   ├─ 明确错误？ → 轨道 A (5 Whys)
   │    ↓
   │    ├─ 找到实现错误 → 修复 → 验证
   │    └─ 发现设计问题 → 轨道 B
   │
   └─ 性能/设计问题？ → 轨道 B (第一性原理)
        ↓
        ├─ 拆解到基本真理
        ├─ 质疑所有假设
        ├─ 从零重建方案
        └─ 选择解决路径
             ↓
             ├─ 修复系统
             ├─ 修改期望
             ├─ 重构系统
             └─ 接受差异
   ↓
4. [Phase 5] 验证（生产环境 + 标准测试）
   ↓
4.5. [Phase 5.5] 更新 debug-log.md ⭐ v7.0
   ├─ 记录本次尝试结果 (FIXED/FAILED)
   ├─ 如果 FIXED → 返回 FIXED 信号
   ├─ 如果 FAILED 且未达上限 → 返回 FAILED 信号
   └─ 如果 FAILED 且达上限 → 追加 EXHAUSTED 汇总 → 返回 ROLLBACK 信号
   ↓
5. [Phase 5.6] 记录经验（仅 FIXED 时）
   ├─ 创建/更新 .claude/debug-experiences/ 经验文件
   │  ├─ [SUCCESS] / [FAILURE]
   │  ├─ Problem, Tags, Root Cause, Solution
   │  └─ Lessons Learned (失败)
   ├─ 更新 INDEX.md
   │  ├─ 高频问题（≥ 3 次）
   │  ├─ 最近 7 天
   │  └─ 标签索引
   └─ 提交 Git（可选）
   ↓
6. 文档化（决策依据 + 解决方案）
```

### 语义激活流程

```
用户输入
   ↓
信号检测
   ├─ 🔴 强信号（错误代码/堆栈跟踪）
   │  → 自动激活 debug + 查询错题集
   │
   ├─ 🟡 中等信号（性能问题）
   │  → 询问"是否启动 dev-debug skill？"
   │
   └─ 🟢 弱信号（开发任务）
      → 正常回答，不激活
```

### 错题集检索流程

```
开始 debug
   ↓
检查 .claude/debug-experiences/INDEX.md
   ├─ 不存在 → 跳过（首次使用）
   └─ 存在 → 继续
      ↓
读取 INDEX 前 50 行（< 100 tokens）
   ↓
提取当前问题特征
   ├─ 错误类型（timeout/crash/leak）
   ├─ 组件（api/database/worker）
   └─ 关键词
      ↓
相关性匹配
   ├─ 频率优先（出现 5 次 > 出现 1 次）
   ├─ 时间优先（最近 7 天 > 1 个月前）
   └─ 标签匹配（3 个标签 > 1 个标签）
      ↓
选择 Top 3-5 条
   ↓
展示并询问用户
   ├─ ⭐ 高频错误 → "第 5 次出现，上次方案：..."
   ├─ ⚠️  失败经验 → "避免此路径，上次失败原因：..."
   └─ 📅 最近成功 → "7 天前解决过，方案：..."
   ↓
用户选择 [Y/n]
   ├─ Y → 参考经验继续 debug
   └─ n → 跳过，正常流程
```

---

## 💡 关键洞察

1. **5 Whys 和第一性原理是互补的，不是互斥的**
   - 5 Whys: 快速定位实现错误
   - 第一性原理: 深度质疑设计假设

2. **问题分类比解决问题更重要**
   - 错误的方法会浪费时间
   - 先分类，再选择方法

3. **不是所有问题都需要"修复"**
   - 修改期望可能更合适
   - 重构系统可能是更好选择
   - 接受差异有时是最优解

4. **工具是用来收集事实，不是验证假设**
   - 用 Read 看实际代码
   - 用 Bash 测试实际行为
   - 用 Grep 找相关模式

5. **生产环境验证是最后的防线**
   - 错误信息包含唯一真理
   - 文件名、URL、行号是事实
   - 工具成功 ≠ 生产正确

---

## 🎯 快速参考

### 问题分类决策树

```
开始
  ↓
是否有明确错误/异常？
  ├─ YES → 使用 5 Whys
  │         ↓
  │       是实现错误？
  │         ├─ YES → 修复系统
  │         └─ NO  → 切换到第一性原理
  │
  └─ NO → 使用第一性原理
           ↓
         性能/设计问题？
           ├─ YES → 质疑框架 → 重建
           └─ NO  → 重新分类
```

### 关键问题清单

**在 Layer 1（问题分类）问**：
1. "这是行为错误还是设计理解错误？"
2. "这是框架内修复还是需要质疑框架？"
3. "用户的真实目标是什么？"

**在轨道 A（5 Whys）问**：
1. "为什么会出现这个错误？"（连问 5 次）
2. "这是症状还是根因？"
3. "如何修复这个实现错误？"

**在轨道 B（第一性原理）问**：
1. "基本真理是什么？"
2. "哪些是物理法则，哪些只是假设？"
3. "如果从零开始，会怎么做？"

**在 Layer 3（解决路径）问**：
1. "应该修复系统、修改期望、重构系统，还是接受差异？"

---

## ⚠️ 常见陷阱

1. **猜测而不是阅读** - 始终使用 Read 工具查看实际代码
2. **治疗症状** - 使用 5 Whys 或第一性原理找到根因
3. **忽略用户目标** - 询问他们真正想要完成什么
4. **没有验证** - 始终计划如何测试修复
5. **过早的解决方案** - 在理解之前不要提出解决方案

### 🔴 生产环境陷阱

6. **信任"构建产物"而非"运行时错误"**
   - ❌ "本地构建看起来正确"
   - ✅ "用户的错误显示文件 ABC.js，让我检查那个文件"

7. **相信部署工具**
   - ❌ "Wrangler 说部署成功"
   - ✅ "让我验证实际提供的内容"

8. **忽略缓存层**
   - ❌ "我部署了，用户应该看到了"
   - ✅ "CDN 可能缓存了旧文件，让我验证"

---

## 📚 与其他技能的协作

### Debug + First-Principles

```
Debug 技能发现问题分类后：
- 如果需要第一性原理分析
  → 自动调用 first-principles 技能
  → 第一性原理分析完成后
  → 返回 debug 技能进行验证
```

### Debug + First-Principles-Planner

```
如果调试发现需要重构系统：
- 使用第一性原理分析后
- 发现需要重新设计功能
- 调用 first-principles-planner 制定实施计划
```

### 完整技能栈

| 场景 | 使用技能 |
|---|---|
| 系统出错/故障 | **debug** (5 Whys) |
| 性能/设计问题 | **debug** → **first-principles** |
| 需要重构系统 | **debug** → **first-principles** → **first-principles-planner** |
| 产品规划 | **first-principles-planner** |
| 创新突破 | **first-principles** |

---

## 📄 与 dev-loop / dev-flow 的集成

### 在 subagent 模式下的行为

当 dev-debug 被 dev-flow subagent 调用时：

```
dev-flow 检测到测试失败
  ↓
调用 dev-debug
  ↓
Phase 0: 检查 debug-log.md
  ├─ 已有 3 次尝试 → 返回 ROLLBACK 信号给 dev-flow
  │   → dev-flow 写入 task-result.md (ROLLBACK)
  │   → dev-loop 执行 git rollback
  │
  └─ 还有尝试机会 → 正常执行 Phase 1-5
      → 修复后返回 FIXED 信号给 dev-flow
      → dev-flow 重新测试
      → 如果通过 → task-result.md (SUCCESS)
      → 如果失败 → 再次调用 dev-debug（循环）
```

### 信号协议

| 信号 | 含义 | 触发条件 |
|------|------|----------|
| `FIXED` | 问题已修复 | Phase 5 验证通过 |
| `FAILED` | 本次尝试失败 | Phase 5 验证未通过，但还有重试机会 |
| `ROLLBACK` | 放弃修复 | 已达 MAX_DEBUG_RETRIES (3次) |

---

**版本**: v7.0.0 (保底回退机制 + debug-log.md 协议)
**最后更新**: 2026-02-13

**End of Dev-Debug Skill**
