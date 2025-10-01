# VPN Site-to-Site Demo Lab - Index

Welcome to the VPN Site-to-Site Demo Lab! This index will help you navigate through all the available documentation.

## 🚀 Start Here

New to Azure VPN Gateway? Start with the Getting Started guide:

**→ [Getting Started Guide](getting-started.md)**

This will walk you through:
- Prerequisites
- Step-by-step deployment
- Testing connectivity
- Your first exercises

## 📖 Documentation

### Core Documentation

| Document | Description | When to Use |
|----------|-------------|-------------|
| [README.md](README.md) | Main documentation with deployment options | First read, comprehensive reference |
| [Getting Started](getting-started.md) | Step-by-step beginner guide | If you're new to Azure VPN |
| [Architecture](architecture.md) | Visual diagrams and architecture details | Understanding the design |
| [Quick Reference](quick-reference.md) | Cheat sheet with common commands | Quick lookups during work |

### Operational Guides

| Document | Description | When to Use |
|----------|-------------|-------------|
| [Configuration Snippets](configuration-snippets.md) | Useful CLI commands and PowerShell scripts | Customizing and managing the lab |
| [Troubleshooting Guide](troubleshooting.md) | Solutions to common problems | When things don't work as expected |

## 🛠️ Scripts and Templates

### Deployment Files

| File | Type | Purpose |
|------|------|---------|
| `main.bicep` | Bicep Template | Infrastructure as Code (IaC) definition |
| `main.json` | ARM Template | Auto-generated from Bicep |
| `main.parameters.json` | Parameters File | Example parameter values |
| `deploy.sh` | Bash Script | Automated deployment script |
| `cleanup.sh` | Bash Script | Resource cleanup script |

## 🎯 Learning Paths

### Path 1: Beginner (New to Azure VPN)

1. Read [Getting Started Guide](getting-started.md)
2. Review [Architecture Diagram](architecture.md)
3. Deploy using [deploy.sh](deploy.sh)
4. Follow testing steps in Getting Started
5. Use [Quick Reference](quick-reference.md) as needed

**Time Required:** 1-2 hours (including deployment wait time)

### Path 2: Intermediate (Some Azure Experience)

1. Skim [README.md](README.md)
2. Review [Architecture](architecture.md)
3. Deploy directly with Azure CLI
4. Explore [Configuration Snippets](configuration-snippets.md)
5. Try customization exercises

**Time Required:** 1 hour

### Path 3: Advanced (Experienced with Azure)

1. Review [Architecture](architecture.md) for design patterns
2. Inspect `main.bicep` template
3. Deploy with custom parameters
4. Implement advanced scenarios (BGP, custom IPSec policies)
5. Extend the lab for your use case

**Time Required:** 30-45 minutes

## 📋 Quick Actions

### Deploy the Lab

```bash
# Clone repository
git clone https://github.com/WapoInc/azure-networking.git
cd azure-networking/labs/vpn-s2s-demo

# Deploy with script
chmod +x deploy.sh
./deploy.sh

# OR deploy with Azure CLI
az group create --name rg-vpn-s2s-demo --location eastus
az deployment group create \
  --resource-group rg-vpn-s2s-demo \
  --template-file main.bicep \
  --parameters adminUsername=azureuser adminPassword='YourP@ssw0rd123!' sharedKey='YourKey123!'
```

### Check Status

```bash
# Check VPN connection
az network vpn-connection show \
  -g rg-vpn-s2s-demo \
  -n conn-onprem-to-azure \
  --query connectionStatus

# Get VM IPs
az vm show -g rg-vpn-s2s-demo -n vm-onprem -d --query publicIps -o tsv
az vm show -g rg-vpn-s2s-demo -n vm-azure -d --query publicIps -o tsv
```

### Clean Up

```bash
# Run cleanup script
./cleanup.sh

# OR use Azure CLI
az group delete --name rg-vpn-s2s-demo --yes --no-wait
```

## 🎓 Learning Objectives

After completing this lab, you will be able to:

