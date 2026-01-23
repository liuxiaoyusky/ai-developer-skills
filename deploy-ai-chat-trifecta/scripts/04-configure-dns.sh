#!/bin/bash
# DNS 配置指南
# 用途：指导如何在阿里云配置自定义域名

set -e

# ============================================
# 配置变量
# ============================================
PROJECT_NAME="${PROJECT_NAME:-myapp}"
CUSTOM_DOMAIN="${CUSTOM_DOMAIN:-myapp.example.com}"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}ℹ️  $1${NC}"; }
echo_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
echo_step() { echo -e "${BLUE}📋 $1${NC}"; }

# ============================================
# DNS 配置指南
# ============================================
echo ""
echo_step "DNS 配置指南"
echo ""
echo_info "========================================"
echo_info "步骤 1: 在 Cloudflare 添加自定义域名"
echo_info "========================================"
echo ""
echo_info "运行以下命令："
echo_warn "  wrangler pages custom-domains create $CUSTOM_DOMAIN --project-name=$PROJECT_NAME"
echo ""
echo_info "或使用 Cloudflare Dashboard:"
echo_info "  1. 访问: https://dash.cloudflare.com"
echo_info "  2. Workers & Pages → $PROJECT_NAME → Custom domains"
echo_info "  3. 点击 'Set up a custom domain'"
echo_info "  4. 输入: $CUSTOM_DOMAIN"
echo_info "  5. 点击 'Activate domain'"
echo ""

echo_info "========================================"
echo_info "步骤 2: 在阿里云配置 DNS"
echo_info "========================================"
echo ""
echo_info "1. 访问阿里云 DNS 控制台:"
echo_warn "   https://dc.console.aliyun.com"
echo ""
echo_info "2. 选择你的域名（例如: example.com）"
echo ""
echo_info "3. 添加 DNS 记录："
echo ""
echo_info "   类型:     CNAME"
echo_info "   主机记录: ${CUSTOM_DOMAIN%%.*}  # (myapp)"
echo_info "   记录值:   $PROJECT_NAME.pages.dev"
echo_info "   TTL:      600"
echo ""

echo_info "========================================"
echo_info "步骤 3: 验证 DNS 传播"
echo_info "========================================"
echo ""
echo_info "运行以下命令验证 DNS："
echo_warn "  dig $CUSTOM_DOMAIN"
echo_warn "  nslookup $CUSTOM_DOMAIN"
echo ""
echo_info "预期输出：CNAME 指向 $PROJECT_NAME.pages.dev"
echo ""
echo_warn "⚠️  DNS 传播可能需要 5-30 分钟"
echo ""

echo_info "========================================"
echo_info "步骤 4: 更新 CORS 配置"
echo_info "========================================"
echo ""
echo_info "在 Azure 中添加自定义域名到 CORS："
echo_warn "  az functionapp cors add \\"
echo_warn "    --name $FUNCTION_APP \\"
echo_warn "    --resource-group $RESOURCE_GROUP \\"
echo_warn "    --allowed-origins \"https://$CUSTOM_DOMAIN\""
echo ""
echo_info "在代码中更新 ALLOWED_ORIGINS (backend/src/index.js):"
echo_warn "  const ALLOWED_ORIGINS = ["
echo_warn "    'http://localhost:5173',"
echo_warn "    'https://$PROJECT_NAME.pages.dev',"
echo_warn "    'https://$CUSTOM_DOMAIN'  // 添加这行"
echo_warn "  ];"
echo ""
echo_info "然后重新部署后端："
echo_warn "  cd backend && func azure functionapp publish \$FUNCTION_APP"
echo ""

echo_info "========================================"
echo_info "步骤 5: 更新 GitHub OAuth (如果使用)"
echo_info "========================================"
echo ""
echo_info "1. 访问: https://github.com/settings/developers"
echo_info "2. 编辑你的 OAuth App"
echo_info "3. 添加回调 URL:"
echo_warn "   https://$CUSTOM_DOMAIN/auth/callback"
echo ""
echo_info "4. 更新主页 URL:"
echo_warn "   https://$CUSTOM_DOMAIN"
echo ""

echo_info "========================================"
echo_info "步骤 6: 清除 DNS 缓存（如果需要）"
echo_info "========================================"
echo ""
echo_info "macOS:"
echo_warn "  sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
echo ""
echo_info "Windows:"
echo_warn "  ipconfig /flushdns"
echo ""
echo_info "Linux:"
echo_warn "  sudo systemd-resolve --flush-caches"
echo ""

echo_info "========================================"
echo_info "✅ DNS 配置完成！"
echo_info "========================================"
echo ""
echo_info "🌐 你的应用现在可以通过以下地址访问："
echo_info "  - Cloudflare: https://$PROJECT_NAME.pages.dev"
echo_info "  - 自定义域名: https://$CUSTOM_DOMAIN"
echo ""
echo_warn "⚠️  下一步："
echo_warn "  运行部署验证 (05-test-deployment.sh)"
