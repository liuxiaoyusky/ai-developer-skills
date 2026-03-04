@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo    AI Developer Skills 一键安装工具
echo    v3.0.0 - 含 Submodule 技能
echo ========================================
echo.

REM 检查是否在正确的目录
if not exist "skills-manifest.json" (
    echo 错误: 未找到 skills-manifest.json
    echo 请确保此脚本在 ai-developer-skills 仓库根目录下运行
    pause
    exit /b 1
)

REM 初始化 git submodules
echo 初始化 Git Submodules...
git submodule update --init --recursive
echo Submodules 就绪
echo.

REM 检测目标安装路径
set "CLAUDE_SKILLS=%USERPROFILE%\.claude\skills"
set "CODEX_SKILLS=%USERPROFILE%\.codex\skills"

echo 检测到的安装路径:
echo   Claude Code: %CLAUDE_SKILLS%
echo   Codex: %CODEX_SKILLS%
echo.

REM 询问安装目标
echo 请选择安装目标:
echo   1. Claude Code (推荐)
echo   2. Codex
echo   3. 两者都安装
echo.
set /p choice="请输入选项 (1/2/3, 默认1): "

if "%choice%"=="" set choice=1

set "INSTALL_CLAUDE=0"
set "INSTALL_CODEX=0"

if "%choice%"=="1" set "INSTALL_CLAUDE=1"
if "%choice%"=="2" set "INSTALL_CODEX=1"
if "%choice%"=="3" (
    set "INSTALL_CLAUDE=1"
    set "INSTALL_CODEX=1"
)

echo.
echo ========================================
echo 开始安装技能...
echo ========================================
echo.

set "SKILLS_COUNT=0"

goto :main

:install_skill
set "skill_name=%~1"
set "skill_source=%~2"
set "target_dir=%~3"

echo 正在安装: !skill_name!

if not exist "!skill_source!\SKILL.md" (
    echo   跳过: 缺少 SKILL.md
    echo.
    goto :eof
)

if not exist "!target_dir!" mkdir "!target_dir!" 2>nul

if exist "!target_dir!\!skill_name!" rmdir /s /q "!target_dir!\!skill_name!" 2>nul

xcopy "!skill_source!" "!target_dir!\!skill_name!" /E /I /Y /Q >nul 2>&1
if errorlevel 1 (
    echo   错误: 复制失败
    echo.
    goto :eof
)

echo   已安装
echo.
set /a SKILLS_COUNT+=1
goto :eof

:install_collection
set "coll_name=%~1"
set "skills_dir=%~2"
set "target_dir=%~3"

echo --- 安装集合: !coll_name! ---
echo.

if not exist "!skills_dir!" (
    echo   跳过: 目录不存在
    echo.
    goto :eof
)

for /d %%S in ("!skills_dir!\*") do (
    if exist "%%S\SKILL.md" (
        set "sname=%%~nxS"
        call :install_skill "!sname!" "%%S" "!target_dir!"
    )
)
goto :eof

:install_all
set "target=%~1"

echo ======== 本地技能 ========
echo.
call :install_skill "business-email" ".\business_routing\business-email" "!target!"
call :install_skill "dev-loop" ".\general\dev-loop" "!target!"
call :install_skill "dev-flow" ".\general\dev-flow" "!target!"
call :install_skill "dev-debug" ".\general\dev-debug" "!target!"
call :install_skill "conversation-exporter" ".\general\conversation-exporter" "!target!"
call :install_skill "dev-verify" ".\general\dev-verify" "!target!"
call :install_skill "first-principles-planner" ".\general\first-principles-planner" "!target!"
call :install_skill "n8n-mcp-workflow" ".\general\n8n-mcp-workflow\skills\n8n-mcp-workflow" "!target!"
call :install_skill "first-principles" ".\general\first-principles" "!target!"
call :install_skill "dev-review" ".\general\dev-review" "!target!"
call :install_skill "skill-checker" ".\general\skill-checker\skills\skill-checker" "!target!"
call :install_skill "web-browser-skill" ".\web-browser-skill" "!target!"
call :install_skill "wechat-miniprogram" ".\wechat-miniprogram" "!target!"
call :install_skill "doc-auditor" ".\doc-auditor" "!target!"
call :install_skill "free-ai-chat-deployment" ".\free-ai-chat-deployment" "!target!"

echo ======== Submodule: masters-skills ========
echo.
call :install_skill "skill-from-masters" ".\masters_skills\skills\skill-from-masters" "!target!"
call :install_skill "skill-from-github" ".\masters_skills\skills\skills\skill-from-github" "!target!"
call :install_skill "search-skill" ".\masters_skills\skills\skills\search-skill" "!target!"
call :install_skill "skill-from-notebook" ".\masters_skills\skills\skills\skill-from-notebook" "!target!"

echo ======== Submodule: self-improving-agent ========
echo.
call :install_skill "self-improving-agent" ".\self-improving-agent" "!target!"

echo ======== Submodule: superpowers (14 skills) ========
echo.
call :install_collection "superpowers" ".\superpowers\skills" "!target!"

echo ======== Submodule: anthropic-skills (16 skills) ========
echo.
call :install_collection "anthropic-skills" ".\anthropic-skills\skills" "!target!"

goto :eof

:main

if "%INSTALL_CLAUDE%"=="1" (
    echo [Claude Code] 安装中...
    echo.
    call :install_all "%CLAUDE_SKILLS%"
    echo [Claude Code] 安装完成
    echo.
)

if "%INSTALL_CODEX%"=="1" (
    echo [Codex] 安装中...
    echo.
    call :install_all "%CODEX_SKILLS%"
    echo [Codex] 安装完成
    echo.
)

echo ========================================
echo 安装完成！
echo ========================================
echo.
echo 成功安装: !SKILLS_COUNT! 个技能
echo.

if "%INSTALL_CLAUDE%"=="1" echo Claude Code: %CLAUDE_SKILLS%
if "%INSTALL_CODEX%"=="1" echo Codex: %CODEX_SKILLS%

echo.
echo 提示:
echo   - 重启 AI 助手以加载新技能
echo   - awesome-claude-skills 索引在 .\awesome-claude-skills\README.md
echo   - 更新所有 submodule: git submodule update --remote --merge
echo.

pause
