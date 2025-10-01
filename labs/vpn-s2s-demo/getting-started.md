# Getting Started - VPN Site-to-Site Demo Lab

This guide will walk you through deploying your first Site-to-Site VPN connection between a simulated on-premises network and Azure.

## What You'll Learn

By completing this lab, you'll learn how to:

- ✅ Deploy Azure VPN Gateways
- ✅ Configure Site-to-Site IPSec tunnels
- ✅ Set up hybrid network connectivity
- ✅ Test connectivity between networks
- ✅ Monitor VPN connections
- ✅ Troubleshoot common VPN issues

## Prerequisites

### Required

1. **Azure Subscription** - Active Azure subscription with:
   - Contributor or Owner role
   - Sufficient quota for VPN Gateways and VMs

2. **Azure CLI** - Installed and configured
   ```bash
   # Check if installed
   az --version
   
   # If not installed, visit:
   # https://docs.microsoft.com/cli/azure/install-azure-cli
   ```

3. **Time Commitment** - Allow 1 hour for:
   - Deployment: ~45 minutes (mostly waiting for gateways)
   - Testing and exploration: ~15 minutes

### Optional but Recommended

- **Basic Networking Knowledge** - Understanding of:
  - IP addressing and subnets
  - VPNs and IPSec
  - Azure networking concepts

- **SSH Client** - To connect to test VMs:
  - Linux/Mac: Built-in `ssh` command
  - Windows: PuTTY, Windows Terminal, or WSL

## Step-by-Step Guide

### Step 1: Prepare Your Environment

1. **Login to Azure**
   ```bash
   az login
   ```

2. **Verify your subscription**
   ```bash
   az account list --output table
   
   # Set the subscription you want to use
   az account set --subscription "<your-subscription-name-or-id>"
   ```

3. **Clone or download this repository**
   ```bash
   git clone https://github.com/WapoInc/azure-networking.git
   cd azure-networking/labs/vpn-s2s-demo
   ```

### Step 2: Review the Configuration

Before deploying, review the network configuration:

```bash
cat README.md
```

**Key details:**
- On-Premises VNet: `192.168.1.0/24`
- Azure VNet: `10.100.0.0/22`
- Resource Group: `rg-vpn-s2s-demo`
- Location: `eastus` (can be changed)

### Step 3: Deploy the Lab

**Option A: Using the Deployment Script (Recommended)**

```bash
# Make the script executable (Linux/Mac)
chmod +x deploy.sh

# Run the deployment
./deploy.sh
```

The script will prompt you for:
- Admin password for VMs (must be complex)
- Shared key for VPN connection (optional, will generate if not provided)

**Option B: Using Azure CLI Directly**

```bash
# Create resource group
az group create --name rg-vpn-s2s-demo --location eastus

# Deploy the Bicep template
az deployment group create \
  --resource-group rg-vpn-s2s-demo \
  --template-file main.bicep \
  --parameters \
    adminUsername=azureuser \
    adminPassword='YourP@ssw0rd123!' \
    sharedKey='YourSharedKey123!'
```

**Option C: Using Azure Portal**

