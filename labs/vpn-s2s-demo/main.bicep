// ============================================================================
// VPN Site-to-Site Demo Lab - Main Bicep Template
// ============================================================================
// This template deploys a complete Site-to-Site VPN demo environment with:
// - On-Premises VNet (192.168.1.0/24) with VPN Gateway
// - Azure VNet (10.100.0.0/22) with VPN Gateway  
// - IPSec tunnel connecting both gateways
// - Optional test VMs in each VNet
// ============================================================================

@description('Location for all resources')
param location string = resourceGroup().location

@description('Admin username for test VMs')
param adminUsername string = 'azureuser'

@description('Admin password for test VMs')
@secure()
param adminPassword string

@description('Shared key for VPN connection')
@secure()
param sharedKey string

@description('Deploy test VMs for connectivity testing')
param deployTestVMs bool = true

@description('VPN Gateway SKU (Basic, VpnGw1, VpnGw2, VpnGw3, VpnGw4, VpnGw5)')
param gatewaySku string = 'Basic'

@description('Enable BGP on VPN Gateways')
param enableBgp bool = false

// ============================================================================
// Variables
// ============================================================================

var onpremVnetName = 'vnet-onprem'
var onpremVnetPrefix = '192.168.1.0/24'
var onpremSubnetName = 'subnet-default'
var onpremSubnetPrefix = '192.168.1.0/27'
var onpremGatewaySubnetPrefix = '192.168.1.224/27'

var azureVnetName = 'vnet-azure'
var azureVnetPrefix = '10.100.0.0/22'
var azureSubnetName = 'subnet-default'
var azureSubnetPrefix = '10.100.0.0/24'
var azureGatewaySubnetPrefix = '10.100.3.224/27'

var onpremGatewayName = 'vng-onprem'
var azureGatewayName = 'vng-azure'

var onpremPipName = 'pip-vng-onprem'
var azurePipName = 'pip-vng-azure'

var connectionNameOnpremToAzure = 'conn-onprem-to-azure'

var onpremVmName = 'vm-onprem'
var azureVmName = 'vm-azure'

// ============================================================================
// On-Premises Virtual Network
// ============================================================================

resource vnetOnprem 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: onpremVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        onpremVnetPrefix
      ]
    }
    subnets: [
      {
        name: onpremSubnetName
        properties: {
          addressPrefix: onpremSubnetPrefix
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: onpremGatewaySubnetPrefix
        }
      }
    ]
  }
}

// ============================================================================
// Azure Virtual Network
// ============================================================================

resource vnetAzure 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: azureVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        azureVnetPrefix
      ]
    }
    subnets: [
      {
        name: azureSubnetName
        properties: {
          addressPrefix: azureSubnetPrefix
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: azureGatewaySubnetPrefix
        }
      }
    ]
  }
}

// ============================================================================
// Public IPs for VPN Gateways
// ============================================================================

resource pipOnpremGateway 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: onpremPipName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource pipAzureGateway 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: azurePipName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// ============================================================================
// On-Premises VPN Gateway
// ============================================================================

resource vngOnprem 'Microsoft.Network/virtualNetworkGateways@2023-04-01' = {
  name: onpremGatewayName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'vnetGatewayConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${vnetOnprem.id}/subnets/GatewaySubnet'
          }
          publicIPAddress: {
            id: pipOnpremGateway.id
          }
        }
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: enableBgp
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
  }
}

// ============================================================================
// Azure VPN Gateway
// ============================================================================

resource vngAzure 'Microsoft.Network/virtualNetworkGateways@2023-04-01' = {
  name: azureGatewayName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'vnetGatewayConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${vnetAzure.id}/subnets/GatewaySubnet'
          }
          publicIPAddress: {
            id: pipAzureGateway.id
          }
        }
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: enableBgp
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
  }
}

// ============================================================================
// VPN Connections (Site-to-Site IPSec Tunnel)
// ============================================================================

resource connectionOnpremToAzure 'Microsoft.Network/connections@2023-04-01' = {
  name: connectionNameOnpremToAzure
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: vngOnprem.id
      properties: {}
    }
    virtualNetworkGateway2: {
      id: vngAzure.id
      properties: {}
    }
    connectionType: 'Vnet2Vnet'
    routingWeight: 10
    sharedKey: sharedKey
    enableBgp: enableBgp
  }
}

// ============================================================================
// Test VMs - Network Interfaces
// ============================================================================

resource nicOnpremVm 'Microsoft.Network/networkInterfaces@2023-04-01' = if (deployTestVMs) {
  name: 'nic-${onpremVmName}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${vnetOnprem.id}/subnets/${onpremSubnetName}'
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipOnpremVm.id
          }
        }
      }
    ]
  }
}

resource nicAzureVm 'Microsoft.Network/networkInterfaces@2023-04-01' = if (deployTestVMs) {
  name: 'nic-${azureVmName}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${vnetAzure.id}/subnets/${azureSubnetName}'
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipAzureVm.id
          }
        }
      }
    ]
  }
}

// ============================================================================
// Test VMs - Public IPs
// ============================================================================

resource pipOnpremVm 'Microsoft.Network/publicIPAddresses@2023-04-01' = if (deployTestVMs) {
  name: 'pip-${onpremVmName}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource pipAzureVm 'Microsoft.Network/publicIPAddresses@2023-04-01' = if (deployTestVMs) {
  name: 'pip-${azureVmName}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// ============================================================================
// Test VMs - Network Security Groups
// ============================================================================

resource nsgOnprem 'Microsoft.Network/networkSecurityGroups@2023-04-01' = if (deployTestVMs) {
  name: 'nsg-onprem'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-ssh'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'allow-icmp'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Icmp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource nsgAzure 'Microsoft.Network/networkSecurityGroups@2023-04-01' = if (deployTestVMs) {
  name: 'nsg-azure'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-ssh'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'allow-icmp'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Icmp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// ============================================================================
// Test VMs - Virtual Machines
// ============================================================================

resource vmOnprem 'Microsoft.Compute/virtualMachines@2023-03-01' = if (deployTestVMs) {
  name: onpremVmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: onpremVmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicOnpremVm.id
        }
      ]
    }
  }
}

resource vmAzure 'Microsoft.Compute/virtualMachines@2023-03-01' = if (deployTestVMs) {
  name: azureVmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: azureVmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicAzureVm.id
        }
      ]
    }
  }
}

// ============================================================================
// Outputs
// ============================================================================

output onpremVnetId string = vnetOnprem.id
output azureVnetId string = vnetAzure.id
output onpremGatewayId string = vngOnprem.id
output azureGatewayId string = vngAzure.id
output onpremGatewayPublicIp string = pipOnpremGateway.properties.ipAddress
output azureGatewayPublicIp string = pipAzureGateway.properties.ipAddress
output onpremVmPublicIp string = deployTestVMs ? pipOnpremVm.properties.ipAddress : 'Not deployed'
output azureVmPublicIp string = deployTestVMs ? pipAzureVm.properties.ipAddress : 'Not deployed'
