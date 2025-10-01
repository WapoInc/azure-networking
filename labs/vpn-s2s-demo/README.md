# VPN Site-to-Site Demo Lab

This demo lab creates a simulated on-premises VNet connected to an Azure VNet via IPSec VPN tunnel.

## 📚 Documentation

- **[Getting Started Guide](getting-started.md)** - Step-by-step walkthrough for beginners
- **[Architecture Diagram](architecture.md)** - Visual guide and detailed architecture
- **[Configuration Snippets](configuration-snippets.md)** - Useful commands and configurations
- **[Quick Reference](quick-reference.md)** - Cheat sheet for common tasks
- **[Troubleshooting Guide](troubleshooting.md)** - Solutions to common issues

## Architecture Overview

This lab deploys:
- **On-Premises VNet**: 192.168.1.0/24 with VPN Gateway
- **Azure VNet**: 10.100.0.0/22 with VPN Gateway
- **IPSec Tunnel**: Site-to-Site VPN connection between the gateways

```
┌─────────────────────────┐                    ┌─────────────────────────┐
│   On-Premises VNet      │                    │      Azure VNet         │
│   192.168.1.0/24        │                    │    10.100.0.0/22        │
│                         │                    │                         │
│  ┌──────────────────┐   │                    │  ┌──────────────────┐   │
│  │  Subnet          │   │                    │  │  Subnet          │   │
│  │  192.168.1.0/27  │   │                    │  │  10.100.0.0/24   │   │
│  │                  │   │                    │  │                  │   │
│  │  [Test VM]       │   │                    │  │  [Test VM]       │   │
│  └──────────────────┘   │                    │  └──────────────────┘   │
│                         │                    │                         │
│  ┌──────────────────┐   │    IPSec Tunnel    │  ┌──────────────────┐   │
│  │ Gateway Subnet   │   │  ════════════════  │  │ Gateway Subnet   │   │
│  │ 192.168.1.224/27 │◄──┼────────────────────┼──►│ 10.100.3.224/27  │   │
│  │                  │   │                    │  │                  │   │
│  │  [VPN Gateway]   │   │                    │  │  [VPN Gateway]   │   │
│  └──────────────────┘   │                    │  └──────────────────┘   │
└─────────────────────────┘                    └─────────────────────────┘
```

## Prerequisites

- Azure subscription
- Azure CLI installed (`az` command)
- Contributor or Owner access to the subscription
- Bicep CLI (automatically included with Azure CLI 2.20.0+)

## Quick Start

### Option 1: Deploy with Azure CLI (Recommended)

```bash
# 1. Login to Azure
az login

# 2. Set your subscription (replace with your subscription ID)
az account set --subscription "<your-subscription-id>"

# 3. Create resource group
az group create --name rg-vpn-s2s-demo --location eastus

# 4. Deploy the lab
az deployment group create \
  --resource-group rg-vpn-s2s-demo \
  --template-file main.bicep \
  --parameters adminUsername=azureuser \
  --parameters adminPassword='<YourSecurePassword123!>'
```

### Option 2: Deploy with PowerShell

```powershell
# 1. Login to Azure
Connect-AzAccount

# 2. Create resource group
New-AzResourceGroup -Name rg-vpn-s2s-demo -Location eastus

# 3. Deploy the lab
New-AzResourceGroupDeployment `
  -ResourceGroupName rg-vpn-s2s-demo `
  -TemplateFile main.bicep `
  -adminUsername azureuser `
  -adminPassword '<YourSecurePassword123!>'
```

### Option 3: Use the Deploy Script

```bash
# Make the script executable
chmod +x deploy.sh

# Run the deployment
./deploy.sh
```

## What Gets Deployed

The deployment creates:

1. **Two Virtual Networks:**
   - On-Premises VNet (192.168.1.0/24)
     - Default Subnet: 192.168.1.0/27
     - Gateway Subnet: 192.168.1.224/27
   - Azure VNet (10.100.0.0/22)
     - Default Subnet: 10.100.0.0/24
     - Gateway Subnet: 10.100.3.224/27

2. **Two VPN Gateways:**
   - Basic SKU (for demo purposes - upgrade to VpnGw1 or higher for production)
   - Route-based VPN type
   - Active-active mode disabled (can be enabled)

3. **IPSec Tunnel Configuration:**
   - Connection type: Site-to-Site (IPsec)
   - IKE version: IKEv2
   - Shared key: automatically generated (customizable)

4. **Test Virtual Machines (Optional):**
   - One VM in each VNet for connectivity testing
   - Ubuntu 20.04 LTS
   - Standard_B2s size

## Deployment Time

- **VPN Gateways**: ~30-45 minutes (this is the longest part)
- **VNets and Subnets**: ~2 minutes
- **VPN Connection**: ~5 minutes
- **Total**: ~45-50 minutes

## Testing Connectivity

After deployment completes:

1. **Get VM Private IP addresses:**
   ```bash
   az vm show -g rg-vpn-s2s-demo -n vm-onprem --show-details --query privateIps -o tsv
   az vm show -g rg-vpn-s2s-demo -n vm-azure --show-details --query privateIps -o tsv
   ```

