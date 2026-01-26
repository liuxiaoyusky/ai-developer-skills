#!/bin/bash
# Ralph Wiggum Loop - 极简版
# 所有检查由前置 skills 处理，loop 只负责执行和提交

ITERATION=0
while true; do
    ITERATION=$((ITERATION + 1))

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔄 迭代 #$ITERATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # 运行 Claude（skills 会处理所有检查和决策）
    CLAude_OUTPUT=$(cat PROMPT_build.md | claude -p --dangerously-skip-permissions --verbose 2>&1)

    # 提交进度
    git add -A
    git commit -m "iteration $ITERATION" 2>/dev/null || echo "No changes to commit"
    git push origin $(git branch --show-current) 2>/dev/null || true

    # 检查 skills 输出的完成标记
    if echo "$CLAude_OUTPUT" | grep -q "RALPH_COMPLETE"; then
        echo "✅ 所有任务已完成！"
        break
    fi

    # 短暂延迟，避免快速循环
    sleep 1
done
