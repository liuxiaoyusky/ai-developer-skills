#!/bin/bash
# Ralph Loop + Dev Flow 自动迭代脚本
#
# ⚠️  安全提示：
#   此脚本使用 --dangerously-skip-permissions 参数运行，将跳过所有权限确认。
#   在运行前，请务必：
#   1. 仔细审查 tasks.md 中的所有任务
#   2. 确认任务范围在可接受的风险内
#   3. 如有疑问，先手动执行 dev-flow 测试
#
# 使用方法：
#   1. 确保 tasks.md 存在并包含任务
#   2. 确保 dev-flow 技能已安装
#   3. 运行：bash loop.sh
#
# 架构说明：
#   每次 CLI 调用 = 1 次 dev-flow 执行（5 步闭环）
#   - 任务识别 → 拆解 → 执行 → 测试 → 调试
#   - 成功：任务移到 DONE
#   - 失败：保持在 TODO，下次继续

set -e  # 遇到错误退出

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Ralph Loop + Dev Flow 自动迭代系统                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# 检查 tasks.md 是否存在
if [ ! -f "tasks.md" ]; then
    echo -e "${RED}错误：tasks.md 不存在${NC}"
    echo "请先创建 tasks.md 并添加任务"
    exit 1
fi

# 统计任务
TODO_COUNT=$(grep -c "^\- \[ \]" tasks.md || true)
DONE_COUNT=$(grep -c "^\- \[x\]" tasks.md || true)

echo -e "${YELLOW}当前状态：${NC}"
echo "  待处理：$TODO_COUNT 个"
echo "  已完成：$DONE_COUNT 个"
echo ""

if [ "$TODO_COUNT" -eq 0 ]; then
    echo -e "${GREEN}🎉 所有任务已完成！${NC}"
    exit 0
fi

# 迭代循环
ITERATION=0
while cat tasks.md | grep -q "^\- \[ \]"; do
    ITERATION=$((ITERATION + 1))

    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}迭代 #$ITERATION 开始${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # 记录开始时间
    START_TIME=$(date +%s)

    # 调用 Claude CLI 执行 dev-flow
    # 每次调用 = 1 次 dev-flow 执行（5 步闭环）
    claude --dangerously-skip-permissions "使用 dev-flow 技能处理下一个任务"

    # 记录结束时间
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))

    echo ""
    echo -e "${GREEN}✓ 迭代 #$ITERATION 完成${NC}"
    echo "  耗时：${MINUTES}分${SECONDS}秒"
    echo ""

    # 更新统计
    TODO_COUNT=$(grep -c "^\- \[ \]" tasks.md || true)
    DONE_COUNT=$(grep -c "^\- \[x\]" tasks.md || true)

    echo -e "${YELLOW}当前进度：${NC}"
    echo "  待处理：$TODO_COUNT 个"
    echo "  已完成：$DONE_COUNT 个"
    echo ""

    # 检查是否还有待处理任务
    if [ "$TODO_COUNT" -eq 0 ]; then
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}🎉 所有任务已完成！${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        break
    fi

    # 短暂暂停（可选）
    echo -e "${YELLOW}等待 2 秒后继续...${NC}"
    sleep 2
done

echo ""
echo -e "${GREEN}✨ 总共完成 $ITERATION 次迭代${NC}"
echo -e "${GREEN}查看详细日志：cat dev-flow.log${NC}"
