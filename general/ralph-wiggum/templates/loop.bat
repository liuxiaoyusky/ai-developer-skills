@echo off
setlocal enabledelayedexpansion
REM Ralph Wiggum Loop - 简洁版
REM 原始理念：5行代码实现强大功能

set ITERATION=0

:loop
set /a ITERATION+=1

REM 计算任务进度（使用 PowerShell）
for /f "tokens=*" %%a in ('powershell -Command "$total = (Select-String -Path AGENTS.md -Pattern '^\- \[.\]' -AllMatches).Matches.Count; $done = (Select-String -Path AGENTS.md -Pattern '^\- \[x\]' -AllMatches).Matches.Count; Write-Output \"$done/$total\""') do set PROGRESS=%%a

echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo 🔄 迭代 #!ITERATION! | 进度: !PROGRESS! 任务已完成
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REM 运行 Claude
type PROMPT_build.md | claude -p --dangerously-skip-permissions --verbose

REM 检查是否所有任务完成
REM 使用 PowerShell 检查是否还有未完成的任务
powershell -Command "if (-not (Select-String -Path AGENTS.md -Pattern '\- \[ \]' -Quiet)) { exit 0 } else { exit 1 }"
if !errorlevel! equ 0 (
    echo ✅ 所有任务已完成！
    goto :eof
)

REM 推送更改（可选）
for /f "tokens=*" %%i in ('git branch --show-current 2^>nul') do set CURRENT_BRANCH=%%i
if defined CURRENT_BRANCH (
    git push origin !CURRENT_BRANCH! 2>nul
)

goto loop
