# Ralph Loop - Windows 示例脚本
# 使用方法：
# 1. 复制到你的项目目录: copy loop.sample.ps1 loop.ps1
# 2. 确保 tasks.md 文件存在
# 3. 运行: .\loop.ps1

# 颜色输出函数
function Write-Green {
    param([string]$Text)
    Write-Host $Text -ForegroundColor Green
}

function Write-Yellow {
    param([string]$Text)
    Write-Host $Text -ForegroundColor Yellow
}

Write-Green "╔════════════════════════════════════════════════════════╗"
Write-Green "║     Ralph Loop - 自动迭代调度器                          ║"
Write-Green "╚════════════════════════════════════════════════════════╝"
Write-Host ""

# 检查 tasks.md 是否存在
if (-not (Test-Path "tasks.md")) {
    Write-Yellow "错误：tasks.md 不存在"
    Write-Host "请先创建 tasks.md 并添加任务"
    exit 1
}

# 统计任务
$tasksContent = Get-Content "tasks.md" -Raw
$TODO_COUNT = ([regex]::Matches($tasksContent, "^\- \[ \]")).Count
$DONE_COUNT = ([regex]::Matches($tasksContent, "^\- \[x\]")).Count

Write-Yellow "当前状态："
Write-Host "  待处理：$TODO_COUNT 个"
Write-Host "  已完成：$DONE_COUNT 个"
Write-Host ""

if ($TODO_COUNT -eq 0) {
    Write-Green "🎉 所有任务已完成！"
    exit 0
}

# 迭代循环
$ITERATION = 0
while (Select-String -Path tasks.md -Pattern '^\- \[ \]' -Quiet) {
    $ITERATION++

    Write-Green "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Green "迭代 #$ITERATION 开始"
    Write-Green "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host ""

    # 记录开始时间
    $START_TIME = Get-Date

    # 调用 Claude CLI 执行 dev-flow
    # 每次调用 = 1 次 dev-flow 执行（5 步闭环）
    claude "使用 dev-flow 技能处理下一个任务"

    # 记录结束时间
    $END_TIME = Get-Date
    $DURATION = $END_TIME - $START_TIME

    Write-Host ""
    Write-Green "✓ 迭代 #$ITERATION 完成"
    Write-Host "  耗时：$($DURATION.Minutes)分$($DURATION.Seconds)秒"
    Write-Host ""

    # 更新统计
    $tasksContent = Get-Content "tasks.md" -Raw
    $TODO_COUNT = ([regex]::Matches($tasksContent, "^\- \[ \]")).Count
    $DONE_COUNT = ([regex]::Matches($tasksContent, "^\- \[x\]")).Count

    Write-Yellow "当前进度："
    Write-Host "  待处理：$TODO_COUNT 个"
    Write-Host "  已完成：$DONE_COUNT 个"
    Write-Host ""

    # 检查是否还有待处理任务
    if ($TODO_COUNT -eq 0) {
        Write-Green "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        Write-Green "🎉 所有任务已完成！"
        Write-Green "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        break
    }

    # 短暂暂停（可选）
    Write-Yellow "等待 2 秒后继续..."
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Green "✨ 总共完成 $ITERATION 次迭代"
Write-Green "查看详细日志：cat dev-flow.log"
