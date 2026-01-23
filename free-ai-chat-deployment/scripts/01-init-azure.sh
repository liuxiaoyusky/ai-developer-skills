#!/bin/bash
# Azure 资源初始化脚本
# 用途：创建 Resource Group、Storage Account 和 Function App

set -e  # 遇到错误立即退出

# ============================================
# 配置变量（请根据你的项目修改）
# ============================================
RESOURCE_GROUP="myapp-rg"
FUNCTION_APP="myapp-api"
LOCATION="eastasia"
STORAGE_ACCOUNT="myappstorage$(date +%s)"  # 添加时间戳确保唯一性

# ============================================
# 颜色输出
# ============================================
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

echo_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

# ============================================
# 检查 Azure 登录状态
# ============================================
echo_info "检查 Azure 登录状态..."
if ! az account show > /dev/null 2>&1; then
    echo_error "未登录 Azure，请先运行: az login"
    exit 1
fi

# ============================================
# 创建资源组
# ============================================
echo_info "创建资源组: $RESOURCE_GROUP (位置: $LOCATION)"
if az group show --name $RESOURCE_GROUP > /dev/null 2>&1; then
    echo_warn "资源组已存在，跳过创建"
else
    az group create \
        --name $RESOURCE_GROUP \
        --location $LOCATION \
        --output none
    echo_info "✅ 资源组创建成功"
fi

# ============================================
# 创建存储账户
# ============================================
echo_info "创建存储账户: $STORAGE_ACCOUNT"
az storage account create \
    --name $STORAGE_ACCOUNT \
    --location $LOCATION \
    --resource-group $RESOURCE_GROUP \
    --sku Standard_LRS \
    --output none
echo_info "✅ 存储账户创建成功"

# ============================================
# 创建 Function App
# ============================================
echo_info "创建 Function App: $FUNCTION_APP"
az functionapp create \
    --resource-group $RESOURCE_GROUP \
    --consumption-plan-location $LOCATION \
    --runtime node \
    --runtime-version 20 \
    --functions-version 4 \
    --name $FUNCTION_APP \
    --storage-account $STORAGE_ACCOUNT \
    --os-type Linux \
    --output none
echo_info "✅ Function App 创建成功"

# ============================================
# 输出结果
# ============================================
echo ""
echo_info "======================================"
echo_info "🎉 Azure 资源初始化完成！"
echo_info "======================================"
echo ""
echo_info "📌 资源信息："
echo_info "  资源组: $RESOURCE_GROUP"
echo_info "  Function App: $FUNCTION_APP"
echo_info "  位置: $LOCATION"
echo_info "  存储账户: $STORAGE_ACCOUNT"
echo ""
echo_info "🌐 Function App URL:"
echo_info "  https://$FUNCTION_APP.azurewebsites.net"
echo ""
echo_warn "⚠️  下一步："
echo_warn "  1. 配置环境变量（运行 02-configure-env.sh）"
echo_warn "  2. 部署后端代码（运行 02-deploy-backend.sh）"
echo ""
echo_info "💾 保存这些变量到你的环境："
echo_info "  export RESOURCE_GROUP=$RESOURCE_GROUP"
echo_info "  export FUNCTION_APP=$FUNCTION_APP"
echo_info "  export STORAGE_ACCOUNT=$STORAGE_ACCOUNT"