1. Open [Azure Portal](https://portal.azure.com)
2. Click "Create a resource" → "Template deployment"
3. Click "Build your own template in the editor"
4. Copy contents of `main.bicep` and paste
5. Click "Save"
6. Fill in parameters and deploy

### Step 4: Monitor the Deployment

The deployment will take approximately 45-50 minutes. Most of this time is spent provisioning the VPN Gateways.

**Track progress:**

```bash
# Watch deployment status
az deployment group show \
  --resource-group rg-vpn-s2s-demo \
  --name <deployment-name> \
  --query properties.provisioningState

# Check gateway provisioning status
az network vnet-gateway show \
  --resource-group rg-vpn-s2s-demo \
  --name vng-onprem \
  --query provisioningState

az network vnet-gateway show \
  --resource-group rg-vpn-s2s-demo \
  --name vng-azure \
  --query provisioningState
```

**In Azure Portal:**
1. Navigate to Resource Groups → rg-vpn-s2s-demo
2. Click "Deployments" in left menu
3. Monitor deployment progress

### Step 5: Verify the VPN Connection

Once deployment completes, wait 5-10 minutes for the VPN connection to establish.

**Check connection status:**

```bash
az network vpn-connection show \
  --resource-group rg-vpn-s2s-demo \
  --name conn-onprem-to-azure \
  --query connectionStatus
```

Expected output: `"Connected"`

### Step 6: Test Connectivity Between VMs

**Get VM IP addresses:**

```bash
# Get public IPs (for SSH access)
ONPREM_VM_PUBLIC=$(az network public-ip show \
  -g rg-vpn-s2s-demo \
  -n pip-vm-onprem \
  --query ipAddress -o tsv)

AZURE_VM_PUBLIC=$(az network public-ip show \
  -g rg-vpn-s2s-demo \
  -n pip-vm-azure \
  --query ipAddress -o tsv)

echo "On-Prem VM Public IP: $ONPREM_VM_PUBLIC"
echo "Azure VM Public IP: $AZURE_VM_PUBLIC"

# Get private IPs (for testing connectivity)
ONPREM_VM_PRIVATE=$(az vm show \
  -g rg-vpn-s2s-demo \
  -n vm-onprem \
  -d --query privateIps -o tsv)

AZURE_VM_PRIVATE=$(az vm show \
  -g rg-vpn-s2s-demo \
  -n vm-azure \
  -d --query privateIps -o tsv)

echo "On-Prem VM Private IP: $ONPREM_VM_PRIVATE"
echo "Azure VM Private IP: $AZURE_VM_PRIVATE"
```

**Test connectivity:**

```bash
# SSH to on-prem VM
ssh azureuser@$ONPREM_VM_PUBLIC

# Once connected, ping the Azure VM
ping $AZURE_VM_PRIVATE

# If ping works, you have successfully established the VPN tunnel!
```

### Step 7: Explore the Configuration

**View VPN Gateway details:**

```bash
az network vnet-gateway show \
  --resource-group rg-vpn-s2s-demo \
  --name vng-azure \
  --output table
```

**View connection metrics:**

```bash
az network vpn-connection show \
  --resource-group rg-vpn-s2s-demo \
  --name conn-onprem-to-azure \
  --query '{name:name, status:connectionStatus, ingressBytes:ingressBytesTransferred, egressBytes:egressBytesTransferred}' \
  --output table
```

**View effective routes on VM:**

```bash
az network nic show-effective-route-table \
  --resource-group rg-vpn-s2s-demo \
  --name nic-vm-onprem \
  --output table
```

## What's Next?

Now that you have a working Site-to-Site VPN, try these exercises:

### Exercise 1: Performance Testing
```bash
# Install iperf3 on both VMs
ssh azureuser@$ONPREM_VM_PUBLIC "sudo apt-get update && sudo apt-get install -y iperf3"
ssh azureuser@$AZURE_VM_PUBLIC "sudo apt-get update && sudo apt-get install -y iperf3"

# Start iperf3 server on Azure VM
ssh azureuser@$AZURE_VM_PUBLIC "iperf3 -s -D"

# Run performance test from on-prem VM
ssh azureuser@$ONPREM_VM_PUBLIC "iperf3 -c $AZURE_VM_PRIVATE -t 30"
```

### Exercise 2: Enable BGP

Edit `main.bicep` and change:
```bicep
param enableBgp bool = true
```

Redeploy and observe dynamic routing.

### Exercise 3: Custom IPSec Policy

Apply custom IPSec policy:
```bash
az network vpn-connection ipsec-policy add \
  --resource-group rg-vpn-s2s-demo \
  --connection-name conn-onprem-to-azure \
  --ike-encryption AES256 \
  --ike-integrity SHA384 \
  --dh-group DHGroup24 \
  --ipsec-encryption GCMAES256 \
  --ipsec-integrity GCMAES256 \
  --pfs-group PFS24 \
  --sa-lifetime 27000 \
  --sa-max-size 102400000
```

### Exercise 4: Upgrade Gateway SKU

Upgrade from Basic to VpnGw1 for better performance:
```bash
az network vnet-gateway update \
  --resource-group rg-vpn-s2s-demo \
  --name vng-azure \
  --sku VpnGw1
```

### Exercise 5: Add More Networks

Extend the lab by:
1. Creating additional VNets
2. Peering them with the Azure VNet
3. Testing connectivity through the VPN

## Troubleshooting

If something doesn't work, check:

1. **VPN Status**: Connection must show "Connected"
2. **Gateway Status**: Both gateways must be "Succeeded"
3. **NSG Rules**: Ensure ICMP and SSH are allowed
4. **VM Firewalls**: Check firewall rules on VMs
5. **Routes**: Verify routes are properly configured

See [troubleshooting.md](troubleshooting.md) for detailed troubleshooting steps.

## Clean Up

When you're done exploring, clean up resources to avoid charges:

```bash
# Option 1: Use cleanup script
./cleanup.sh

# Option 2: Manual cleanup
az group delete --name rg-vpn-s2s-demo --yes --no-wait
```

**Note:** Deletion will take several minutes to complete.

## Cost Management

To minimize costs during exploration:

```bash
# Stop VMs when not in use (no compute charges)
az vm deallocate -g rg-vpn-s2s-demo -n vm-onprem
az vm deallocate -g rg-vpn-s2s-demo -n vm-azure

# Start VMs when needed
az vm start -g rg-vpn-s2s-demo -n vm-onprem
az vm start -g rg-vpn-s2s-demo -n vm-azure
```

**Note:** VPN Gateways continue to incur charges even when not actively transferring data.

## Additional Resources

- [Architecture Diagram](architecture.md) - Visual guide to the deployment
- [Configuration Snippets](configuration-snippets.md) - Useful commands and configs
- [Quick Reference](quick-reference.md) - Cheat sheet for common tasks
- [Main README](README.md) - Complete documentation

## Get Help

If you encounter issues:

1. Check [troubleshooting.md](troubleshooting.md)
2. Review [Azure VPN Gateway documentation](https://docs.microsoft.com/azure/vpn-gateway/)
3. Open an issue in this repository
4. Visit [Microsoft Q&A](https://docs.microsoft.com/answers/)

## Feedback

We'd love to hear about your experience with this lab! Please provide feedback by:
- Opening an issue
- Submitting a pull request with improvements
- Sharing your use case

---

**Happy Learning! 🚀**

Now you're ready to build hybrid cloud networks with Azure VPN Gateway!
