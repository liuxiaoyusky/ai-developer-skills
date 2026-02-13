#!/bin/bash
# Dev Loop v7.0 - Project Orchestrator（跨平台 bash 版本）
#
# 版本：2026-02-13
#
# 三阶段工作流：
#   Phase 1: tasks.md (产品设计) → task-details.md (技术设计)
#   Phase 2: 逐个子任务执行 (subagent 调度 + version control)
#   Phase 3: 收尾 (进度更新)
#
# Version Control:
#   - 每个子任务前创建 git checkpoint
#   - 成功 → git commit (conventional commits)
#   - 失败 → git rollback → 重试一次 → 再失败则跳过
#
# 使用方法：
#   chmod +x loop.sh && ./loop.sh [--max N]

set -e

# ============================================
# 配置
# ============================================

MAX_ITERATIONS=""
MAX_ROLLBACK_RETRIES=1  # 每个子任务最多 rollback 重试次数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAUTION_FILE="$SCRIPT_DIR/caution.md"
TASKS_FILE="$SCRIPT_DIR/tasks.md"
TASK_DETAILS_FILE="$SCRIPT_DIR/task-details.md"
TASK_RESULT_FILE="$SCRIPT_DIR/task-result.md"
DEBUG_LOG_FILE="$SCRIPT_DIR/debug-log.md"

# ============================================
# 命令行参数解析
# ============================================

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
# ANSI 颜色
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

log_red()     { echo -e "${RED}$1${RESET}"; }
log_green()   { echo -e "${GREEN}$1${RESET}"; }
log_yellow()  { echo -e "${YELLOW}$1${RESET}"; }
log_cyan()    { echo -e "${CYAN}$1${RESET}"; }
log_magenta() { echo -e "${MAGENTA}$1${RESET}"; }

# ============================================
# 辅助函数
# ============================================

# 从 task-details.md 中提取子任务数量
count_subtasks() {
  if [ ! -f "$TASK_DETAILS_FILE" ]; then
    echo "0"
    return
  fi
  grep -c "^### Task [0-9]" "$TASK_DETAILS_FILE" 2>/dev/null || echo "0"
}

# 从 task-details.md 中提取指定子任务的状态
get_task_status() {
  local task_num=$1
  if [ ! -f "$TASK_DETAILS_FILE" ]; then
    echo "unknown"
    return
  fi
  # 查找 "### Task N:" 后面的状态行
  local status
  status=$(awk "/^### Task ${task_num}:/{found=1} found && /\*\*状态\*\*:/{print; exit}" "$TASK_DETAILS_FILE" \
    | sed 's/.*\*\*状态\*\*: *//' | tr -d '[:space:]')
  echo "${status:-pending}"
}

# 从 task-result.md 中提取执行状态
get_result_status() {
  if [ ! -f "$TASK_RESULT_FILE" ]; then
    echo "UNKNOWN"
    return
  fi
  local status
  status=$(grep "^## 状态:" "$TASK_RESULT_FILE" 2>/dev/null | head -1 | sed 's/## 状态: *//' | tr -d '[:space:]')
  echo "${status:-UNKNOWN}"
}

# 从 task-result.md 中提取建议的 commit message
get_commit_message() {
  if [ ! -f "$TASK_RESULT_FILE" ]; then
    echo "feat: complete task"
    return
  fi
  local msg
  msg=$(awk '/^## 建议 Commit Message/{getline; if(NF>0) print; exit}' "$TASK_RESULT_FILE")
  echo "${msg:-feat: complete task}"
}

# 从 task-details.md 中提取子任务标题
get_task_title() {
  local task_num=$1
  if [ ! -f "$TASK_DETAILS_FILE" ]; then
    echo "task-${task_num}"
    return
  fi
  local title
  title=$(grep "^### Task ${task_num}:" "$TASK_DETAILS_FILE" 2>/dev/null | head -1 | sed "s/^### Task ${task_num}: *//")
  echo "${title:-task-${task_num}}"
}

# 更新 task-details.md 中指定子任务的状态
update_task_status() {
  local task_num=$1
  local new_status=$2
  if [ -f "$TASK_DETAILS_FILE" ]; then
    # 用 awk 精确替换对应 task 块中的状态
    awk -v tn="$task_num" -v ns="$new_status" '
      /^### Task / { current_task = $3; gsub(/:/, "", current_task) }
      current_task == tn && /\*\*状态\*\*:/ {
        sub(/\*\*状态\*\*: *[a-z_]+/, "**状态**: " ns)
      }
      { print }
    ' "$TASK_DETAILS_FILE" > "${TASK_DETAILS_FILE}.tmp" && mv "${TASK_DETAILS_FILE}.tmp" "$TASK_DETAILS_FILE"
  fi
}

