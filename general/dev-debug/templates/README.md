# Debug Skill Templates

此目录包含 Debug Skill 错题集功能的模板文件。

## 📁 文件说明

### `debug-experience-template.md`
单个调试经验的详细记录模板。

**使用场景**：
- Debug 完成后记录详细经验
- 包含问题描述、调查过程、解决方案、验证结果
- 适用于成功和失败的经验

**主要字段**：
- Problem: 问题描述
- Tags: 标签（类型、组件、方法、影响）
- Root Cause: 根本原因
- Solution Details: 解决方案详情
- Verification: 验证结果
- Lessons Learned: 经验教训（失败经验必填）

### `debug-index-template.md`
错题集索引文件模板。

**使用场景**：
- 快速浏览项目的历史调试经验
- 按频率、时间、标签分类
- 轻量级查询（只读前 50 行，< 100 tokens）

**主要部分**：
- 🔥 High-Frequency Issues: 出现 ≥ 3 次的问题
- 📅 Last 7 Days: 最近 7 天的经验
- 🏷️ By Tag: 按标签分类的索引

## 🚀 使用方法

### 首次使用

Debug Skill 会自动创建错题集目录：

```bash
# 自动创建
.claude/debug-experiences/
├── INDEX.md
└── YYYY-MM-DD-issue-description.md
```

### 手动创建（可选）

如果你想手动创建错题集：

```bash
# 1. 创建目录
mkdir -p .claude/debug-experiences

# 2. 复制模板
cp templates/debug-index-template.md .claude/debug-experiences/INDEX.md

# 3. 创建第一个经验文件
cp templates/debug-experience-template.md .claude/debug-experiences/2025-01-15-first-issue.md

# 4. 编辑文件，填写内容
vim .claude/debug-experiences/2025-01-15-first-issue.md

# 5. 更新 INDEX.md
vim .claude/debug-experiences/INDEX.md
```

### 文件命名规范

```
格式: YYYY-MM-DD-short-description.md

示例:
✅ 2025-01-15-api-timeout-n-plus-1.md
✅ 2025-01-10-redis-cache-failure.md
✅ 2025-01-08-memory-leak-worker.md

❌ issue-1.md (缺少日期和描述)
❌ API_TIMEOUT.md (全大写，缺少日期)
❌ 2025-01-15 (缺少描述)
```

## 📝 快速开始示例

### 记录一个成功的调试经验

```bash
# 1. 复制模板
cp templates/debug-experience-template.md \
   .claude/debug-experiences/2025-01-27-api-timeout.md

# 2. 编辑文件，填写内容
# - Problem: API 超时 30 秒
# - Tags: error, api, database, 5-whys, high
# - Root Cause: N+1 查询问题
# - Solution Details: 添加 eager loading
# - Verification: 30s → 0.2s
# - Lessons Learned: 优先检查 N+1 查询

# 3. 更新 INDEX.md
# 在 ## 📅 Last 7 Days 添加:
### [SUCCESS] 2025-01-27: API Timeout (N+1 Query)
**Tags**: error, api, database
**Method**: 5 Whys
**Lesson**: Always check for N+1 queries first
→ [Read more](2025-01-27-api-timeout.md)

# 4. 更新统计信息
# - 总经验数: 1
# - 成功经验: 1
# - 最后更新: 2025-01-27
```

### 记录一个失败的调试尝试

```bash
# 1. 创建失败经验文件
cp templates/debug-experience-template.md \
   .claude/debug-experiences/2025-01-27-redis-cache-failed.md

# 2. 标记为 FAILURE
# 将标题改为: # [FAILURE] 2025-01-27: Redis Cache Attempt

# 3. 填写失败原因
# - Why It Failed: 缓存失效策略太复杂
# - Lessons Learned: 先规划失效策略
# - Avoid: 对频繁变化的数据使用缓存

# 4. 更新 INDEX.md
### [FAILURE] 2025-01-27: Redis Cache Attempt
**Why Failed**: Cache invalidation too complex
**Lesson**: Plan invalidation strategy first
→ [Read more](2025-01-27-redis-cache-failed.md)
```

## 🎯 最佳实践

