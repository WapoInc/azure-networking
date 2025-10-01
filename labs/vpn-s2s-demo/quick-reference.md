# Quick Reference - VPN S2S Demo Lab

## Network Configuration

| Component | CIDR / Address |
|-----------|---------------|
| On-Premises VNet | 192.168.1.0/24 |
| On-Premises Default Subnet | 192.168.1.0/27 |
| On-Premises Gateway Subnet | 192.168.1.224/27 |
| Azure VNet | 10.100.0.0/22 |
| Azure Default Subnet | 10.100.0.0/24 |
| Azure Gateway Subnet | 10.100.3.224/27 |

## Resource Names

| Resource Type | Name |
|--------------|------|
| On-Premises VNet | vnet-onprem |
| Azure VNet | vnet-azure |
| On-Premises Gateway | vng-onprem |
| Azure Gateway | vng-azure |
| VPN Connection | conn-onprem-to-azure |
| On-Premises VM | vm-onprem |
| Azure VM | vm-azure |

## Quick Commands

### Deploy
```bash
./deploy.sh
```

### Check Status
```bash
az network vpn-connection show \
  -g rg-vpn-s2s-demo \
  -n conn-onprem-to-azure \
  --query connectionStatus
```

### Get IPs
```bash
# Gateway IPs
az network public-ip show -g rg-vpn-s2s-demo -n pip-vng-onprem --query ipAddress -o tsv
az network public-ip show -g rg-vpn-s2s-demo -n pip-vng-azure --query ipAddress -o tsv

# VM IPs
az network public-ip show -g rg-vpn-s2s-demo -n pip-vm-onprem --query ipAddress -o tsv
az network public-ip show -g rg-vpn-s2s-demo -n pip-vm-azure --query ipAddress -o tsv
```

### Cleanup
```bash
./cleanup.sh
```

## Default Settings

| Setting | Value |
|---------|-------|
| Gateway SKU | Basic |
| VPN Type | RouteBased |
| IKE Version | IKEv2 |
| Shared Key | Azure12345678 |
| Admin Username | azureuser |
| VM Size | Standard_B2s |
| VM OS | Ubuntu 20.04 LTS |

## Port Requirements

| Protocol | Port | Purpose |
|----------|------|---------|
| UDP | 500 | IKE |
| UDP | 4500 | IKE NAT-T |
| ESP | 50 | IPSec |
| AH | 51 | IPSec (optional) |

## Deployment Timeline

| Phase | Duration |
|-------|----------|
| VNets & Subnets | 2 min |
| Public IPs | 1 min |
| VPN Gateways | 30-45 min |
| VPN Connection | 5 min |
| Test VMs | 5 min |
| **Total** | **~45-50 min** |

## Cost Estimate (Monthly - East US)

| Resource | Basic SKU | VpnGw1 SKU |
|----------|-----------|------------|
| VPN Gateway (x2) | $54 | $280 |
| VMs (B2s x2) | $60 | $60 |
| Public IPs (x4) | $15 | $15 |
| **Total** | **~$129** | **~$355** |

## Useful Azure Portal Links

### Resource Group
```
https://portal.azure.com/#@<tenant>/resource/subscriptions/<subscription-id>/resourceGroups/rg-vpn-s2s-demo
```

### VPN Gateways
```
https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Network%2FvirtualNetworkGateways
```

### Connections
```
https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Network%2Fconnections
```

## Testing Checklist

- [ ] Both VPN gateways provisioned (Succeeded state)
- [ ] VPN connection status shows "Connected"
- [ ] Can SSH to both VMs
- [ ] Can ping between VMs via private IPs
- [ ] Can SSH from one VM to another via private IP
- [ ] Gateway metrics show traffic flowing
- [ ] BGP routes learned (if BGP enabled)

## Common Tasks

### Reset Connection
```bash
az network vpn-connection reset \
  -g rg-vpn-s2s-demo \
  -n conn-onprem-to-azure
```

### Update Shared Key
```bash
az network vpn-connection shared-key update \
  -g rg-vpn-s2s-demo \
  -n conn-onprem-to-azure \
  --value "NewSharedKey123!"
```

### Scale Gateway
```bash
az network vnet-gateway update \
  -g rg-vpn-s2s-demo \
  -n vng-azure \
  --sku VpnGw1
```

### VM Operations
```bash
# Stop VM (still incurs costs)
az vm stop -g rg-vpn-s2s-demo -n vm-onprem

# Deallocate VM (no compute costs)
az vm deallocate -g rg-vpn-s2s-demo -n vm-onprem

# Start VM
az vm start -g rg-vpn-s2s-demo -n vm-onprem

# Restart VM
az vm restart -g rg-vpn-s2s-demo -n vm-onprem
```

## Troubleshooting Quick Checks

```bash
# 1. Check gateway status
az network vnet-gateway show -g rg-vpn-s2s-demo -n vng-azure --query provisioningState

# 2. Check connection status
az network vpn-connection show -g rg-vpn-s2s-demo -n conn-onprem-to-azure --query connectionStatus

# 3. Check VM status
az vm get-instance-view -g rg-vpn-s2s-demo -n vm-onprem --query instanceView.statuses[1].displayStatus

# 4. Check NSG rules
az network nsg rule list -g rg-vpn-s2s-demo --nsg-name nsg-onprem --output table

# 5. Check effective routes
az network nic show-effective-route-table -g rg-vpn-s2s-demo -n nic-vm-onprem --output table
```

## Next Steps After Lab

1. **Enable BGP** for dynamic routing
2. **Add more sites** for multi-site VPN
3. **Implement Azure Firewall** for centralized filtering
4. **Set up Azure Route Server** for advanced routing
5. **Configure custom IPSec policies** for specific requirements
6. **Add ExpressRoute** alongside VPN for redundancy
7. **Implement Network Watcher** for monitoring
8. **Set up alerts** for connection failures

## Related Resources

- [Main README](README.md)
- [Configuration Snippets](configuration-snippets.md)
- [Troubleshooting Guide](troubleshooting.md)
- [Azure Hub-Spoke Design](../../README.md#azure-hub-spoke-design)
