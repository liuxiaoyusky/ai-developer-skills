---
name: update-skills
description: 更新所有过期的marketplace插件到最新版本
---

# /update-skills

更新所有已安装的marketplace插件到最新版本。

## 使用方法

```bash
/update-skills                    # 更新所有marketplace
/update-skills --marketplace <name>  # 更新指定marketplace
```

## 功能

1. 检查每个marketplace的更新状态
2. 执行git pull获取最新代码
3. 显示更新结果

## 注意事项

- 更新前建议查看变更内容
- 某些更新可能包含破坏性变更
- 更新后重启Claude Code以生效