# ============================================
# 启动检查
# ============================================

# 检查 git 是否初始化
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  log_red "❌ 错误：当前目录不是 git 仓库"
  log_red "   请先运行: git init && git add -A && git commit -m 'init'"
  exit 1
fi

# 检查 caution.md
if [ ! -f "$CAUTION_FILE" ]; then
  log_yellow "⚠️  caution.md 不存在，正在创建默认模板..."
  cat > "$CAUTION_FILE" << 'CAUTIONEOF'
# ⚠️ 开发注意事项

## 强制规则

在此文件中添加开发过程中必须遵守的规则。
这些规则将在每次 dev-flow subagent 启动时读取。

## 示例规则

- 禁止未测试就标记任务完成
- 禁止直接修改核心配置文件
- 禁止提交包含 console.log 的代码
- 所有 API 变更必须更新文档

---
请根据项目需求修改上述内容。
CAUTIONEOF
  log_green "✅ 已创建 caution.md"
fi

# 显示 caution.md
log_red "╔══════════════════════════════════════════════════════════╗"
log_red "║  ⚠️  注意事项 (caution.md)                               ║"
log_red "╚══════════════════════════════════════════════════════════╝"
echo ""
cat "$CAUTION_FILE"
echo ""

# 检查 tasks.md
if [ ! -f "$TASKS_FILE" ]; then
  log_red "❌ 错误：tasks.md 不存在"
  log_red "   请先创建 tasks.md（产品设计文档）"
  exit 1
fi

# 启动 banner
log_green "╔══════════════════════════════════════════════════════════╗"
log_green "║  Dev Loop v7.0 - Project Orchestrator                   ║"
log_green "║  Version Control + Subagent Dispatching                 ║"
log_green "╚══════════════════════════════════════════════════════════╝"
echo ""

if [ -n "$MAX_ITERATIONS" ]; then
  log_cyan "最大迭代次数: $MAX_ITERATIONS"
else
  log_cyan "模式: 持续迭代直到所有需求完成"
fi
echo ""

# ============================================
# Phase 1: 产品设计 → 技术设计
# ============================================

phase1_generate_task_details() {
  log_magenta "═══════════════════════════════════════════════════════════"
  log_magenta "  Phase 1: 产品设计 → 技术设计"
  log_magenta "═══════════════════════════════════════════════════════════"
  echo ""

  log_cyan "📄 读取 tasks.md，生成 task-details.md..."
  echo ""

  # 调度 subagent 生成 task-details.md
  local PROMPT="你是 dev-loop 的技术设计生成器。

你的任务：
1. 读取 tasks.md（产品设计文档）
2. 识别下一个未完成的需求（进度追踪中 - [ ] 的项，或正文中未处理的需求）
3. 为该需求生成 task-details.md（技术设计文档）

要求：
- 分析需求，拆解为 3-7 个可执行子任务
- 每个子任务必须包含：状态(pending)、描述、涉及文件、验收标准、测试策略、预计复杂度
- 子任务之间标注依赖关系
- 记录关键技术决策

格式参考（严格遵循）：

# Technical Design: [需求名称]

## 来源
- 需求: tasks.md > [需求标题]
- 生成时间: $(date '+%Y-%m-%d %H:%M')

## 子任务列表

### Task 1: [标题]
- **状态**: pending
- **描述**: [...]
- **涉及文件**: [...]
- **验收标准**: [...]
- **测试策略**: [...]
- **预计复杂度**: [low|medium|high]

（继续 Task 2, 3...）

## 依赖关系
[...]

## 技术决策记录
[...]

如果 tasks.md 中所有需求都已完成，输出: <promise>COMPLETE</promise>

现在开始，读取 tasks.md 并生成 task-details.md。"

  OUTPUT=$(claude --dangerously-skip-permissions --print "$PROMPT" 2>&1 | tee /dev/stderr) || true

  # 检查完成信号
  if echo "$OUTPUT" | grep -q "COMPLETE"; then
    log_green "🎉 所有需求已完成！"
    return 1  # 信号：全部完成
  fi

  # 验证 task-details.md 已生成
  if [ ! -f "$TASK_DETAILS_FILE" ]; then
    log_red "❌ task-details.md 未生成"
    return 2  # 信号：生成失败
  fi

  local total
  total=$(count_subtasks)
  log_green "✅ task-details.md 已生成，包含 $total 个子任务"
  echo ""
  return 0
}

# ============================================
# Phase 2: 逐个执行子任务
# ============================================

