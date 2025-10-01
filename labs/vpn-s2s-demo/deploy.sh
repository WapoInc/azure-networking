#!/bin/bash

# ============================================================================
# VPN Site-to-Site Demo Lab - Deployment Script
# ============================================================================
# This script automates the deployment of the VPN S2S demo lab
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="rg-vpn-s2s-demo"
LOCATION="eastus"
ADMIN_USERNAME="azureuser"
DEPLOY_VMS="true"
GATEWAY_SKU="Basic"
ENABLE_BGP="false"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo "============================================================================"
    echo "$1"
    echo "============================================================================"
    echo ""
}

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    echo "Visit: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

print_header "VPN Site-to-Site Demo Lab Deployment"

# Check if logged in
print_info "Checking Azure CLI authentication..."
if ! az account show &> /dev/null; then
    print_error "Not logged in to Azure. Running 'az login'..."
    az login
fi

# Get current subscription
SUBSCRIPTION=$(az account show --query name -o tsv)
print_info "Using subscription: ${SUBSCRIPTION}"

# Prompt for admin password
echo ""
read -s -p "Enter admin password for test VMs: " ADMIN_PASSWORD
echo ""
read -s -p "Confirm admin password: " ADMIN_PASSWORD_CONFIRM
echo ""

if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]; then
    print_error "Passwords do not match. Exiting."
    exit 1
fi

# Prompt for shared key
echo ""
read -s -p "Enter shared key for VPN connection (or press Enter for random): " SHARED_KEY
echo ""
if [ -z "$SHARED_KEY" ]; then
    SHARED_KEY="Azure$(date +%s)Key!"
    print_info "Generated random shared key"
fi

# Create resource group
print_header "Step 1: Creating Resource Group"
print_info "Creating resource group: ${RESOURCE_GROUP} in ${LOCATION}..."
az group create \
    --name "${RESOURCE_GROUP}" \
    --location "${LOCATION}" \
    --output table

# Deploy the Bicep template
print_header "Step 2: Deploying Infrastructure"
print_warning "This will take approximately 45-50 minutes (VPN gateways take time to provision)..."
print_info "Starting deployment..."

DEPLOYMENT_NAME="vpn-s2s-$(date +%Y%m%d-%H%M%S)"

az deployment group create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${DEPLOYMENT_NAME}" \
    --template-file main.bicep \
    --parameters \
        adminUsername="${ADMIN_USERNAME}" \
        adminPassword="${ADMIN_PASSWORD}" \
        sharedKey="${SHARED_KEY}" \
        deployTestVMs=${DEPLOY_VMS} \
        gatewaySku="${GATEWAY_SKU}" \
        enableBgp=${ENABLE_BGP} \
    --output table

# Get deployment outputs
print_header "Step 3: Deployment Complete!"

print_info "Retrieving deployment outputs..."

ONPREM_GW_IP=$(az deployment group show \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${DEPLOYMENT_NAME}" \
    --query properties.outputs.onpremGatewayPublicIp.value \
    -o tsv)

AZURE_GW_IP=$(az deployment group show \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${DEPLOYMENT_NAME}" \
    --query properties.outputs.azureGatewayPublicIp.value \
    -o tsv)

ONPREM_VM_IP=$(az deployment group show \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${DEPLOYMENT_NAME}" \
    --query properties.outputs.onpremVmPublicIp.value \
    -o tsv)

AZURE_VM_IP=$(az deployment group show \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${DEPLOYMENT_NAME}" \
    --query properties.outputs.azureVmPublicIp.value \
    -o tsv)

# Display results
print_header "Deployment Summary"

echo "Resource Group: ${RESOURCE_GROUP}"
echo "Location: ${LOCATION}"
echo ""
echo "On-Premises VPN Gateway Public IP: ${ONPREM_GW_IP}"
echo "Azure VPN Gateway Public IP: ${AZURE_GW_IP}"
echo ""

if [ "$DEPLOY_VMS" = "true" ]; then
    echo "On-Premises VM Public IP: ${ONPREM_VM_IP}"
    echo "Azure VM Public IP: ${AZURE_VM_IP}"
    echo ""
    echo "SSH Commands:"
    echo "  ssh ${ADMIN_USERNAME}@${ONPREM_VM_IP}"
    echo "  ssh ${ADMIN_USERNAME}@${AZURE_VM_IP}"
fi

echo ""
print_header "Next Steps"
echo "1. Wait 5-10 minutes for VPN connection to fully establish"
echo "2. Check connection status:"
echo "   az network vpn-connection show \\"
echo "     -g ${RESOURCE_GROUP} \\"
echo "     -n conn-onprem-to-azure \\"
echo "     --query connectionStatus"
echo ""
echo "3. Test connectivity between VMs (if deployed):"
echo "   - SSH to on-prem VM: ssh ${ADMIN_USERNAME}@${ONPREM_VM_IP}"
echo "   - Get Azure VM private IP and ping it"
echo ""
print_info "Deployment completed successfully!"