2. **SSH into the On-Premises VM:**
   ```bash
   ssh azureuser@<onprem-vm-public-ip>
   ```

3. **Test connectivity to Azure VM:**
   ```bash
   ping <azure-vm-private-ip>
   ```

4. **Check VPN connection status:**
   ```bash
   az network vpn-connection show \
     -g rg-vpn-s2s-demo \
     -n conn-onprem-to-azure \
     --query connectionStatus
   ```

## Configuration Details

### VPN Gateway Settings

**On-Premises Gateway:**
- Name: vng-onprem
- SKU: Basic (VpnGw1 recommended for production)
- VPN Type: RouteBased
- BGP: Disabled (can be enabled)

**Azure Gateway:**
- Name: vng-azure
- SKU: Basic (VpnGw1 recommended for production)
- VPN Type: RouteBased
- BGP: Disabled (can be enabled)

### IPSec/IKE Policy (Default)

```
IKE Phase 1:
- Encryption: AES256
- Integrity: SHA256
- DH Group: DHGroup2
- PFS Group: None
- SA Lifetime: 28800 seconds

IKE Phase 2:
- Encryption: AES256
- Integrity: SHA256
- PFS Group: None
- SA Lifetime: 27000 seconds
```

## Customization

### Change Shared Key

Edit the `main.bicep` file or pass as parameter:

```bash
az deployment group create \
  --resource-group rg-vpn-s2s-demo \
  --template-file main.bicep \
  --parameters sharedKey='YourCustomSharedKey123!'
```

### Enable BGP

Set `enableBgp` parameter to `true`:

```bash
az deployment group create \
  --resource-group rg-vpn-s2s-demo \
  --template-file main.bicep \
  --parameters enableBgp=true
```

### Upgrade Gateway SKU

For production, use VpnGw1 or higher:

```bash
az deployment group create \
  --resource-group rg-vpn-s2s-demo \
  --template-file main.bicep \
  --parameters gatewaySku='VpnGw1'
```

## Monitoring and Troubleshooting

### Check VPN Connection Status

```bash
# Check connection status
az network vpn-connection show \
  -g rg-vpn-s2s-demo \
  -n conn-onprem-to-azure \
  --query "{name:name, status:connectionStatus, ingressBytes:ingressBytesTransferred, egressBytes:egressBytesTransferred}"

# Check VPN Gateway
az network vnet-gateway show \
  -g rg-vpn-s2s-demo \
  -n vng-azure
```

### View Metrics in Azure Portal

1. Navigate to the VPN Gateway resource
2. Click on "Metrics"
3. Select metrics like:
   - Gateway S2S Bandwidth
   - Tunnel Ingress/Egress Bytes
   - BGP Peer Status (if BGP is enabled)

### Common Issues

**Connection shows "Not Connected":**
- Verify both gateways are fully provisioned (check provisioning state)
- Ensure shared keys match on both sides
- Check that gateway subnets don't overlap
- Verify NSG rules aren't blocking traffic

**Can't ping between VMs:**
- Check VM network security groups
- Verify VPN connection status is "Connected"
- Check VM firewall rules (Linux: ufw, Windows: Windows Firewall)
- Verify routes are propagated correctly

## Cost Considerations

**Estimated Monthly Cost (East US region):**
- VPN Gateway (Basic SKU): ~$27/month per gateway = $54/month
- VPN Gateway (VpnGw1 SKU): ~$140/month per gateway = $280/month
- Virtual Machines (B2s): ~$30/month per VM = $60/month
- Public IPs: ~$3.65/month per IP = ~$15/month (4 IPs)
- Data Transfer: Variable based on usage

**Total: ~$129-355/month**

To save costs during testing, deallocate VMs when not in use:
```bash
az vm deallocate -g rg-vpn-s2s-demo -n vm-onprem
az vm deallocate -g rg-vpn-s2s-demo -n vm-azure
```

## Clean Up

To delete all resources:

```bash
az group delete --name rg-vpn-s2s-demo --yes --no-wait
```

## Next Steps

- Enable BGP for dynamic routing
- Implement custom IPSec/IKE policies
- Add Azure Firewall for centralized security
- Connect multiple on-premises locations
- Implement ExpressRoute for dedicated connectivity
- Add Azure Route Server for advanced routing scenarios

## References

- [Azure VPN Gateway Documentation](https://docs.microsoft.com/azure/vpn-gateway/)
- [Configure Site-to-Site VPN](https://docs.microsoft.com/azure/vpn-gateway/vpn-gateway-howto-site-to-site-resource-manager-portal)
- [VPN Gateway SKUs](https://docs.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpn-gateway-settings#gwsku)
- [IPsec/IKE Policy](https://docs.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpn-devices)

## Support

For issues or questions:
- Open an issue in this repository
- Refer to the [Azure Networking Design Resources](../../README.md)
- Check the [Hub-Spoke Design documentation](../../README.md#azure-hub-spoke-design)
