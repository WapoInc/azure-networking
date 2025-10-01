# VPN Gateway Configuration Snippets

## VPN Connection Status Check

### Using Azure CLI
```bash
# Check connection status
az network vpn-connection show \
  --resource-group rg-vpn-s2s-demo \
  --name conn-onprem-to-azure \
  --query '{Name:name, Status:connectionStatus, IngressBytes:ingressBytesTransferred, EgressBytes:egressBytesTransferred}' \
  --output table

# List all connections
az network vpn-connection list \
  --resource-group rg-vpn-s2s-demo \
  --output table
```

### Using PowerShell
```powershell
# Check connection status
Get-AzVirtualNetworkGatewayConnection `
  -Name conn-onprem-to-azure `
  -ResourceGroupName rg-vpn-s2s-demo

# Get detailed status
Get-AzVirtualNetworkGatewayConnectionSharedKey `
  -Name conn-onprem-to-azure `
  -ResourceGroupName rg-vpn-s2s-demo
```

## Custom IPSec/IKE Policy

If you need to configure custom IPSec/IKE policies:

### Azure CLI
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

### PowerShell
```powershell
$ipsecpolicy = New-AzIpsecPolicy `
  -IkeEncryption AES256 `
  -IkeIntegrity SHA384 `
  -DhGroup DHGroup24 `
  -IpsecEncryption GCMAES256 `
  -IpsecIntegrity GCMAES256 `
  -PfsGroup PFS24 `
  -SALifeTimeSeconds 27000 `
  -SADataSizeKilobytes 102400000

Set-AzVirtualNetworkGatewayConnection `
  -VirtualNetworkGatewayConnection $connection `
  -IpsecPolicies $ipsecpolicy
```

## BGP Configuration

To enable BGP after deployment:

### Azure CLI
```bash
# Update On-Premises Gateway with BGP
az network vnet-gateway update \
  --resource-group rg-vpn-s2s-demo \
  --name vng-onprem \
  --asn 65001 \
  --bgp-peering-address 192.168.1.254

# Update Azure Gateway with BGP
az network vnet-gateway update \
  --resource-group rg-vpn-s2s-demo \
  --name vng-azure \
  --asn 65002 \
  --bgp-peering-address 10.100.3.254

# Enable BGP on connection
az network vpn-connection update \
  --resource-group rg-vpn-s2s-demo \
  --name conn-onprem-to-azure \
  --enable-bgp true
```

## Monitoring Commands

### Check Gateway Status
```bash
# Get gateway details
az network vnet-gateway show \
  --resource-group rg-vpn-s2s-demo \
  --name vng-azure \
  --query '{Name:name, State:provisioningState, SKU:sku.name, Type:vpnType}' \
  --output table

# Check gateway health
az network vnet-gateway list \
  --resource-group rg-vpn-s2s-demo \
  --output table
```

### View Metrics
```bash
# Get gateway metrics (requires Azure Monitor)
az monitor metrics list \
  --resource /subscriptions/{subscription-id}/resourceGroups/rg-vpn-s2s-demo/providers/Microsoft.Network/virtualNetworkGateways/vng-azure \
  --metric "TunnelIngressBytes" \
  --start-time 2023-01-01T00:00:00Z \
  --end-time 2023-12-31T23:59:59Z \
  --interval PT5M
```

## Route Table Configuration

### Add User Defined Routes (UDR)
```bash
# Create route table
az network route-table create \
  --resource-group rg-vpn-s2s-demo \
  --name rt-onprem

# Add route to Azure VNet
az network route-table route create \
  --resource-group rg-vpn-s2s-demo \
  --route-table-name rt-onprem \
  --name route-to-azure \
  --address-prefix 10.100.0.0/22 \
  --next-hop-type VirtualNetworkGateway

# Associate route table with subnet
az network vnet subnet update \
  --resource-group rg-vpn-s2s-demo \
  --vnet-name vnet-onprem \
  --name subnet-default \
  --route-table rt-onprem
```

## Troubleshooting Commands

### Reset VPN Gateway
```bash
# Reset the gateway (causes brief downtime)
az network vnet-gateway reset \
  --resource-group rg-vpn-s2s-demo \
  --name vng-azure
```

### View Connection Logs
```bash
# Enable diagnostics
az monitor diagnostic-settings create \
  --resource /subscriptions/{subscription-id}/resourceGroups/rg-vpn-s2s-demo/providers/Microsoft.Network/virtualNetworkGateways/vng-azure \
  --name diag-vng-azure \
  --workspace {log-analytics-workspace-id} \
  --logs '[{"category": "GatewayDiagnosticLog", "enabled": true}]' \
  --metrics '[{"category": "AllMetrics", "enabled": true}]'
```

### Packet Capture
```bash
# Start packet capture on gateway
az network vnet-gateway packet-capture start \
  --resource-group rg-vpn-s2s-demo \
  --name vng-azure

# Stop packet capture
az network vnet-gateway packet-capture stop \
  --resource-group rg-vpn-s2s-demo \
  --name vng-azure \
  --sas-url "{storage-account-sas-url}"
```

## VM Network Testing

### On the VMs - Test Connectivity

```bash
# SSH to VM
ssh azureuser@{vm-public-ip}

# Test network connectivity
ping {remote-vm-private-ip}

# Check routes
ip route show

# Test specific ports
nc -zv {remote-vm-private-ip} 22

# Trace route
traceroute {remote-vm-private-ip}

# Install network tools
sudo apt-get update
sudo apt-get install -y traceroute netcat tcpdump

# Capture packets
sudo tcpdump -i eth0 -w capture.pcap
```

## Performance Testing

### Test VPN throughput
```bash
# On receiving VM - start iperf server
iperf3 -s

# On sending VM - run iperf client
iperf3 -c {remote-vm-private-ip} -t 60 -P 10
```

## Scaling the Gateway

### Resize Gateway SKU
```bash
az network vnet-gateway update \
  --resource-group rg-vpn-s2s-demo \
  --name vng-azure \
  --sku VpnGw1
```

### Enable Active-Active Mode
```bash
az network vnet-gateway update \
  --resource-group rg-vpn-s2s-demo \
  --name vng-azure \
  --active-active true
```

## Export Configuration

### Export ARM Template
```bash
az group export \
  --resource-group rg-vpn-s2s-demo \
  --output json > exported-template.json
```

### Backup Configuration
```bash
# List all resources
az resource list \
  --resource-group rg-vpn-s2s-demo \
  --output table > resource-list.txt

# Export connection details
az network vpn-connection show \
  --resource-group rg-vpn-s2s-demo \
  --name conn-onprem-to-azure \
  --output json > connection-config.json
```
