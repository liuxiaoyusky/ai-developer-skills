# Changelog

## [1.1.0] - 2026-02-04

### Added
- ⭐ **My Skills 功能** - 追踪和显示常用技能
- ✨ 使用历史记录 - 自动记录每次skill使用
- ✨ 使用统计功能 - 显示最常用和最近使用的skills
- 📝 /my-skills 命令 - 快速查看常用技能
- 📝 `--my-skills` 选项 - 显示常用skills列表
- 📝 `--record` 选项 - 手动记录使用的skill
- 💾 skills-usage.json - 使用历史存储文件

### Features
- 支持记录skill使用次数和最后使用时间
- 按使用频率和最近使用时间排序
- 显示技能来源marketplace
- 可手动编辑使用历史
- 跨平台支持（Linux/macOS/Windows）

## [1.0.0] - 2026-02-04

### Added
- 🎉 初始发布 skill-checker 技能
- ✨ 本地Skills扫描功能 - 区分官方/自定义技能
- ✨ Marketplace插件检查功能 - 读取已安装插件列表
- ✨ 更新检测功能 - 通过git对比本地/远程commit
- ✨ 详细报告功能 - 显示受影响插件、commits behind
- ✨ 一键更新功能 - 支持自动更新marketplace
- 📝 完整的SKILL.md文档
- 📝 Python检查脚本 (check_skills.py)
- 📝 两个命令：/check-skills 和 /update-skills

### Features
- 检测16个本地官方skills
- 支持31个marketplace插件
- 自动检测marketplace更新
- JSON格式输出支持
- 跨平台支持（Linux/macOS/Windows）
