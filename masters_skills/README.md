# Masters Skills

> **出处**: 本目录下的所有技能来自 [GBSOSS/skill-from-masters](https://github.com/GBSOSS/skill-from-masters)
>
> **理念**: "Stand on the shoulders of giants" — 站在巨人的肩膀上
>
> **管理方式**: 使用 Git Submodule 进行版本管理，确保与官方仓库同步
>
> **更新方式**: `git submodule update --remote masters_skills/skills`

## 目录说明

```
masters_skills/
├── README.md              # 本文件
└── skills/                # Git Submodule: GBSOSS/skill-from-masters
    ├── skill-from-masters/    # 主技能：基于大师方法论创建技能
    │   ├── SKILL.md
    │   └── references/
    └── skills/                # 辅助子技能
        ├── search-skill/      # 搜索技能
        ├── skill-from-github/ # 从 GitHub 仓库提取技能
        └── skill-from-notebook/ # 从 Notebook 提取技能
```

## 核心理念

**"创建技能的难点不在于格式，而在于知道最佳实践。"**

这个技能集合帮助你在生成任何新技能之前，先发现并融合各领域大师的方法论、原则和最佳实践。

### 大师方法示例

| 领域 | 大师 | 专长 |
|------|------|------|
| 产品 | Steve Jobs | 产品思维、招聘、营销 |
| 决策 | Jeff Bezos | 6页备忘录、决策机制 |
| 思维 | Charlie Munger | 心智模型 |
| 谈判 | Chris Voss | 谈判策略 |

## 包含的技能

### 1. skill-from-masters (主技能)
基于大师方法论创建 AI 技能的核心技能。

**工作流程**:
1. 检查本地方法论数据库
2. 网络搜索额外的专家资源
3. 找到优秀输出的黄金示例
4. 识别需要避免的常见错误
5. 跨来源交叉验证

**特性**:
- **3层搜索**: 本地数据库 → 专家网络搜索 → 深度挖掘原始资料
- **黄金示例**: 找到示范性输出以定义质量标准
- **反模式**: 搜索常见错误以编码"不要这样做"
- **交叉验证**: 比较多位专家以找到共识和分歧
- **质量清单**: 在生成前验证完整性

### 2. search-skill
网络搜索技能，用于查找专家资源和最佳实践。

### 3. skill-from-github
从 GitHub 仓库自动提取和生成技能。

### 4. skill-from-notebook
从 Notebook 文档中提取和生成技能。

## 安装子模块

如果首次克隆此仓库后子模块为空：

```bash
# 初始化并更新子模块
git submodule update --init --recursive

# 或者单独更新
cd masters_skills
git submodule update --init --recursive
```

## 更新技能

```bash
# 更新到最新版本
git submodule update --remote masters_skills/skills

# 查看子模块状态
git submodule status
```

## 使用方法

安装后，你可以直接使用：

```
"使用 skill-from-masters 技能创建一个用户访谈技能"
"基于大师方法论为代码审查创建技能"
"用 skill-from-masters 生成技术写作指南"
```

## 方法论数据库

技能包含涵盖 15+ 领域的精选数据库，包括但不限于：

- 产品管理
- 用户研究
- 代码审查
- 技术写作
- 决策制定
- 谈判技巧
- 系统设计
- ...

## 许可证

MIT License - 详见 [原始仓库](https://github.com/GBSOSS/skill-from-masters/blob/main/LICENSE)

## 贡献

这些是社区技能的镜像，不建议直接修改。如需贡献，请前往 [GBSOSS/skill-from-masters](https://github.com/GBSOSS/skill-from-masters) 提交 PR。

---

**最后更新**: 2026-02-03
**原始仓库**: [GBSOSS/skill-from-masters](https://github.com/GBSOSS/skill-from-masters)
**标语**: Stand on the shoulders of giants 🦸‍♂️
