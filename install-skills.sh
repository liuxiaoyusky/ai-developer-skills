#!/bin/bash

# AI Developer Skills 一键安装工具 (macOS/Linux)
# 使用方法: chmod +x install-skills.sh && ./install-skills.sh

set -e

echo "========================================"
echo "   AI Developer Skills 一键安装工具"
echo "   v3.0.0 - 含 Submodule 技能"
echo "========================================"
echo ""

# 检查是否在正确的目录
if [ ! -f "skills-manifest.json" ]; then
    echo "❌ 错误: 未找到 skills-manifest.json"
    echo "请确保此脚本在 ai-developer-skills 仓库根目录下运行"
    exit 1
fi

# 初始化 git submodules
echo "初始化 Git Submodules..."
git submodule update --init --recursive
echo "✅ Submodules 就绪"
echo ""

# 检测目标安装路径
CLAUDE_SKILLS="$HOME/.claude/skills"
CODEX_SKILLS="$HOME/.codex/skills"

echo "检测到的安装路径:"
echo "  Claude Code: $CLAUDE_SKILLS"
echo "  Codex: $CODEX_SKILLS"
echo ""

# 询问安装目标
echo "请选择安装目标:"
echo "  1. Claude Code (推荐)"
echo "  2. Codex"
echo "  3. 两者都安装"
echo ""
read -p "请输入选项 (1/2/3, 默认1): " choice

if [ -z "$choice" ]; then
    choice=1
fi

INSTALL_CLAUDE=0
INSTALL_CODEX=0

case $choice in
    1) INSTALL_CLAUDE=1 ;;
    2) INSTALL_CODEX=1 ;;
    3)
        INSTALL_CLAUDE=1
        INSTALL_CODEX=1
        ;;
    *)
        echo "❌ 无效选项"
        exit 1
        ;;
esac

echo ""
echo "========================================"
echo "开始安装技能..."
echo "========================================"
echo ""

SKILLS_COUNT=0

install_skill() {
    local skill_name="$1"
    local skill_source="$2"
    local target_dir="$3"

    echo "正在安装: $skill_name"

    if [ ! -f "$skill_source/SKILL.md" ]; then
        echo "  ⚠️  跳过: 缺少 SKILL.md"
        echo ""
        return
    fi

    mkdir -p "$target_dir"

    # 如果目标已存在，先删除（确保干净更新）
    if [ -d "$target_dir/$skill_name" ]; then
        rm -rf "$target_dir/$skill_name"
    fi

    cp -r "$skill_source" "$target_dir/$skill_name"
    echo "  ✅ 已安装"
    echo ""
    ((SKILLS_COUNT++))
}

# 安装 submodule 集合（每个子 skill 单独安装）
install_skill_collection() {
    local collection_name="$1"
    local skills_dir="$2"
    local target_dir="$3"

    echo "--- 安装集合: $collection_name ---"
    echo ""

    if [ ! -d "$skills_dir" ]; then
        echo "  ⚠️  跳过: 目录不存在 $skills_dir"
        echo ""
        return
    fi

    for skill_path in "$skills_dir"/*/; do
        [ -d "$skill_path" ] || continue
        local name
        name=$(basename "$skill_path")
        if [ -f "$skill_path/SKILL.md" ]; then
            install_skill "$name" "$skill_path" "$target_dir"
        fi
    done
}

install_all_to() {
    local target="$1"

    echo "======== 本地技能 ========"
    echo ""
    install_skill "business-email" "./business_routing/business-email" "$target"
    install_skill "dev-loop" "./general/dev-loop" "$target"
    install_skill "dev-flow" "./general/dev-flow" "$target"
    install_skill "dev-debug" "./general/dev-debug" "$target"
    install_skill "conversation-exporter" "./general/conversation-exporter" "$target"
    install_skill "dev-verify" "./general/dev-verify" "$target"
    install_skill "first-principles-planner" "./general/first-principles-planner" "$target"
    install_skill "n8n-mcp-workflow" "./general/n8n-mcp-workflow/skills/n8n-mcp-workflow" "$target"
    install_skill "first-principles" "./general/first-principles" "$target"
    install_skill "dev-review" "./general/dev-review" "$target"
    install_skill "skill-checker" "./general/skill-checker/skills/skill-checker" "$target"
    install_skill "web-browser-skill" "./web-browser-skill" "$target"
    install_skill "wechat-miniprogram" "./wechat-miniprogram" "$target"
    install_skill "doc-auditor" "./doc-auditor" "$target"
    install_skill "free-ai-chat-deployment" "./free-ai-chat-deployment" "$target"

    echo "======== Submodule: masters-skills ========"
    echo ""
    install_skill "skill-from-masters" "./masters_skills/skills/skill-from-masters" "$target"
    install_skill "skill-from-github" "./masters_skills/skills/skills/skill-from-github" "$target"
    install_skill "search-skill" "./masters_skills/skills/skills/search-skill" "$target"
    install_skill "skill-from-notebook" "./masters_skills/skills/skills/skill-from-notebook" "$target"

    echo "======== Submodule: self-improving-agent ========"
    echo ""
    install_skill "self-improving-agent" "./self-improving-agent" "$target"

    echo "======== Submodule: superpowers (14 skills) ========"
    echo ""
    install_skill_collection "superpowers" "./superpowers/skills" "$target"

    echo "======== Submodule: anthropic-skills (16 skills) ========"
    echo ""
    install_skill_collection "anthropic-skills" "./anthropic-skills/skills" "$target"
}

if [ "$INSTALL_CLAUDE" -eq 1 ]; then
    echo "[Claude Code] 安装中..."
    echo ""
    install_all_to "$CLAUDE_SKILLS"
    echo "[Claude Code] 安装完成"
    echo ""
fi

if [ "$INSTALL_CODEX" -eq 1 ]; then
    echo "[Codex] 安装中..."
    echo ""
    install_all_to "$CODEX_SKILLS"
    echo "[Codex] 安装完成"
    echo ""
fi

echo "========================================"
echo "安装完成！"
echo "========================================"
echo ""
echo "成功安装: $SKILLS_COUNT 个技能"
echo ""

if [ "$INSTALL_CLAUDE" -eq 1 ]; then
    echo "Claude Code: $CLAUDE_SKILLS"
fi
if [ "$INSTALL_CODEX" -eq 1 ]; then
    echo "Codex: $CODEX_SKILLS"
fi

echo ""
echo "提示:"
echo "  - 重启 AI 助手以加载新技能"
echo "  - awesome-claude-skills 索引已在 ./awesome-claude-skills/README.md"
echo "  - 更新所有 submodule: git submodule update --remote --merge"
echo ""
