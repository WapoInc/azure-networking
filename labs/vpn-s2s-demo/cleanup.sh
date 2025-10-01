#!/bin/bash

# ============================================================================
# VPN Site-to-Site Demo Lab - Cleanup Script
# ============================================================================
# This script removes all resources created by the demo lab
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="rg-vpn-s2s-demo"

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
    print_error "Azure CLI is not installed."
    exit 1
fi

print_header "VPN Site-to-Site Demo Lab Cleanup"

# Check if logged in
print_info "Checking Azure CLI authentication..."
if ! az account show &> /dev/null; then
    print_error "Not logged in to Azure. Running 'az login'..."
    az login
fi

# Get current subscription
SUBSCRIPTION=$(az account show --query name -o tsv)
print_info "Using subscription: ${SUBSCRIPTION}"

# Check if resource group exists
if ! az group exists --name "${RESOURCE_GROUP}" | grep -q true; then
    print_warning "Resource group ${RESOURCE_GROUP} does not exist. Nothing to clean up."
    exit 0
fi

# List resources
print_header "Resources to be deleted"
az resource list --resource-group "${RESOURCE_GROUP}" --output table

# Confirm deletion
echo ""
print_warning "This will DELETE all resources in the resource group: ${RESOURCE_GROUP}"
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_info "Cleanup cancelled."
    exit 0
fi

# Delete resource group
print_header "Deleting Resources"
print_info "Deleting resource group: ${RESOURCE_GROUP}..."
print_warning "This may take several minutes..."

az group delete \
    --name "${RESOURCE_GROUP}" \
    --yes \
    --no-wait

print_info "Delete operation initiated. Resources will be removed in the background."
print_info "To check status, run: az group show --name ${RESOURCE_GROUP}"
print_header "Cleanup Complete"
