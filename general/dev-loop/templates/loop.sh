#!/bin/bash
# Dev Loop - 自动迭代调度器（跨平台 bash 版本）
#
# 版本：2025-02-04
#
# 说明：
# - 这是 dev-loop skill 的 asset 文件
# - dev-loop 激活时会将此文件复制到用户项目目录
# - 这是 loop.sh 的唯一源码文件
#
# 使用方法：
# 1. 确保 tasks.md 文件存在
# 2. 运行: chmod +x loop.sh && ./loop.sh [--max N]
#
# 参数说明：
#   --max N         设置最大迭代次数（默认：无限循环）
#
# 完成检测：
#   当 dev-flow 检测到 tasks.md 中无待处理任务时，
#   会输出 <promise>COMPLETE</promise> 信号，loop.sh 检测到后自动退出

set -e  # 遇到错误退出（但在 AI 调用处使用 || true 覆盖）

# ============================================
# 命令行参数解析
# ============================================

MAX_ITERATIONS=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAUTION_FILE="$SCRIPT_DIR/caution.md"
TASKS_FILE="$SCRIPT_DIR/tasks.md"
PROMPT_FILE="$SCRIPT_DIR/CLAUDE.md"

# 解析参数
while [[ $# -gt 0 ]]; do
  case $1 in
    --max)
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    *)
      echo "❌ 未知参数: $1"
      echo "用法: $0 [--max N]"
      exit 1
      ;;
  esac
done

# ============================================
# ANSI 颜色代码
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# 彩色输出函数
log_red() {
  echo -e "${RED}$1${RESET}"
}

log_green() {
  echo -e "${GREEN}$1${RESET}"
}

log_yellow() {
  echo -e "${YELLOW}$1${RESET}"
}

log_cyan() {
  echo -e "${CYAN}$1${RESET}"
}

# ============================================
# 任务统计
# ============================================

count_tasks() {
  if [ ! -f "$TASKS_FILE" ]; then
    echo "0 0"
    return
  fi

  local todo_count=$(grep -c "^- \[ \]" "$TASKS_FILE" 2>/dev/null || echo "0")
  local done_count=$(grep -c "^- \[x\]" "$TASKS_FILE" 2>/dev/null || echo "0")

  echo "$todo_count $done_count"
}

# ============================================
# 启动检查
# ============================================

# ⚠️ 强制检查 caution.md
if [ ! -f "$CAUTION_FILE" ]; then
  log_red "╔════════════════════════════════════════════════════════╗"
  log_red "║  ⚠️  警告：caution.md 不存在                           ║"
  log_red "╚════════════════════════════════════════════════════════╝"
  echo ""
  log_red "正在创建默认 caution.md 模板..."
  echo ""

  cat > "$CAUTION_FILE" << 'EOF'
# ⚠️ 开发注意事项

## 强制规则

在此文件中添加开发过程中必须遵守的规则。这些规则将在每次 dev-flow 启动时显示。

## 示例规则

- 禁止未测试就标记任务完成
- 禁止直接修改核心配置文件
- 禁止提交包含 console.log 的代码
- 所有 API 变更必须更新文档

---
请根据项目需求修改上述内容。
EOF

  log_green "✅ 已创建 caution.md"
  echo ""
  log_yellow "⚠️  请根据项目需求编辑此文件，添加必须遵守的规则。"
  echo ""
fi

# 读取并显示 caution.md
log_red "╔════════════════════════════════════════════════════════╗"
log_red "║  ⚠️  注意事项 (caution.md)                              ║"
log_red "╚════════════════════════════════════════════════════════╝"
echo ""
cat "$CAUTION_FILE"
echo ""
log_red "⚠️  以上规则必须严格遵守！"
echo ""

log_green "╔════════════════════════════════════════════════════════╗"
log_green "║     Dev Loop - 自动迭代调度器                           ║"
log_green "╚════════════════════════════════════════════════════════╝"
echo ""

