# Ralph Wiggum - AGENTS.md Template

**使用说明**：复制到项目根目录，重命名为 `AGENTS.md`，根据项目填写内容。

**保持简洁**（~60 行）：只包含必要信息，状态更新记录在 Git commit 中。

---

## Build & Run

```bash
# 构建：npm run build | cargo build | python setup.py build
# 运行：npm start | cargo run | python main.py
```

---

## Validation

```bash
# Tests: npm test | cargo test | pytest
# Typecheck: npm run typecheck | cargo clippy | mypy
# Lint: npm run lint | eslint | flake8
```

这些是必需的 backpressure - Ralph 必须运行并在失败时修复。

---

## Tasks

- [ ] Task 1: [描述] - 验收：[标准]
- [ ] Task 2: [描述] - 验收：[标准]
- [ ] Task 3: [描述] - 验收：[标准]

格式：`- [ ]` 未完成，`- [x]` 已完成。全部 `- [x]` 时循环停止。

---

## Operational Notes

```bash
# 环境变量、依赖安装、数据库迁移等
export DATABASE_URL="..."
npm install
npm run migrate
```

**代码模式**：`src/lib/` 是共享库。优先使用 consolidated implementations。

---

## Debug Skills

- `/debug-error` - 通用错误分析
- `/debug-tests` - 测试失败诊断
- `/debug-performance` - 性能问题
- `/debug-build` - 构建失败

使用：`/debug "<错误详情>"`

---

**保持简洁** - 每次循环都加载此文件到上下文。定期清理已完成任务。
