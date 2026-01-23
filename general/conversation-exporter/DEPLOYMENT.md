# Deployment Guide - Conversation Exporter Skill

## ✅ Skill已准备就绪

**位置**: `/Users/xiaoyuliu/Documents/github/ai-developer-skills/general/conversation-exporter/`

**状态**: 已测试并验证工作正常

---

## 快速测试

### 在Claude Code中测试

打开新的Claude Code会话，然后说：

```
Use conversation-exporter to export this conversation
```

或者

```
使用conversation-exporter技能导出这个对话
```

### 直接Python脚本测试

```bash
cd /Users/xiaoyuliu/Documents/github/ai-developer-skills/general/conversation-exporter

# Minimal模式测试
python3 scripts/export-conversation.py \
  ~/.claude/projects/-Users-xiaoyuliu-Documents-github-volaris-web/f0eb6929-aad2-45f5-aaf9-898e1be823b7.jsonl \
  /tmp/test-minimal.md \
  minimal

# Standard模式测试
python3 scripts/export-conversation.py \
  ~/.claude/projects/-Users-xiaoyuliu-Documents-github-volaris-web/f0eb6929-aad2-45f5-aaf9-898e1be823b7.jsonl \
  /tmp/test-standard.md \
  standard

# Detailed模式测试
python3 scripts/export-conversation.py \
  ~/.claude/projects/-Users-xiaoyuliu-Documents-github-volaris-web/f0eb6929-aad2-45f5-aaf9-898e1be823b7.jsonl \
  /tmp/test-detailed.md \
  detailed
```

---

## 文件清单

✅ `SKILL.md` - 技能主文档（完整的YAML frontmatter和使用说明）
✅ `scripts/export-conversation.py` - Python导出脚本（可执行）
✅ `references/example.md` - 使用示例和输出样例
✅ `README.md` - 中文使用说明
✅ `DEPLOYMENT.md` - 本部署指南

---

## 验证结果

### Python脚本测试

```bash
✅ Reading conversation from: ~/.claude/projects/.../f0eb6929-aad2-45f5-aaf9-898e1be823b7.jsonl
✅ Found 632 messages
✅ Generating markdown in minimal mode...
✅ Exported to: /tmp/conversation-test.md
✅ 632 messages exported
```

### 导出内容验证

✅ 用户消息正确提取
✅ 助手回复正确提取
✅ 时间戳格式正确
✅ Markdown格式正确
✅ 中文显示正常
✅ 空消息已过滤
✅ Emoji标识清晰

---

## 在Claude Code中使用

### 基础用法

```
Export this conversation to markdown
```

**结果**: 创建 `conversation-export_20260123.md`

### 指定文件名

```
Export this conversation to my-doc.md
```

**结果**: 创建 `my-doc.md`

### 选择模式

```
Export this conversation in standard mode to technical-doc.md
```

**结果**: 创建 `technical-doc.md`（包含工具调用）

### Detailed模式

```
Export this conversation in detailed mode to complete-record.md
```

**结果**: 创建 `complete-record.md`（包含所有细节）

---

## 三种模式对比

| 特性 | Minimal | Standard | Detailed |
|------|---------|----------|----------|
| 用户消息 | ✅ | ✅ | ✅ |
| 助手回复 | ✅ | ✅ | ✅ |
| 时间戳 | ✅ | ✅ | ✅ |
| 工具调用 | ❌ | ✅ | ✅ |
| 工具输出 | ❌ | ❌ | ✅ |
| 代码diffs | ❌ | ❌ | ✅ |
| 适用场景 | 快速参考 | 技术文档 | 完整记录 |

---

## 下一步

### 1. 在Claude Code中测试

尝试上述命令，验证skill可以正常工作

### 2. 测试不同模式

对比三种模式的输出，确认符合预期

### 3. 提交到Git（可选）

```bash
cd /Users/xiaoyuliu/Documents/github/ai-developer-skills
git add general/conversation-exporter/
git commit -m "Add conversation-exporter skill

- Export Claude Code conversations to markdown
- Three modes: minimal, standard, detailed
- Filter out noise messages
- Include timestamps and metadata
- Python script for direct usage"
git push
```

---

## 故障排查

### Skill未被识别

**症状**: Claude Code说找不到skill

**解决**:
1. 确认SKILL.md文件存在
2. 检查YAML frontmatter格式
3. 尝试重启Claude Code

### 导出为空

**症状**: 导出的markdown文件没有内容

**解决**:
1. 检查.jsonl文件路径
2. 使用Python脚本直接测试
3. 查看错误消息

### 格式问题

**症状**: 导出的内容格式不对

**解决**:
1. 确认使用最新版本脚本
2. 检查Python版本（需要Python 3.6+）
3. 查看完整错误输出

---

## 成功标志

✅ Python脚本可以独立运行
✅ 导出的markdown格式正确
✅ 包含预期的消息数量
✅ 时间戳和中文显示正常
✅ 三种模式输出不同
✅ 可以在Claude Code中调用

---

**准备好测试了！** 🚀

开始在你的Claude Code中使用这个skill吧！
