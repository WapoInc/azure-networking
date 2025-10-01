# Architecture Diagram - VPN Site-to-Site Demo Lab

## Network Topology

```
                             INTERNET
                                |
                                |
        ┌───────────────────────┴───────────────────────┐
        |                                               |
        |                                               |
   ┌────▼────┐                                    ┌────▼────┐
   │ Public  │                                    │ Public  │
   │   IP    │                                    │   IP    │
   └────┬────┘                                    └────┬────┘
        |                                               |
┌───────┴────────────────────┐         ┌───────────────┴──────────────┐
│                            │         │                              │
│    ON-PREMISES VNET        │         │        AZURE VNET            │
│    192.168.1.0/24          │         │       10.100.0.0/22          │
│                            │         │                              │
│  ┌──────────────────────┐  │         │  ┌──────────────────────┐   │
│  │                      │  │         │  │                      │   │
│  │  Gateway Subnet      │  │         │  │  Gateway Subnet      │   │
│  │  192.168.1.224/27    │  │         │  │  10.100.3.224/27     │   │
│  │                      │  │         │  │                      │   │
│  │  ┌────────────────┐  │  │         │  │  ┌────────────────┐  │   │
│  │  │                │  │  │         │  │  │                │  │   │
│  │  │  VPN Gateway   │◄─┼──┼─────────┼──┼──►│  VPN Gateway   │  │   │
│  │  │   vng-onprem   │  │  │  IPSec  │  │  │   vng-azure    │  │   │
│  │  │                │  │  │  Tunnel │  │  │                │  │   │
│  │  └────────────────┘  │  │         │  │  └────────────────┘  │   │
│  │                      │  │         │  │                      │   │
│  └──────────────────────┘  │         │  └──────────────────────┘   │
│                            │         │                              │
│  ┌──────────────────────┐  │         │  ┌──────────────────────┐   │
│  │                      │  │         │  │                      │   │
│  │  Default Subnet      │  │         │  │  Default Subnet      │   │
│  │  192.168.1.0/27      │  │         │  │  10.100.0.0/24       │   │
│  │                      │  │         │  │                      │   │
│  │  ┌────────────────┐  │  │         │  │  ┌────────────────┐  │   │
│  │  │                │  │  │         │  │  │                │  │   │
│  │  │   Test VM      │  │  │         │  │  │   Test VM      │  │   │
│  │  │   vm-onprem    │  │  │         │  │  │   vm-azure     │  │   │
│  │  │  Ubuntu 20.04  │  │  │         │  │  │  Ubuntu 20.04  │  │   │
│  │  │                │  │  │         │  │  │                │  │   │
│  │  └────────────────┘  │  │         │  │  └────────────────┘  │   │
│  │                      │  │         │  │                      │   │
│  └──────────────────────┘  │         │  └──────────────────────┘   │
│                            │         │                              │
└────────────────────────────┘         └──────────────────────────────┘
```

## Traffic Flow

### VM to VM Communication

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│              │      │              │      │              │      │              │
│  vm-onprem   │─────▶│ VNG-onprem   │─────▶│ VNG-azure    │─────▶│  vm-azure    │
│ 192.168.1.x  │      │              │      │              │      │ 10.100.0.x   │
│              │      │              │      │              │      │              │
└──────────────┘      └──────────────┘      └──────────────┘      └──────────────┘
                              │                     │
                              │   IPSec Tunnel     │
                              └─────────────────────┘
                                 Encrypted over
                                   Internet
```

## Component Details

### VPN Gateways

```
┌─────────────────────────────────────────────┐
│         VPN Gateway Configuration           │
├─────────────────────────────────────────────┤
│                                             │
│  Type:           Route-based                │
│  SKU:            Basic (or VpnGw1-5)        │
│  IKE Version:    IKEv2                      │
│  Protocol:       IPSec                      │
│  BGP:            Optional                   │
│  Active-Active:  Optional                   │
│                                             │
└─────────────────────────────────────────────┘
```

### IPSec Tunnel Parameters

```
┌─────────────────────────────────────────────┐
│         IPSec Tunnel Settings               │
├─────────────────────────────────────────────┤
│                                             │
│  Phase 1 (IKE):                             │
│    Encryption:  AES256                      │
│    Integrity:   SHA256                      │
│    DH Group:    DHGroup2                    │
│    SA Lifetime: 28800 seconds               │
│                                             │
│  Phase 2 (IPSec):                           │
│    Encryption:  AES256                      │
│    Integrity:   SHA256                      │
│    PFS Group:   None                        │
│    SA Lifetime: 27000 seconds               │
│                                             │
│  Shared Key:    User-defined (secure)       │
│                                             │
└─────────────────────────────────────────────┘
```

## Network Address Space

```
┌─────────────────────┬──────────────────┬─────────────────────────┐
│ Component           │ Address Space    │ Purpose                 │
├─────────────────────┼──────────────────┼─────────────────────────┤
│ On-Prem VNet        │ 192.168.1.0/24   │ Simulated on-premises   │
│ On-Prem Subnet      │ 192.168.1.0/27   │ Workload/VM subnet      │
│ On-Prem GW Subnet   │ 192.168.1.224/27 │ VPN Gateway subnet      │
├─────────────────────┼──────────────────┼─────────────────────────┤
│ Azure VNet          │ 10.100.0.0/22    │ Azure workload VNet     │
│ Azure Subnet        │ 10.100.0.0/24    │ Workload/VM subnet      │
│ Azure GW Subnet     │ 10.100.3.224/27  │ VPN Gateway subnet      │
└─────────────────────┴──────────────────┴─────────────────────────┘
```

## Deployment Flow

```
Step 1: Create Resource Group
    ↓