phase2_execute_tasks() {
  log_magenta "═══════════════════════════════════════════════════════════"
  log_magenta "  Phase 2: 逐个执行子任务 (Subagent + Version Control)"
  log_magenta "═══════════════════════════════════════════════════════════"
  echo ""

  local total
  total=$(count_subtasks)
  local completed=0
  local failed=0

  for task_num in $(seq 1 "$total"); do
    local task_title
    task_title=$(get_task_title "$task_num")
    local task_status
    task_status=$(get_task_status "$task_num")

    # 跳过已完成或已失败的任务
    if [ "$task_status" = "completed" ] || [ "$task_status" = "failed" ]; then
      if [ "$task_status" = "completed" ]; then
        completed=$((completed + 1))
      else
        failed=$((failed + 1))
      fi
      log_cyan "  ⏭️  跳过 Task $task_num: $task_title (状态: $task_status)"
      continue
    fi

    echo ""
    log_green "───────────────────────────────────────────────────────────"
    log_green "  Task $task_num/$total: $task_title"
    log_green "───────────────────────────────────────────────────────────"
    echo ""

    # 执行子任务（带 rollback 重试）
    execute_single_task "$task_num" "$task_title"
    local result=$?

    if [ $result -eq 0 ]; then
      completed=$((completed + 1))
      log_green "  ✅ Task $task_num 完成"
    else
      failed=$((failed + 1))
      log_red "  ❌ Task $task_num 失败，已跳过"
    fi
  done

  echo ""
  log_cyan "📊 Phase 2 结果: $completed 完成, $failed 失败, $total 总计"
  echo ""
}

# 执行单个子任务（包含 checkpoint/commit/rollback 逻辑）
execute_single_task() {
  local task_num=$1
  local task_title=$2
  local rollback_count=0

  while true; do
    # ── Step 1: CHECKPOINT ──
    log_yellow "  [CHECKPOINT] 创建 git 检查点..."
    git add -A 2>/dev/null || true
    git commit -m "checkpoint: before task-${task_num} ${task_title}" --allow-empty -q 2>/dev/null || true

    # ── Step 2: PREPARE ──
    > "$TASK_RESULT_FILE"  # 清空 task-result.md
    # debug-log.md 不清空（保留错误记忆）

    # 更新状态为 in_progress
    update_task_status "$task_num" "in_progress"

    # ── Step 3: DISPATCH subagent ──
    log_cyan "  [DISPATCH] 调度 dev-flow subagent..."
    echo ""

    local RETRY_CONTEXT=""
    if [ $rollback_count -gt 0 ] && [ -f "$DEBUG_LOG_FILE" ]; then
      RETRY_CONTEXT="

重要：这是第 $((rollback_count + 1)) 次尝试。
之前的尝试已失败并回退。请阅读 debug-log.md 了解之前的失败原因，
务必采用不同的实现方案，避免重蹈覆辙。"
    fi

    local PROMPT="你是 dev-flow task executor（子任务执行器）。

你的职责：执行 task-details.md 中的 Task ${task_num}，完成 实现→测试→debug 闭环。

步骤：
1. 读取 task-details.md 中 Task ${task_num} 的详细信息
2. 读取 caution.md（如果存在，遵守项目约束）
3. 读取 debug-log.md（如果存在，了解之前的失败，避免相同方案）
4. 实现子任务
5. 运行测试验证（使用 dev-verify 技能或直接执行测试命令）
6. 如果测试失败：调试修复（最多 3 次，记录到 debug-log.md）
7. 写入 task-result.md（严格遵循以下格式）

task-result.md 格式（必须严格遵循）：

# Task Result

## 状态: [SUCCESS 或 ROLLBACK]

## 任务: [子任务标题]

## 时间: $(date '+%Y-%m-%d %H:%M')

---

## 变更摘要

- [修改/新增] [文件路径]: [做了什么]

## 建议 Commit Message

[type]([scope]): [description]

## 测试结果

- [测试类型]: [结果]

---

如果 debug 3 次仍无法解决，状态写 ROLLBACK，并在末尾添加：

## 失败原因
[汇总]

## 建议方向
[下次应尝试的不同方案]
${RETRY_CONTEXT}

现在开始执行 Task ${task_num}。"

    OUTPUT=$(claude --dangerously-skip-permissions --print "$PROMPT" 2>&1 | tee /dev/stderr) || true

    # ── Step 4: READ result ──
    local status
    status=$(get_result_status)
    log_cyan "  [RESULT] 状态: $status"

    # ── Step 5: BRANCH ──
    if [ "$status" = "SUCCESS" ]; then
      # 成功：commit
      local commit_msg
      commit_msg=$(get_commit_message)
      log_green "  [COMMIT] $commit_msg"
      git add -A 2>/dev/null || true
      git commit -m "$commit_msg" -q 2>/dev/null || true
      update_task_status "$task_num" "completed"
      # 清理通信文件
      rm -f "$TASK_RESULT_FILE" "$DEBUG_LOG_FILE" 2>/dev/null || true
      return 0

    elif [ "$status" = "ROLLBACK" ]; then
      rollback_count=$((rollback_count + 1))
      log_yellow "  [ROLLBACK] 第 $rollback_count 次回退"

      if [ $rollback_count -gt $MAX_ROLLBACK_RETRIES ]; then
        # 超过重试次数，标记失败并跳过
        log_red "  [FAILED] 已达最大回退重试次数 ($MAX_ROLLBACK_RETRIES)，跳过此任务"
        git reset --hard HEAD~1 -q 2>/dev/null || true
        update_task_status "$task_num" "failed"
        rm -f "$TASK_RESULT_FILE" "$DEBUG_LOG_FILE" 2>/dev/null || true
        return 1
      fi

      # 保存 debug-log（错误记忆）
      if [ -f "$DEBUG_LOG_FILE" ]; then
        cp "$DEBUG_LOG_FILE" "/tmp/debug-log-task-${task_num}.md" 2>/dev/null || true
      fi

      # 回退到 checkpoint
      log_yellow "  [ROLLBACK] git reset --hard HEAD~1"
      git reset --hard HEAD~1 -q 2>/dev/null || true

      # 恢复 debug-log（错误记忆）
      if [ -f "/tmp/debug-log-task-${task_num}.md" ]; then
        cp "/tmp/debug-log-task-${task_num}.md" "$DEBUG_LOG_FILE" 2>/dev/null || true
      fi

      log_yellow "  [RETRY] 重新调度 subagent（带避坑上下文）..."
      # 继续循环，重新 dispatch

    else
      # 未知状态（subagent 可能没有正确写入 task-result.md）
      log_red "  [ERROR] task-result.md 状态未知: $status"
      log_red "  [ERROR] 可能 subagent 未正确写入结果"
      # 当作失败处理
      git reset --hard HEAD~1 -q 2>/dev/null || true
      update_task_status "$task_num" "failed"
      rm -f "$TASK_RESULT_FILE" "$DEBUG_LOG_FILE" 2>/dev/null || true
      return 1
    fi
  done
}

