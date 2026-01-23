# Conversation Exporter Skill

将Claude Code对话导出为Markdown格式的技能。

## 文件结构

```
conversation-exporter/
├── SKILL.md                          # 技能主文档
├── scripts/
│   └── export-conversation.py        # Python导出脚本
├── references/
│   └── example.md                    # 使用示例
└── README.md                         # 本文件
```

## 部署到Claude Code

### 方法1: 通过Skill系统部署

1. **确认skill位置**：
   ```bash
   ls -la /Users/xiaoyuliu/Documents/github/ai-developer-skills/general/conversation-exporter/
   ```

2. **在Claude Code中使用**：
   - 直接说："Use conversation-exporter skill"
   - 或："使用conversation-exporter技能"

### 方法2: 手动安装（如果需要）

如果skill没有被自动发现，可能需要：

1. **检查Claude Code的skills路径**：
   ```bash
   ls -la ~/.claude/skills/
   ```

2. **创建软链接**：
   ```bash
   ln -s /Users/xiaoyuliu/Documents/github/ai-developer-skills/general/conversation-exporter \
          ~/.claude/skills/conversation-exporter
   ```

## 测试步骤

### 1. 基础测试（Minimal模式）

在Claude Code中说：
```
Export this conversation to markdown
```

**预期结果**：
- 创建文件：`conversation-export_20260123.md`
- 包含用户和助手的对话
- 过滤掉噪音消息

### 2. 指定文件名测试

```
Export this conversation to test-export.md
```

**预期结果**：
- 创建文件：`test-export.md`
- 内容与基础测试相同

### 3. Standard模式测试

```
Export this conversation in standard mode to standard-test.md
```

**预期结果**：
- 创建文件：`standard-test.md`
- 包含对话内容
- 包含工具调用（Read, Edit, Bash等）

### 4. Detailed模式测试

```
Export this conversation in detailed mode to detailed-test.md
```

**预期结果**：
- 创建文件：`detailed-test.md`
- 包含所有内容
- 包含工具输出
- 包含代码diffs

### 5. 指定对话文件测试

```
Export ~/.claude/projects/-Users-xiaoyuliu-Documents-github-volaris-web/f0eb6929-aad2-45f5-aaf9-898e1be823b7.jsonl to specific-test.md
```

**预期结果**：
- 导出指定的会话文件
- 创建 `specific-test.md`

## 直接使用Python脚本测试

你也可以直接测试Python脚本：

```bash
# Minimal模式
python3 /Users/xiaoyuliu/Documents/github/ai-developer-skills/general/conversation-exporter/scripts/export-conversation.py \
  ~/.claude/projects/-Users-xiaoyuliu-Documents-github-volaris-web/f0eb6929-aad2-45f5-aaf9-898e1be823b7.jsonl \
  test-minimal.md \
  minimal

# Standard模式
python3 /Users/xiaoyuliu/Documents/github/ai-developer-skills/general/conversation-exporter/scripts/export-conversation.py \
  ~/.claude/projects/-Users-xiaoyuliu-Documents-github-volaris-web/f0eb6929-aad2-45f5-aaf9-898e1be823b7.jsonl \
  test-standard.md \
  standard

# Detailed模式
python3 /Users/xiaoyuliu/Documents/github/ai-developer-skills/general/conversation-exporter/scripts/export-conversation.py \
  ~/.claude/projects/-Users-xiaoyuliu-Documents-github-volaris-web/f0eb6929-aad2-45f5-aaf9-898e1be823b7.jsonl \
  test-detailed.md \
  detailed
```

## 验证清单

测试时检查以下项目：

- [ ] Skill可以被Claude Code识别
- [ ] Minimal模式导出干净，只有对话
- [ ] Standard模式包含工具调用
- [ ] Detailed模式包含工具输出
- [ ] 文件命名正确（默认或自定义）
- [ ] 时间戳格式正确
- [ ] Markdown格式正确
- [ ] 中文内容显示正常
- [ ] 空消息被正确过滤
- [ ] 错误处理正常（文件不存在等）

## 故障排查

### Skill未被识别

**问题**：Claude Code说找不到skill

**解决方案**：
1. 确认SKILL.md文件存在且格式正确
2. 检查YAML frontmatter是否完整
3. 尝试重启Claude Code

### 导出文件为空

**问题**：导出的markdown文件没有内容

**解决方案**：
1. 检查源.jsonl文件路径是否正确
2. 使用直接Python脚本测试
3. 查看错误消息

### 包含太多空消息

**问题**：导出的文件有很多空的对话

**解决方案**：
1. 确认使用的是最新版本的脚本
2. 检查脚本中是否有过滤空消息的逻辑

## 下一步

测试成功后，你可以：

1. **提交到Git仓库**：
   ```bash
   cd /Users/xiaoyuliu/Documents/github/ai-developer-skills
   git add general/conversation-exporter/
   git commit -m "Add conversation-exporter skill"
   git push
   ```

2. **创建更多skills**：
   - 复制这个结构
   - 修改SKILL.md
   - 实现新的功能

3. **改进现有skill**：
   - 添加更多导出选项
   - 支持其他格式（PDF、HTML等）
   - 添加搜索和过滤功能

---

**Good luck with your testing!** 🚀