### 1. 及时记录
- ✅ Debug 完成后立即记录（记忆最清晰）
- ❌ 不要等到"有空再说"（容易遗漏细节）

### 2. 详细但不冗余
- ✅ 包含关键信息：问题、根因、方案、验证
- ❌ 避免流水账式记录

### 3. 标签规范
```yaml
type: error | performance | design | behavior
component: api | database | frontend | worker | cache | other
method: 5-whys | first-principles
impact: high | medium | low
```

### 4. 验证结果
- ✅ 包含具体的指标（响应时间、错误率）
- ✅ 记录生产环境验证结果
- ❌ 不要只说"问题解决了"

### 5. 失败经验同样重要
- ✅ 记录为什么失败
- ✅ 明确"避免此路径"
- ✅ 提供更好的替代方案

### 6. 保持 INDEX.md 简洁
- ✅ INDEX 只包含摘要（< 100 tokens）
- ✅ 详细内容在单独的文件中
- ❌ 不要在 INDEX 中写长篇大论

## 🔍 查询经验

### 快速浏览

```bash
# 只读前 50 行（高频 + 最近）
head -n 50 .claude/debug-experiences/INDEX.md
```

### 按标签搜索

```bash
# 搜索 API 相关问题
grep -i "api" .claude/debug-experiences/INDEX.md

# 搜索性能问题
grep -i "performance" .claude/debug-experiences/INDEX.md

# 搜索高频问题
grep "⭐" .claude/debug-experiences/INDEX.md
```

### 读取详细经验

```bash
# 读取特定经验文件
cat .claude/debug-experiences/2025-01-27-api-timeout.md
```

## 🤝 团队协作

### Git 版本控制

```bash
# 添加到 Git
git add .claude/debug-experiences/

# 提交
git commit -m "docs: add debug experience - API timeout (N+1 query)"

# 推送到远程
git push
```

### .gitignore 设置

**建议：不要忽略错题集**

```bash
# ❌ 不要在 .gitignore 中添加
.claude/debug-experiences/

# ✅ 让错题集随代码一起版本控制
# 这样团队成员可以共享经验
```

### 团队使用场景

1. **新成员入职**
   - 查看 `.claude/debug-experiences/INDEX.md`
   - 快速了解项目的历史问题
   - 学习团队的调试经验

2. **代码审查**
   - 检查是否有类似的失败经验
   - 避免重复掉坑

3. **故障排查**
   - 先搜索错题集
   - 参考历史解决方案

## 📊 维护建议

### 定期清理

```bash
# 每月检查一次
# - 合并重复的经验
# - 更新统计信息
# - 归档旧经验（可选）
```

### 高频问题升级

当一个问题的频率 ≥ 3 时：
1. 在 INDEX.md 中添加到 🔥 High-Frequency Issues
2. 提炼 Quick Fix（一行解决方案）
3. 标记为 ⭐ high-freq

### 归档旧经验（可选）

对于超过 6 个月的经验：
```bash
# 创建归档目录
mkdir -p .claude/debug-experiences/archived

# 移动旧经验
mv .claude/debug-experiences/2024-*.md \
   .claude/debug-experiences/archived/

# 更新 INDEX.md
# 添加 ## 📦 Archived (6+ months ago)
```

## 🔧 故障排查

### 错题集不工作？

**检查目录是否存在**：
```bash
ls -la .claude/debug-experiences/
```

**检查 INDEX.md 是否存在**：
```bash
cat .claude/debug-experiences/INDEX.md
```

**手动触发创建**：
```bash
mkdir -p .claude/debug-experiences
cp templates/debug-index-template.md \
   .claude/debug-experiences/INDEX.md
```

### 找不到相关经验？

**检查标签是否正确**：
```bash
grep "your-tag" .claude/debug-experiences/INDEX.md
```

**尝试其他关键词**：
```bash
grep -i "timeout|slow|performance" \
   .claude/debug-experiences/INDEX.md
```

## 📚 相关资源

- [Debug Skill 文档](../SKILL.md)
- [如何构建 Skills](../../docs/how-to-build-skills.md)
- [第一性原理技能](../../general/first-principles/SKILL.md)

---

**最后更新**: 2025-01-27
**维护者**: Debug Skill
