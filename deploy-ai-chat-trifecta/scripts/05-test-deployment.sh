#!/bin/bash
# 部署验证测试脚本
# 用途：验证全栈部署是否成功

set -e

# ============================================
# 配置变量
# ============================================
FUNCTION_APP="${FUNCTION_APP:-myapp-api}"
PROJECT_NAME="${PROJECT_NAME:-myapp}"
CUSTOM_DOMAIN="${CUSTOM_DOMAIN:-}"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}✅ $1${NC}"; }
echo_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
echo_error() { echo -e "${RED}❌ $1${NC}"; }
echo_test() { echo -e "\n${BLUE}🧪 测试: $1${NC}"; }

# 统计
PASSED=0
FAILED=0

# ============================================
# 测试函数
# ============================================
test_backend_health() {
    echo_test "后端健康检查"

    local url="https://$FUNCTION_APP.azurewebsites.net/api/health"
    local response=$(curl -s "$url" 2>/dev/null)
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)

    if [ "$http_code" = "200" ]; then
        echo_info "后端健康检查通过 (HTTP 200)"
        echo "$response" | jq . 2>/dev/null || echo "$response"
        ((PASSED++))
    else
        echo_error "后端健康检查失败 (HTTP $http_code)"
        ((FAILED++))
    fi
}

test_frontend_accessibility() {
    echo_test "前端可访问性"

    local url="https://$PROJECT_NAME.pages.dev"
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)

    if [ "$http_code" = "200" ]; then
        echo_info "前端可访问 (HTTP 200)"
        ((PASSED++))
    else
        echo_error "前端不可访问 (HTTP $http_code)"
        ((FAILED++))
    fi
}

test_cors() {
    echo_test "CORS 预检"

    local url="https://$FUNCTION_APP.azurewebsites.net/api/health"
    local origin="https://$PROJECT_NAME.pages.dev"

    local cors_header=$(curl -s -I -X OPTIONS \
        -H "Origin: $origin" \
        -H "Access-Control-Request-Method: POST" \
        "$url" 2>/dev/null | grep -i "access-control-allow-origin")

    if [ -n "$cors_header" ]; then
        echo_info "CORS 配置正确"
        echo "  $cors_header"
        ((PASSED++))
    else
        echo_error "CORS 配置可能有问题"
        echo_warn "请检查 Azure CORS 设置和代码中的 ALLOWED_ORIGINS"
        ((FAILED++))
    fi
}

test_streaming() {
    echo_test "SSE 流式传输"

    local url="https://$FUNCTION_APP.azurewebsites.net/api/stream-test"

    if timeout 3 curl -sfN "$url" 2>/dev/null | head -c 100 | grep -q "data:"; then
        echo_info "SSE 流式传输正常"
        ((PASSED++))
    else
        echo_warn "SSE 流式传输未测试（可能不存在 /api/stream-test 端点）"
        # 不计为失败
    fi
}

test_custom_domain() {
    if [ -n "$CUSTOM_DOMAIN" ]; then
        echo_test "自定义域名"

        local http_code=$(curl -s -o /dev/null -w "%{http_code}" "https://$CUSTOM_DOMAIN" 2>/dev/null)

        if [ "$http_code" = "200" ]; then
            echo_info "自定义域名可访问 (HTTP 200)"
            ((PASSED++))
        else
            echo_error "自定义域名不可访问 (HTTP $http_code)"
            echo_warn "检查 DNS 配置和传播状态"
            ((FAILED++))
        fi
    fi
}

test_dns() {
    if [ -n "$CUSTOM_DOMAIN" ]; then
        echo_test "DNS 解析"

        local dns_result=$(dig +short "$CUSTOM_DOMAIN" 2>/dev/null)

        if echo "$dns_result" | grep -q "pages.dev"; then
            echo_info "DNS 解析正确"
            echo "  $dns_result"
            ((PASSED++))
        else
            echo_error "DNS 解析可能有问题"
            echo "  当前结果: $dns_result"
            echo_warn "预期: CNAME 指向 $PROJECT_NAME.pages.dev"
            ((FAILED++))
        fi
    fi
}

# ============================================
# 运行测试
# ============================================
echo ""
echo_info "======================================"
echo_info "🧪 部署验证测试"
echo_info "======================================"
echo ""
echo_info "配置信息:"
echo_info "  Function App: $FUNCTION_APP"
echo_info "  Project Name: $PROJECT_NAME"
echo_info "  Custom Domain: ${CUSTOM_DOMAIN:-未配置}"
echo ""

# 运行所有测试
test_backend_health
test_frontend_accessibility
test_cors
test_streaming
test_custom_domain
test_dns

# ============================================
# 输出结果
# ============================================
echo ""
echo_info "======================================"
echo_info "测试结果"
echo_info "======================================"
echo ""
echo_info "通过: $PASSED"
echo_error "失败: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo_info "🎉 所有测试通过！部署成功！"
    echo ""
    echo_info "🌐 应用 URL:"
    echo_info "  后端: https://$FUNCTION_APP.azurewebsites.net"
    echo_info "  前端: https://$PROJECT_NAME.pages.dev"
    if [ -n "$CUSTOM_DOMAIN" ]; then
        echo_info "  自定义域名: https://$CUSTOM_DOMAIN"
    fi
    exit 0
else
    echo_error "部分测试失败，请检查上述错误"
    echo ""
    echo_warn "💡 常见问题排查:"
    echo_warn "  1. 后端未就绪：等待几分钟再试"
    echo_warn "  2. CORS 错误：检查 Azure CORS 设置和代码配置"
    echo_warn "  3. DNS 未传播：等待 5-30 分钟"
    echo_warn "  4. 查看故障排除指南: docs/troubleshooting.md"
    exit 1
fi
