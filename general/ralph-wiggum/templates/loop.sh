#!/bin/bash
# Ralph Wiggum Loop - 简洁版
# 原始理念：5行代码实现强大功能

ITERATION=0
while true; do
    ITERATION=$((ITERATION + 1))

    # 计算任务进度
    TOTAL=$(grep -c '^\- \[.\]' AGENTS.md 2>/dev/null || echo 0)
    DONE=$(grep -c '^\- \[x\]' AGENTS.md 2>/dev/null || echo 0)

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔄 迭代 #$ITERATION | 进度: $DONE/$TOTAL 任务已完成"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # 运行 Claude
    cat PROMPT_build.md | claude -p --dangerously-skip-permissions --verbose

    # 检查是否所有任务完成
    if ! grep -q '\- \[ \]' AGENTS.md 2>/dev/null; then
        echo "✅ 所有任务已完成！"
        break
    fi

    # 推送更改（可选）
    git push origin $(git branch --show-current) 2>/dev/null || true
done