if [ -n "$MAX_ITERATIONS" ]; then
  log_cyan "最大迭代次数: $MAX_ITERATIONS"
else
  log_cyan "模式: 无限循环（直到检测到完成信号）"
fi
echo ""

# 检查 tasks.md 是否存在
if [ ! -f "$TASKS_FILE" ]; then
  log_yellow "⚠️  警告：tasks.md 不存在"
  echo "   将继续运行，但无法统计任务进度"
  echo ""
fi

# 初始统计
TASK_STATS=$(count_tasks)
todo_count=$(echo "$TASK_STATS" | awk '{print $1}')
done_count=$(echo "$TASK_STATS" | awk '{print $2}')

if [ -f "$TASKS_FILE" ]; then
  log_yellow "📊 当前状态："
  echo "   待处理：$todo_count 个"
  echo "   已完成：$done_count 个"
  echo ""

  if [ "$todo_count" -eq 0 ]; then
    log_green "🎉 所有任务已完成！"
    exit 0
  fi
fi

# ============================================
# 主循环
# ============================================

iteration=0

while true; do
  iteration=$((iteration + 1))

  # 检查是否超过最大迭代次数
  if [ -n "$MAX_ITERATIONS" ] && [ $iteration -gt $MAX_ITERATIONS ]; then
    echo ""
    log_yellow "⚠️  Dev Loop 已达到最大迭代次数 ($MAX_ITERATIONS) 但未完成所有任务"
    exit 1
  fi

  echo ""
  log_green "==============================================================="
  if [ -n "$MAX_ITERATIONS" ]; then
    log_green "  迭代 $iteration / $MAX_ITERATIONS"
  else
    log_green "  迭代 #$iteration"
  fi
  log_green "==============================================================="
  echo ""

  # 记录开始时间
  start_time=$(date +%s)

  # ⭐ 关键：使用 bash 实现实时输出 + 捕获（类似 Ralph 的实现）
  # 2>&1 | tee /dev/stderr：同时实现实时显示和捕获
  # || true：无论命令成功失败都继续
  if [ -f "$PROMPT_FILE" ]; then
    # 优先使用 CLAUDE.md 文件
    OUTPUT=$(claude --dangerously-skip-permissions --print < "$PROMPT_FILE" 2>&1 | tee /dev/stderr) || true
  else
    # 备用：直接调用 dev-flow 技能
    OUTPUT=$(claude --dangerously-skip-permissions --print "使用 dev-flow 技能处理下一个任务" 2>&1 | tee /dev/stderr) || true
  fi

  # 记录结束时间
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  minutes=$((duration / 60))
  seconds=$((duration % 60))

  echo ""
  log_green "✓ 迭代 #$iteration 完成"
  echo "  耗时：${minutes}分${seconds}秒"
  echo ""

  # 检查完成信号（dev-flow 主动报告完成）
  if echo "$OUTPUT" | grep -q "COMPLETE"; then
    echo ""
    log_green "==============================================================="
    log_green "🎉 Dev Loop 已完成所有任务！"
    log_green "  在第 $iteration 次迭代完成"
    log_green "==============================================================="
    exit 0
  fi

  # 更新统计
  CURRENT_STATS=$(count_tasks)
  current_todo=$(echo "$CURRENT_STATS" | awk '{print $1}')
  current_done=$(echo "$CURRENT_STATS" | awk '{print $2}')

  if [ -f "$TASKS_FILE" ]; then
    log_yellow "📊 当前进度："
    echo "   待处理：$current_todo 个"
    echo "   已完成：$current_done 个"
    echo ""
  fi

  echo "迭代 $iteration 完成。继续..."
  echo ""

  # 短暂暂停
  sleep 2
done

# 最终状态
echo ""
log_green "✨ 成功完成所有任务（共 $iteration 次迭代）"
exit 0