# ============================================
# Phase 3: 收尾
# ============================================

phase3_finalize() {
  log_magenta "═══════════════════════════════════════════════════════════"
  log_magenta "  Phase 3: 收尾"
  log_magenta "═══════════════════════════════════════════════════════════"
  echo ""

  # 更新 tasks.md 进度追踪（由 subagent 完成）
  log_cyan "📝 更新 tasks.md 进度..."

  local PROMPT="读取 task-details.md 的完成情况。
如果所有子任务都已 completed，在 tasks.md 的进度追踪中将对应需求标记为 [x]。
如果有子任务 failed，在 tasks.md 中对应需求后添加注释说明。
不要修改 tasks.md 的其他内容。"

  claude --dangerously-skip-permissions --print "$PROMPT" 2>&1 | tee /dev/stderr || true

  echo ""
  log_green "✅ Phase 3 完成"
}

# ============================================
# 主循环
# ============================================

iteration=0

while true; do
  iteration=$((iteration + 1))

  # 检查最大迭代次数
  if [ -n "$MAX_ITERATIONS" ] && [ $iteration -gt "$MAX_ITERATIONS" ]; then
    log_yellow "⚠️  已达最大迭代次数 ($MAX_ITERATIONS)"
    exit 1
  fi

  echo ""
  log_green "╔══════════════════════════════════════════════════════════╗"
  if [ -n "$MAX_ITERATIONS" ]; then
    log_green "║  迭代 $iteration / $MAX_ITERATIONS"
  else
    log_green "║  迭代 #$iteration"
  fi
  log_green "╚══════════════════════════════════════════════════════════╝"
  echo ""

  start_time=$(date +%s)

  # Phase 1: 生成 task-details.md
  phase1_generate_task_details
  phase1_result=$?

  if [ $phase1_result -eq 1 ]; then
    # 全部完成
    echo ""
    log_green "╔══════════════════════════════════════════════════════════╗"
    log_green "║  🎉 所有需求已完成！                                     ║"
    log_green "║  共 $iteration 次迭代                                    ║"
    log_green "╚══════════════════════════════════════════════════════════╝"
    exit 0
  fi

  if [ $phase1_result -eq 2 ]; then
    log_red "❌ Phase 1 失败：task-details.md 未能生成"
    log_yellow "等待 5 秒后重试..."
    sleep 5
    continue
  fi

  # Phase 2: 逐个执行子任务
  phase2_execute_tasks

  # Phase 3: 收尾
  phase3_finalize

  # 统计
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  minutes=$((duration / 60))
  seconds=$((duration % 60))

  echo ""
  log_green "✓ 迭代 #$iteration 完成 (耗时: ${minutes}分${seconds}秒)"
  echo ""

  # 短暂暂停
  sleep 2
done
