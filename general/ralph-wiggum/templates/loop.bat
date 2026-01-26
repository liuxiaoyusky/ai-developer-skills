@echo off
setlocal enabledelayedexpansion
REM Ralph Wiggum Loop - 极简版
REM 所有检查由前置 skills 处理，loop 只负责执行和提交

set ITERATION=0

:loop
set /a ITERATION+=1

echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo 🔄 迭代 #!ITERATION!
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REM 运行 Claude（skills 会处理所有检查和决策）
for /f "delims=" %%a in ('type PROMPT_build.md ^| claude -p --dangerously-skip-permissions --verbose 2^>^&1') do set "OUTPUT=%%a"

REM 提交进度
git add -A
git commit -m "iteration !ITERATION!" 2>nul || echo No changes to commit
for /f "tokens=*" %%i in ('git branch --show-current 2^>nul') do set CURRENT_BRANCH=%%i
if defined CURRENT_BRANCH (
    git push origin !CURRENT_BRANCH! 2>nul
)

REM 检查 skills 输出的完成标记
echo !OUTPUT! | findstr "RALPH_COMPLETE" >nul
if !errorlevel! equ 0 (
    echo ✅ 所有任务已完成！
    goto :eof
)

REM 短暂延迟，避免快速循环
timeout /t 1 >nul
goto loop
