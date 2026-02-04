---
name: skill-checker
description: Claude Skills管理工具 - 检查并列出本地skills和marketplace插件，检测插件更新并提示升级。触发场景："检查技能更新"、"skill更新"、"插件升级"、"查看已安装skills"。
---

# Skill Checker

> **触发条件**（技能管理场景）：
> - 🔍 **检查更新**："检查技能更新"、"skill更新"、"插件升级"、"插件有更新吗"
> - 📋 **列出技能**："查看已安装skills"、"列出所有技能"、"有哪些插件"
> - 🔄 **同步更新**："更新所有插件"、"同步marketplace"
>
> **功能**：
> - 区分本地skills和marketplace插件
> - 检查marketplace插件是否有新版本
> - 提供更新建议和执行方案

---

## 🎯 功能概述

### 能力清单

1. **本地Skills检查**
   - 扫描 `~/.claude/skills/` 目录
   - 识别软链接和实体目录
   - 区分官方skills和用户自定义skills

2. **Marketplace插件检查**
   - 读取 `~/.claude/plugins/installed_plugins.json`
   - 读取 `~/.claude/plugins/known_marketplaces.json`
   - 通过git fetch检查远程更新

3. **更新检测**
   - 比较本地git commit和远程仓库
   - 生成更新报告
   - 询问用户是否执行更新

---

## 📂 数据结构解析

### Claude Skills 目录结构

```
~/.claude/
├── skills/                          # 技能目录
│   ├── official/skills/            # 官方技能（实际存储）
│   │   ├── algorithmic-art/
│   │   ├── brand-guidelines/
│   │   └── ...
│   ├── algorithmic-art -> ...      # 软链接到官方技能
│   ├── brand-guidelines -> ...
│   └── ...
│
├── plugins/                        # 插件目录
│   ├── marketplaces/              # Marketplace源码
│   │   ├── ai-developer-skills/   # GitHub仓库克隆
│   │   ├── claude-plugins-official/
│   │   └── claude-code-templates/
│   ├── installed_plugins.json     # 已安装插件记录
│   ├── known_marketplaces.json    # Marketplace元数据
│   └── cache/                     # 插件安装缓存
│
└── settings.json                  # Claude配置
```

### 关键文件格式

**installed_plugins.json**:
```json
{
  "version": 2,
  "plugins": {
    "plugin-name@marketplace": [
      {
        "scope": "user",
        "installPath": "/path/to/plugin/version",
        "version": "commit-sha",
        "installedAt": "ISO-8601-timestamp",
        "lastUpdated": "ISO-8601-timestamp",
        "gitCommitSha": "full-git-commit-sha"
      }
    ]
  }
}
```

**known_marketplaces.json**:
```json
{
  "marketplace-name": {
    "source": {
      "source": "github",
      "repo": "owner/repo-name"
    },
    "installLocation": "/path/to/marketplace",
    "lastUpdated": "ISO-8601-timestamp"
  }
}
```

---

## 🛠️ 执行流程

### Phase 1: 扫描本地Skills

```bash
# 1. 列出所有skills
ls -la ~/.claude/skills/

# 2. 区分类型：
#    - 软链接 (-> official/skills/xxx) = 官方本地skill
#    - 普通目录 = 可能是用户自定义skill
#    - 检查链接目标是否存在
```

**输出格式**:
```
本地Skills:
[官方] algorithmic-art (official/skills/algorithmic-art)
[官方] brand-guidelines (official/skills/brand-guidelines)
[自定义] my-custom-skill (本地目录)
```

### Phase 2: 扫描Marketplace插件

```bash
# 1. 读取installed_plugins.json
cat ~/.claude/plugins/installed_plugins.json

# 2. 提取插件信息
#    - 插件名称
#    - 来源marketplace
#    - 当前版本
#    - 安装路径
```

**输出格式**:
```
Marketplace插件:
[ai-developer-skills] first-principles (v9de61b2)
[ai-developer-skills] dev-flow (v41ac7db)
[claude-plugins-official] plugin-dev (ve307683)
[claude-code-templates] testing-suite (v1.0.0)
```

### Phase 3: 检查更新

```bash
# 对于每个marketplace:
cd /path/to/marketplace
git fetch origin
git rev-parse HEAD          # 本地commit
git rev-parse origin/main   # 远程commit

# 比较是否一致
```