- ✅ Deploy Azure VPN Gateways using Infrastructure as Code
- ✅ Configure Site-to-Site IPSec VPN tunnels
- ✅ Understand hybrid network architecture
- ✅ Test and validate VPN connectivity
- ✅ Monitor VPN gateway performance and health
- ✅ Troubleshoot common VPN connection issues
- ✅ Customize VPN configurations (BGP, IPSec policies, etc.)
- ✅ Estimate and manage costs for VPN deployments

## 🔗 Related Resources

### Within This Repository

- [Hub-Spoke Network Design](../../README.md#azure-hub-spoke-design)
- [vWAN Architecture](../../README.md#vwan-azure-virtual-wan)
- [Azure Networking Diagrams](../../diagrams/)

### External Resources

- [Azure VPN Gateway Documentation](https://docs.microsoft.com/azure/vpn-gateway/)
- [Site-to-Site VPN Tutorial](https://docs.microsoft.com/azure/vpn-gateway/vpn-gateway-howto-site-to-site-resource-manager-portal)
- [VPN Gateway Design](https://docs.microsoft.com/azure/vpn-gateway/design)
- [VPN Gateway Pricing](https://azure.microsoft.com/pricing/details/vpn-gateway/)
- [Azure Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)

## 💡 Use Cases

This lab demonstrates patterns applicable to:

### Production Scenarios

1. **Hybrid Cloud Connectivity**
   - Connect on-premises datacenter to Azure
   - Extend corporate network to cloud
   - Enable secure remote access

2. **Multi-Cloud Networking**
   - Connect Azure to other cloud providers
   - Build cross-cloud architectures
   - Implement cloud exit strategies

3. **Disaster Recovery**
   - Replicate data to Azure for DR
   - Implement backup connectivity
   - Test failover scenarios

4. **Development and Testing**
   - Extend dev/test environments to cloud
   - Test hybrid applications
   - Validate network configurations

### Learning Scenarios

1. **Azure Certification Preparation**
   - AZ-104: Azure Administrator
   - AZ-305: Azure Solutions Architect
   - AZ-700: Azure Network Engineer

2. **Hands-on Training**
   - Team training workshops
   - Customer demonstrations
   - POC development

## 📊 Lab Components Overview

### Infrastructure Components

```
Resource Group: rg-vpn-s2s-demo
├── Virtual Networks (2)
│   ├── vnet-onprem (192.168.1.0/24)
│   └── vnet-azure (10.100.0.0/22)
├── VPN Gateways (2)
│   ├── vng-onprem
│   └── vng-azure
├── VPN Connection (1)
│   └── conn-onprem-to-azure
├── Virtual Machines (2, optional)
│   ├── vm-onprem
│   └── vm-azure
├── Public IP Addresses (4)
├── Network Interfaces (2, if VMs deployed)
└── Network Security Groups (2, if VMs deployed)
```

### Cost Breakdown

| Component | Monthly Cost (Basic) | Monthly Cost (VpnGw1) |
|-----------|---------------------|----------------------|
| VPN Gateways (x2) | ~$54 | ~$280 |
| Virtual Machines (x2) | ~$60 | ~$60 |
| Public IPs (x4) | ~$15 | ~$15 |
| **Total** | **~$129** | **~$355** |

*Prices are estimates for East US region and may vary.*

## 🤝 Contributing

Found an issue or have an improvement? Contributions are welcome!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

Need help? Here's how to get support:

1. **Check Documentation**
   - Review [Troubleshooting Guide](troubleshooting.md)
   - Check [Configuration Snippets](configuration-snippets.md)

2. **Community Support**
   - [Microsoft Q&A](https://docs.microsoft.com/answers/)
   - [Stack Overflow](https://stackoverflow.com/questions/tagged/azure-vpn-gateway)

3. **Official Support**
   - [Azure Support Plans](https://azure.microsoft.com/support/plans/)
   - [Open Support Ticket](https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade)

## 📝 License

This lab is part of the azure-networking repository. Please refer to the repository license for usage terms.

## 🙏 Acknowledgments

This lab was created as part of the Azure Networking learning series. Special thanks to the Azure networking community for their continuous contributions and feedback.

---

**Ready to start?** Head over to the [Getting Started Guide](getting-started.md)! 🚀
