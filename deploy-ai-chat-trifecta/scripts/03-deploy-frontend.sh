#!/bin/bash
# 前端部署脚本
# 用途：构建并部署到 Cloudflare Pages

set -e

# ============================================
# 配置变量
# ============================================
PROJECT_NAME="${PROJECT_NAME:-myapp}"
FRONTEND_DIR="${FRONTEND_DIR:-./frontend}"
BUILD_DIR="${BUILD_DIR:-dist}"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}ℹ️  $1${NC}"; }
echo_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
echo_error() { echo -e "${RED}❌ $1${NC}"; }

# ============================================
# 检查 Cloudflare 登录
# ============================================
echo_info "检查 Cloudflare 登录状态..."
if ! wrangler whoami > /dev/null 2>&1; then
    echo_error "未登录 Cloudflare，请先运行: wrangler login"
    exit 1
fi

# ============================================
# 检查目录
# ============================================
echo_info "检查前端目录: $FRONTEND_DIR"
if [ ! -d "$FRONTEND_DIR" ]; then
    echo_error "目录不存在: $FRONTEND_DIR"
    exit 1
fi

cd "$FRONTEND_DIR"

# ============================================
# 安装依赖
# ============================================
echo_info "安装依赖..."
if [ -f "package.json" ]; then
    npm install
    echo_info "✅ 依赖安装完成"
else
    echo_error "未找到 package.json"
    exit 1
fi

# ============================================
# 构建项目
# ============================================
echo_info "构建项目..."
npm run build

if [ ! -d "$BUILD_DIR" ]; then
    echo_error "构建失败：未找到输出目录 $BUILD_DIR"
    exit 1
fi

echo_info "✅ 构建完成"

# ============================================
# 部署到 Cloudflare Pages
# ============================================
echo_info "部署到 Cloudflare Pages..."
wrangler pages deploy "$BUILD_DIR" \
    --project-name="$PROJECT_NAME" \
    --branch=production

echo_info "✅ 部署完成"

# ============================================
# 输出结果
# ============================================
echo ""
echo_info "======================================"
echo_info "🎉 前端部署完成！"
echo_info "======================================"
echo ""
echo_info "🌐 前端 URL:"
echo_info "  https://$PROJECT_NAME.pages.dev"
echo ""
echo_warn "⚠️  下一步："
echo_warn "  1. 配置自定义域名 (运行 04-configure-dns.sh)"
echo_warn "  2. 更新 CORS 配置"
echo ""
echo_info "💾 保存项目名称："
echo_info "  export PROJECT_NAME=$PROJECT_NAME"
