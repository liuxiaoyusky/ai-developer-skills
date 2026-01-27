#!/bin/bash
# Ralph Loop - macOS/Linux 示例脚本
# 使用方法：
# 1. 复制到你的项目目录: cp loop.sample.sh loop.sh
# 2. 确保 TASKS.md 文件存在
# 3. 运行: chmod +x loop.sh && ./loop.sh

iteration=0
while true; do
  iteration=$((iteration + 1))
  echo ""
  echo "=== Iteration $iteration ==="
  echo ""

  if ! grep -q '\[ \]' TASKS.md 2>/dev/null; then
    echo "✅ All tasks complete!"
    break
  fi

  claude -p "Implement the next incomplete task in TASKS.md. Update the checkbox to [x] when done."
done
