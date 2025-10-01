# VPN Site-to-Site Demo Lab - Cheat Sheet

## Network Information

| Network | CIDR | Purpose |
|---------|------|---------|
| On-Prem VNet | 192.168.1.0/24 | Simulated on-premises |
| On-Prem Subnet | 192.168.1.0/27 | Workloads |
| On-Prem Gateway | 192.168.1.224/27 | VPN Gateway |
| Azure VNet | 10.100.0.0/22 | Azure workloads |
| Azure Subnet | 10.100.0.0/24 | Workloads |
| Azure Gateway | 10.100.3.224/27 | VPN Gateway |

## Quick Commands

### Deploy
```bash
./deploy.sh
```

### Status Check
```bash
# Connection status
az network vpn-connection show -g rg-vpn-s2s-demo -n conn-onprem-to-azure --query connectionStatus

# Gateway status  
az network vnet-gateway show -g rg-vpn-s2s-demo -n vng-azure --query provisioningState
az network vnet-gateway show -g rg-vpn-s2s-demo -n vng-onprem --query provisioningState
```

### Get IPs
```bash
# VM Public IPs
az network public-ip show -g rg-vpn-s2s-demo -n pip-vm-onprem --query ipAddress -o tsv
az network public-ip show -g rg-vpn-s2s-demo -n pip-vm-azure --query ipAddress -o tsv

# VM Private IPs
az vm show -g rg-vpn-s2s-demo -n vm-onprem -d --query privateIps -o tsv
az vm show -g rg-vpn-s2s-demo -n vm-azure -d --query privateIps -o tsv
```

### Test Connectivity
```bash
# SSH and ping
ssh azureuser@<onprem-public-ip>
ping <azure-private-ip>
```

### VM Management
```bash
# Stop (no compute cost)
az vm deallocate -g rg-vpn-s2s-demo -n vm-onprem
az vm deallocate -g rg-vpn-s2s-demo -n vm-azure

# Start
az vm start -g rg-vpn-s2s-demo -n vm-onprem
az vm start -g rg-vpn-s2s-demo -n vm-azure
```

### Cleanup
```bash
./cleanup.sh
# OR
az group delete --name rg-vpn-s2s-demo --yes --no-wait
```

## Resource Names

| Type | Name |
|------|------|
| Resource Group | rg-vpn-s2s-demo |
| On-Prem VNet | vnet-onprem |
| Azure VNet | vnet-azure |
| On-Prem Gateway | vng-onprem |
| Azure Gateway | vng-azure |
| Connection | conn-onprem-to-azure |
| On-Prem VM | vm-onprem |
| Azure VM | vm-azure |

## Deployment Time

| Phase | Duration |
|-------|----------|
| VPN Gateways | 30-45 min |
| Other Resources | 5-10 min |
| **Total** | **~45-50 min** |

## Monthly Cost (East US)

| SKU | Gateway Cost | VM Cost | Total |
|-----|-------------|---------|-------|
| Basic | ~$54 | ~$60 | **~$129** |
| VpnGw1 | ~$280 | ~$60 | **~$355** |

*Plus ~$15/month for Public IPs*

## Common Tasks

### Update Shared Key
```bash
az network vpn-connection shared-key update \
  -g rg-vpn-s2s-demo \
  -n conn-onprem-to-azure \
  --value "NewKey123!"
```

### Upgrade Gateway
```bash
az network vnet-gateway update \
  -g rg-vpn-s2s-demo \
  -n vng-azure \
  --sku VpnGw1
```

### Enable BGP
```bash
az network vnet-gateway update \
  -g rg-vpn-s2s-demo \
  -n vng-azure \
  --asn 65002 \
  --bgp-peering-address 10.100.3.254
```

### Reset Gateway
```bash
az network vnet-gateway reset \
  -g rg-vpn-s2s-demo \
  -n vng-azure
```

### View Metrics
```bash
az network vpn-connection show \
  -g rg-vpn-s2s-demo \
  -n conn-onprem-to-azure \
  --query '{status:connectionStatus, in:ingressBytesTransferred, out:egressBytesTransferred}'
```

## Troubleshooting

### Check List
- [ ] Both gateways show "Succeeded" status
- [ ] Connection shows "Connected" status
- [ ] NSG allows SSH (22) and ICMP
- [ ] VM firewalls allow traffic
- [ ] Routes are correct

### Quick Diagnostics
```bash
# Effective routes
az network nic show-effective-route-table \
  -g rg-vpn-s2s-demo \
  -n nic-vm-onprem --output table

# NSG rules
az network nsg rule list \
  -g rg-vpn-s2s-demo \
  --nsg-name nsg-onprem --output table

# Gateway details
az network vnet-gateway show \
  -g rg-vpn-s2s-demo \
  -n vng-azure --output table
```

## IPSec Settings (Default)

| Parameter | Value |
|-----------|-------|
| IKE Encryption | AES256 |
| IKE Integrity | SHA256 |
| DH Group | DHGroup2 |
| IPSec Encryption | AES256 |
| IPSec Integrity | SHA256 |
| PFS Group | None |
| SA Lifetime | 27000 sec |

## Ports Required

| Protocol | Port | Purpose |
|----------|------|---------|
| UDP | 500 | IKE |
| UDP | 4500 | NAT-T |
| ESP | 50 | IPSec |

## Portal Links

### Resource Group
```
portal.azure.com → Resource Groups → rg-vpn-s2s-demo
```

### VPN Gateways
```
portal.azure.com → Virtual Network Gateways → vng-azure
```

### Monitor
```
portal.azure.com → Monitor → Metrics → Select VPN Gateway
```

## Documentation Links

- [README](README.md) - Full documentation
- [Getting Started](getting-started.md) - Step-by-step guide
- [Architecture](architecture.md) - Visual diagrams
- [Troubleshooting](troubleshooting.md) - Problem solving
- [Config Snippets](configuration-snippets.md) - Advanced configs

## Support

- **Azure Docs**: docs.microsoft.com/azure/vpn-gateway/
- **Q&A**: docs.microsoft.com/answers/
- **Issues**: github.com/WapoInc/azure-networking/issues

---

**Pro Tip**: Bookmark this page for quick reference! 📌
