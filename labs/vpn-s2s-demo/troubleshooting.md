# Troubleshooting Guide - VPN Site-to-Site Demo Lab

## Common Issues and Solutions

### 1. VPN Connection Status Shows "Not Connected"

**Symptoms:**
- Connection status shows "NotConnected" or "Unknown"
- Unable to ping between VMs

**Possible Causes & Solutions:**

#### A. Gateway Still Provisioning
```bash
# Check gateway provisioning state
az network vnet-gateway show \
  -g rg-vpn-s2s-demo \
  -n vng-azure \
  --query provisioningState

az network vnet-gateway show \
  -g rg-vpn-s2s-demo \
  -n vng-onprem \
  --query provisioningState
```
**Solution:** Wait for both gateways to show "Succeeded" status (takes 30-45 minutes)

#### B. Shared Key Mismatch
```bash
# Verify shared keys match on both connections
az network vpn-connection shared-key show \
  -g rg-vpn-s2s-demo \
  -n conn-onprem-to-azure
```
**Solution:** Update the shared key if needed

#### C. Gateway Subnet Configuration Issue
```bash
# Verify gateway subnets
az network vnet subnet show \
  -g rg-vpn-s2s-demo \
  --vnet-name vnet-onprem \
  -n GatewaySubnet

az network vnet subnet show \
  -g rg-vpn-s2s-demo \
  --vnet-name vnet-azure \
  -n GatewaySubnet
```
**Solution:** Ensure GatewaySubnet exists and is not overlapping

### 2. Deployment Fails

**Symptoms:**
- Bicep/ARM deployment fails
- Error messages during deployment

**Common Errors:**

#### A. Invalid Password
```
Error: Password must meet complexity requirements
```
**Solution:** Use a password with:
- At least 12 characters
- Upper and lowercase letters
- Numbers
- Special characters
- Example: `MyP@ssw0rd123!`

#### B. Quota Exceeded
```
Error: Operation results in exceeding quota limits
```
**Solution:** 
```bash
# Check quota
az vm list-usage --location eastus --output table

# Request quota increase through Azure Portal
```

#### C. SKU Not Available
```
Error: The requested VM/Gateway size is not available
```
**Solution:** Try a different region or SKU:
```bash
# List available VM sizes
az vm list-sizes --location eastus --output table

# List available gateway SKUs in documentation
```

### 3. Cannot SSH to VMs

**Symptoms:**
- SSH connection timeout
- Connection refused

**Solutions:**

#### A. Check NSG Rules
```bash
# Verify NSG allows SSH
az network nsg rule list \
  -g rg-vpn-s2s-demo \
  --nsg-name nsg-onprem \
  --output table

# Add SSH rule if missing
az network nsg rule create \
  -g rg-vpn-s2s-demo \
  --nsg-name nsg-onprem \
  -n allow-ssh \
  --priority 1000 \
  --destination-port-ranges 22 \
  --protocol Tcp \
  --access Allow
```

#### B. Check VM Status
```bash
# Verify VM is running
az vm get-instance-view \
  -g rg-vpn-s2s-demo \
  -n vm-onprem \
  --query instanceView.statuses
```

#### C. Verify Public IP
```bash
# Get public IP
az network public-ip show \
  -g rg-vpn-s2s-demo \
  -n pip-vm-onprem \
  --query ipAddress -o tsv
```

### 4. Cannot Ping Between VMs

**Symptoms:**
- VPN shows "Connected" but ping fails
- Intermittent connectivity

**Solutions:**

#### A. Check VM Firewall
```bash
# SSH to VM and check firewall
sudo ufw status

# Disable firewall temporarily for testing
sudo ufw disable

# Or allow ICMP
sudo ufw allow from 192.168.1.0/24
sudo ufw allow from 10.100.0.0/22
```

#### B. Verify Effective Routes
```bash
# Check effective routes on NIC
az network nic show-effective-route-table \
  -g rg-vpn-s2s-demo \
  -n nic-vm-onprem \
  --output table
```

#### C. Check NSG Rules
```bash
# Ensure ICMP is allowed
az network nsg rule create \
  -g rg-vpn-s2s-demo \
  --nsg-name nsg-onprem \
  -n allow-icmp \
  --priority 1001 \
  --protocol Icmp \
  --access Allow
```

### 5. Gateway Performance Issues

**Symptoms:**
- Slow VPN throughput
- High latency

**Solutions:**

#### A. Check Gateway Metrics
```bash
# View gateway metrics in portal
# Or use Azure Monitor
az monitor metrics list \
  --resource-type "Microsoft.Network/virtualNetworkGateways" \
  --resource-group rg-vpn-s2s-demo \
  --resource vng-azure \
  --metric-names "TunnelAverageBandwidth"
```

