# Skill Checker

Claude Skills管理工具 - 检查并列出本地skills和marketplace插件，检测插件更新并提示升级。

## 功能

- 🔍 **本地Skills扫描** - 区分官方/自定义技能
- 📦 **Marketplace插件检查** - 读取已安装插件列表
- 🔄 **更新检测** - 通过git对比本地/远程commit
- 📊 **详细报告** - 显示受影响插件和更新内容
- 🚀 **一键更新** - 自动执行插件更新
- ⭐ **My Skills** - 追踪和显示常用技能，记录使用历史

## 安装

将此目录作为skill或插件添加到Claude Code。

## 使用方式

### 作为Skill使用

触发条件：
- "检查技能更新"、"skill更新"、"插件升级"
- "查看已安装skills"、"列出所有技能"
- "有哪些插件"
- "我的常用技能"、"使用记录"、"my-skills"

### 直接运行脚本

```bash
# 检查所有
python3 check_skills.py

# 仅检查本地skills
python3 check_skills.py --local

# 仅检查插件
python3 check_skills.py --plugins

# 输出JSON格式
python3 check_skills.py --json

# 更新所有marketplace
python3 check_skills.py --update

# 更新指定marketplace
python3 check_skills.py --update claude-plugins-official

# 显示我的常用skills
python3 check_skills.py --my-skills

# 记录使用的skill
python3 check_skills.py --record <skill-name>

# 记录并指定marketplace
python3 check_skills.py --record <skill-name> --marketplace ai-developer-skills
```

## 输出示例

```
============================================================
🔍 Claude Skills 状态报告
============================================================

📁 本地Skills (16个)
------------------------------------------------------------
[官方] ✅ algorithmic-art
[官方] ✅ brand-guidelines
...

📦 Marketplace插件 (30个)
------------------------------------------------------------

[ai-developer-skills] ✅ 最新
  • dev-flow (v41ac7db4)
  • dev-review (v79db6d47)
  ...

[claude-plugins-official] ⚠️ 可更新
  本地: e3076837 → 远程: 27d2b86d
  • playwright (ve3076837)
  ...
```

## My Skills 功能

### 查看常用技能

```bash
/my-skills
```

或

```bash
python3 check_skills.py --my-skills
```

### 输出示例

```
⭐ 我的常用 Skills
============================================================

🔥 最常用 (Top 4)
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

## 文件结构

```
skill-checker/
├── .claude-plugin/
│   └── plugin.json          # 插件清单
├── commands/
│   ├── check-skills.md      # /check-skills 命令
│   ├── update-skills.md     # /update-skills 命令
│   └── my-skills.md         # /my-skills 命令
├── skills/
│   └── skill-checker/
│       └── SKILL.md         # 技能文档
├── scripts/
│   └── check_skills.py      # 检查脚本
└── README.md                # 本文件
```

## 依赖

- Python 3.6+
- Git
- Claude Code (用于skill集成)

## 许可证

MIT