Step 2: Deploy Virtual Networks
    ├── On-Premises VNet (192.168.1.0/24)
    │   ├── Default Subnet
    │   └── Gateway Subnet
    │
    └── Azure VNet (10.100.0.0/22)
        ├── Default Subnet
        └── Gateway Subnet
    ↓
Step 3: Create Public IPs
    ├── On-Prem Gateway Public IP
    └── Azure Gateway Public IP
    ↓
Step 4: Deploy VPN Gateways (30-45 min)
    ├── On-Premises Gateway
    └── Azure Gateway
    ↓
Step 5: Create VPN Connection
    └── IPSec Tunnel (Vnet2Vnet)
    ↓
Step 6: Deploy Test VMs (Optional)
    ├── On-Prem VM
    └── Azure VM
    ↓
Step 7: Verify Connectivity
    └── Ping test between VMs
```

## Routing

### Default Routing (without BGP)

```
On-Premises VNet Routing:
┌────────────────────┬──────────────────┬─────────────┐
│ Destination        │ Next Hop         │ Route Type  │
├────────────────────┼──────────────────┼─────────────┤
│ 192.168.1.0/24     │ VNet             │ System      │
│ 10.100.0.0/22      │ VPN Gateway      │ VNet Gateway│
└────────────────────┴──────────────────┴─────────────┘

Azure VNet Routing:
┌────────────────────┬──────────────────┬─────────────┐
│ Destination        │ Next Hop         │ Route Type  │
├────────────────────┼──────────────────┼─────────────┤
│ 10.100.0.0/22      │ VNet             │ System      │
│ 192.168.1.0/24     │ VPN Gateway      │ VNet Gateway│
└────────────────────┴──────────────────┴─────────────┘
```

## Security

### Network Security Groups (NSGs)

```
┌──────────────────────────────────────────────┐
│         NSG Rules (Both Subnets)             │
├──────────────────────────────────────────────┤
│                                              │
│  Priority 1000: Allow SSH (TCP 22)          │
│    Direction:  Inbound                       │
│    Source:     Any                           │
│    Dest:       Any                           │
│                                              │
│  Priority 1001: Allow ICMP (Ping)           │
│    Direction:  Inbound                       │
│    Protocol:   ICMP                          │
│    Source:     Any                           │
│    Dest:       Any                           │
│                                              │
└──────────────────────────────────────────────┘
```

### VPN Gateway Security

```
┌──────────────────────────────────────────────┐
│         VPN Gateway Security                 │
├──────────────────────────────────────────────┤
│                                              │
│  ✓ Traffic encrypted in tunnel (IPSec)      │
│  ✓ Shared key authentication                │
│  ✓ IKEv2 protocol                            │
│  ✓ Strong encryption (AES256)               │
│  ✓ SHA256 integrity checking                │
│  ✓ Optional: Custom IPSec policies          │
│  ✓ Optional: BGP for dynamic routing        │
│                                              │
└──────────────────────────────────────────────┘
```

## Use Cases

This demo lab is suitable for:

1. **Learning Azure VPN Gateway** - Understand how Site-to-Site VPN works
2. **Hybrid Connectivity** - Simulate on-premises to Azure connection
3. **Testing Applications** - Test hybrid scenarios before production
4. **Training and Demos** - Hands-on training for teams
5. **POC Development** - Proof of concept for hybrid architectures

## Next Steps

After mastering this basic setup, you can extend it with:

- **BGP** - Dynamic routing between sites
- **Active-Active Gateways** - High availability configuration
- **Multiple Sites** - Connect more locations
- **Azure Firewall** - Centralized security filtering
- **ExpressRoute** - Add dedicated connectivity alongside VPN
- **Azure Route Server** - Advanced routing scenarios
- **Network Virtual Appliances** - Third-party NVAs for additional features

## References

- [Azure VPN Gateway Documentation](https://docs.microsoft.com/azure/vpn-gateway/)
- [Hub-Spoke Network Topology](../../README.md#azure-hub-spoke-design)
- [Azure Networking Best Practices](https://docs.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/)