#### B. Upgrade Gateway SKU
```bash
# Current: Basic (100 Mbps)
# Upgrade to VpnGw1 (650 Mbps) or higher
az network vnet-gateway update \
  -g rg-vpn-s2s-demo \
  -n vng-azure \
  --sku VpnGw1
```

#### C. Enable Active-Active
```bash
az network vnet-gateway update \
  -g rg-vpn-s2s-demo \
  -n vng-azure \
  --active-active true
```

### 6. BGP Not Working

**Symptoms:**
- BGP peers not establishing
- Routes not being learned

**Solutions:**

#### A. Verify BGP Configuration
```bash
# Check BGP settings
az network vnet-gateway show \
  -g rg-vpn-s2s-demo \
  -n vng-azure \
  --query bgpSettings
```

#### B. Check BGP Peer Status
```bash
# View learned routes
az network vnet-gateway list-learned-routes \
  -g rg-vpn-s2s-demo \
  -n vng-azure \
  --output table

# View advertised routes
az network vnet-gateway list-advertised-routes \
  -g rg-vpn-s2s-demo \
  -n vng-azure \
  --peer {bgp-peer-ip} \
  --output table
```

### 7. Cost Exceeds Budget

**Symptoms:**
- Unexpected high costs

**Solutions:**

#### A. Deallocate VMs When Not in Use
```bash
# Stop and deallocate VM
az vm deallocate -g rg-vpn-s2s-demo -n vm-onprem
az vm deallocate -g rg-vpn-s2s-demo -n vm-azure

# Start when needed
az vm start -g rg-vpn-s2s-demo -n vm-onprem
```

#### B. Use Basic SKU for Testing
- Already using Basic SKU in this lab
- Downgrade from VpnGw SKUs if not needed

#### C. Delete Resources When Not Needed
```bash
# Run cleanup script
./cleanup.sh
```

## Diagnostic Commands

### Comprehensive Health Check Script

```bash
#!/bin/bash

RG="rg-vpn-s2s-demo"

echo "=== VPN Gateway Status ==="
az network vnet-gateway show -g $RG -n vng-azure --query provisioningState
az network vnet-gateway show -g $RG -n vng-onprem --query provisioningState

echo "=== VPN Connection Status ==="
az network vpn-connection show -g $RG -n conn-onprem-to-azure --query connectionStatus

echo "=== VM Status ==="
az vm get-instance-view -g $RG -n vm-onprem --query instanceView.statuses[1].displayStatus
az vm get-instance-view -g $RG -n vm-azure --query instanceView.statuses[1].displayStatus

echo "=== Public IPs ==="
echo "OnPrem Gateway: $(az network public-ip show -g $RG -n pip-vng-onprem --query ipAddress -o tsv)"
echo "Azure Gateway: $(az network public-ip show -g $RG -n pip-vng-azure --query ipAddress -o tsv)"
echo "OnPrem VM: $(az network public-ip show -g $RG -n pip-vm-onprem --query ipAddress -o tsv)"
echo "Azure VM: $(az network public-ip show -g $RG -n pip-vm-azure --query ipAddress -o tsv)"
```

### Enable Diagnostics

```bash
# Create Log Analytics workspace
az monitor log-analytics workspace create \
  -g rg-vpn-s2s-demo \
  -n law-vpn-demo

# Get workspace ID
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  -g rg-vpn-s2s-demo \
  -n law-vpn-demo \
  --query id -o tsv)

# Enable diagnostics on gateway
az monitor diagnostic-settings create \
  -n diag-vng-azure \
  --resource $(az network vnet-gateway show -g rg-vpn-s2s-demo -n vng-azure --query id -o tsv) \
  --workspace $WORKSPACE_ID \
  --logs '[{"category":"GatewayDiagnosticLog","enabled":true},{"category":"TunnelDiagnosticLog","enabled":true},{"category":"RouteDiagnosticLog","enabled":true},{"category":"IKEDiagnosticLog","enabled":true}]' \
  --metrics '[{"category":"AllMetrics","enabled":true}]'
```

## Getting Help

If you continue to experience issues:

1. **Check Azure Service Health:**
   - Visit: https://status.azure.com/

2. **Review Azure VPN Gateway Documentation:**
   - https://docs.microsoft.com/azure/vpn-gateway/

3. **Open Support Ticket:**
   - Azure Portal → Help + Support → New support request

4. **Community Resources:**
   - Microsoft Q&A: https://docs.microsoft.com/answers/
   - Stack Overflow: https://stackoverflow.com/questions/tagged/azure-vpn-gateway

5. **Reset Gateway as Last Resort:**
   ```bash
   # This will cause brief downtime
   az network vnet-gateway reset -g rg-vpn-s2s-demo -n vng-azure
   ```
