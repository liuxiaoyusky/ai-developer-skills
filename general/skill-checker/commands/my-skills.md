---
name: my-skills
description: 显示我的常用skills，包括使用频率和最近使用记录
---

# /my-skills

显示你常用的 skills，帮助你快速找到和启动使用频率高的技能。

## 使用方法

```bash
/my-skills
```

## 功能

1. **最常用 Skills** - 按使用次数排序，显示你最常用的 15 个技能
2. **最近使用** - 按时间排序，显示最近使用的 10 个技能
3. **使用统计** - 显示每个技能的使用次数和最后使用时间
4. **一键启动** - 复制技能名称即可在对话中使用

## 输出示例

```
⭐ 我的常用 Skills
============================================================

🔥 最常用 (Top 15)
------------------------------------------------------------
 1. first-principles
    来源: ai-developer-skills
    使用次数: 42
    最后使用: 2026-02-04 10:30

 2. dev-flow
    来源: ai-developer-skills
    使用次数: 35
    最后使用: 2026-02-04 09:15

...

🕐 最近使用
------------------------------------------------------------
 1. skill-checker (ai-developer-skills) - 02-04 10:30
 2. frontend-design (claude-plugins-official) - 02-04 09:45
 3. dev-debug (ai-developer-skills) - 02-04 09:15
...
```

## 手动记录技能

如果你想手动记录使用的技能：

```bash
# 记录使用某个技能
python3 ~/.claude/plugins/cache/ai-developer-skills/skill-checker/1.0.0/scripts/check_skills.py --record skill-name

# 记录并指定marketplace
python3 ~/.claude/plugins/cache/ai-developer-skills/skill-checker/1.0.0/scripts/check_skills.py --record skill-name --marketplace ai-developer-skills
```

## 数据存储

使用历史存储在：`~/.claude/skills-usage.json`

你可以：
- 查看原始数据：`cat ~/.claude/skills-usage.json`
- 备份数据：`cp ~/.claude/skills-usage.json ~/skills-usage-backup.json`
- 清空历史：`rm ~/.claude/skills-usage.json`
