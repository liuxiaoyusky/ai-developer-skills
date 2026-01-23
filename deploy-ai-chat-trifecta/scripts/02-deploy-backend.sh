#!/bin/bash
# 后端部署脚本
# 用途：部署 Azure Functions 后端

set -e

# ============================================
# 配置变量
# ============================================
RESOURCE_GROUP="${RESOURCE_GROUP:-myapp-rg}"
FUNCTION_APP="${FUNCTION_APP:-myapp-api}"
BACKEND_DIR="${BACKEND_DIR:-./backend}"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}ℹ️  $1${NC}"; }
echo_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
echo_error() { echo -e "${RED}❌ $1${NC}"; }

# ============================================
# 检查变量
# ============================================
if [ -z "$RESOURCE_GROUP" ] || [ -z "$FUNCTION_APP" ]; then
    echo_error "请设置环境变量:"
    echo_error "  export RESOURCE_GROUP=your-resource-group"
    echo_error "  export FUNCTION_APP=your-function-app"
    exit 1
fi

# ============================================
# 检查目录
# ============================================
echo_info "检查后端目录: $BACKEND_DIR"
if [ ! -d "$BACKEND_DIR" ]; then
    echo_error "目录不存在: $BACKEND_DIR"
    exit 1
fi

cd "$BACKEND_DIR"

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
# 部署到 Azure
# ============================================
echo_info "部署到 Azure Functions: $FUNCTION_APP"
func azure functionapp publish "$FUNCTION_APP"

echo_info "✅ 代码部署完成"

# ============================================
# 重启 Function App
# ============================================
echo_info "重启 Function App..."
az functionapp restart \
    --name "$FUNCTION_APP" \
    --resource-group "$RESOURCE_GROUP" \
    --output none 2>/dev/null || echo_warn "重启失败，可能需要手动重启"

echo_info "✅ Function App 重启完成"

# ============================================
# 验证部署
# ============================================
echo_info "验证部署..."
sleep 5  # 等待重启完成

HEALTH_URL="https://$FUNCTION_APP.azurewebsites.net/api/health"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    echo_info "✅ 健康检查通过"
    curl -s "$HEALTH_URL" | jq . 2>/dev/null || curl -s "$HEALTH_URL"
else
    echo_warn "健康检查失败 (HTTP $HTTP_CODE)"
    echo_warn "请手动检查: $HEALTH_URL"
fi

# ============================================
# 完成
# ============================================
echo ""
echo_info "======================================"
echo_info "🎉 后端部署完成！"
echo_info "======================================"
echo ""
echo_info "🌐 后端 URL:"
echo_info "  https://$FUNCTION_APP.azurewebsites.net"
echo ""
echo_info "🔍 健康检查:"
echo_info "  curl https://$FUNCTION_APP.azurewebsites.net/api/health"
echo ""
echo_warn "⚠️  下一步："
echo_warn "  部署前端 (运行 03-deploy-frontend.sh)"