**更新检测逻辑**:
```python
for marketplace in marketplaces:
    local_commit = get_local_commit(marketplace)
    remote_commit = get_remote_commit(marketplace)

    if local_commit != remote_commit:
        plugins_need_update.append({
            "marketplace": marketplace,
            "local": local_commit[:8],
            "remote": remote_commit[:8],
            "affected_plugins": get_plugins_from(marketplace)
        })
```

**输出格式**:
```
📦 可更新插件:

[ai-developer-skills]
  本地: 79db6d4
  远程: 85a58d7
  受影响插件:
    - dev-review
    - dev-loop
    - dev-debug

建议执行: cd ~/.claude/plugins/marketplaces/ai-developer-skills && git pull
```

### Phase 4: 询问并执行更新

使用 `AskUserQuestion` 工具询问用户：

```javascript
{
  "questions": [{
    "question": "检测到 3 个marketplace有更新，是否执行更新？",
    "header": "更新确认",
    "options": [
      {
        "label": "全部更新",
        "description": "更新所有过期的marketplace插件"
      },
      {
        "label": "选择性更新",
        "description": "手动选择要更新的marketplace"
      },
      {
        "label": "跳过",
        "description": "暂不更新，仅查看状态"
      }
    ],
    "multiSelect": false
  }]
}
```

如果用户选择更新，执行：
```bash
cd ~/.claude/plugins/marketplace/{name}
git pull origin main
```

---

## 📊 输出报告模板

### 完整报告示例

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Claude Skills 状态报告
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 本地Skills (18个)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[官方] algorithmic-art
[官方] brand-guidelines
[官方] canvas-design
[官方] doc-coauthoring
[官方] docx
[官方] frontend-design
[官方] internal-comms
[官方] mcp-builder
[官方] pdf
[官方] pptx
[官方] skill-creator
[官方] slack-gif-creator
[官方] theme-factory
[官方] web-artifacts-builder
[官方] webapp-testing
[官方] xlsx

📦 Marketplace插件 (30个)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[ai-developer-skills] (14个插件)
  ✓ conversation-exporter (6f9046cc) ✅ 最新
  ⚠ first-principles (9de61b24) 🔄 可更新
  ⚠ dev-flow (41ac7db4) 🔄 可更新
  ...

[claude-plugins-official] (6个插件)
  ✓ notion (19a119f9) ✅ 最新
  ✓ plugin-dev (e3076837) ✅ 最新
  ⚠ playwright (e3076837) 🔄 可更新
  ...

[claude-code-templates] (10个插件)
  ✓ testing-suite (1.0.0) ✅ 最新
  ✓ documentation-generator (1.0.0) ✅ 最新
  ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 统计
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
总Skills: 18个
总插件: 30个
可更新: 5个插件 (来自2个marketplace)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🔧 实现要点

### 关键命令

```bash
# 检查软链接
readlink ~/.claude/skills/skill-name

# 检查git更新
cd /path/to/repo
git fetch --quiet origin
git rev-parse HEAD           # 本地commit
git rev-parse origin/main    # 远程commit
git log HEAD..origin/main --oneline  # 查看更新内容

# 获取插件信息
jq '.plugins | keys' ~/.claude/plugins/installed_plugins.json
jq '.["plugin-name@marketplace"][0]' ~/.claude/plugins/installed_plugins.json
```

### 错误处理

1. **网络错误**: git fetch失败时标记为"无法检查"
2. **权限问题**: 跳过无权限访问的目录
3. **损坏的链接**: 标记为"已断开"
4. **JSON解析失败**: 使用备用方法扫描目录

---

## 💡 使用建议

### 最佳实践

1. **定期检查**: 建议每周运行一次
2. **选择性更新**: 关注重要的插件更新
3. **备份配置**: 更新前备份settings.json
4. **查看变更**: 更新前查看git log了解变更

### 相关命令

- **查看单个插件详情**: `cd ~/.claude/plugins/cache/{marketplace}/{plugin}/{version}/ && cat PLUGIN.md`
- **手动更新**: `cd ~/.claude/plugins/marketplaces/{name} && git pull`
- **禁用插件**: 编辑 `~/.claude/settings.json`，在 `enabledPlugins` 中设置false

---

## 🎯 触发场景

**自动触发**:
- 用户说"检查更新"、"查看skills"、"列出插件"
- 用户询问"有没有新版本"、"插件版本"

**手动触发**:
- 在需要更新插件时
- 在添加新插件后验证安装
- 在排查插件相关问题时

---

**End of Skill Checker**
