resource "azurerm_virtual_network" "vnet" {
  name                = "${var.base_name}-vnet"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  address_space       = ["192.168.0.0/16"]
}


// https://docs.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure#size-of-the-subnet
// Per docs, /24 highly recommended, but not required. App Gateway v2 can support up to 125 instances, 
// which each require their own IP address.
resource "azurerm_subnet" "gateway" {
  name                 = "gateway-subnet"
  resource_group_name  = azurerm_resource_group.group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.1.0/27"]
}

// Azure Postgresql Flexible Server requires needs minimum of 4 IPs. So, /28 would 
// be minimum size for single Postgres resource, (based on internal Microsoft email)
resource "azurerm_subnet" "data" {
  name                 = "data-subnet"
  resource_group_name  = azurerm_resource_group.group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.2.0/27"]

  delegation {
    name = "postgres-subnet-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

// https://docs.microsoft.com/en-us/azure/azure-cache-for-redis/cache-how-to-premium-vnet
// In addition to the IP addresses used by the Azure virtual network infrastructure, each Azure
// Cache for Redis instance in the subnet uses two IP addresses per shard and one additional
// IP address for the load balancer. A nonclustered cache is considered to have one shard.
resource "azurerm_subnet" "cache" {
  name                 = "cache-subnet"
  resource_group_name  = azurerm_resource_group.group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.3.0/27"]
}

# resource "azurerm_subnet" "bastion" {
#   name                 = "AzureBastionSubnet"
#   resource_group_name  = azurerm_resource_group.group.name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefixes     = ["192.168.9.0/24"]
# }

// https://docs.microsoft.com/en-us/azure/aks/configure-kubenet#ip-address-availability-and-exhaustion
// A /24 subnet can support up to 251 nodes in Kubenet, and a /27 could support 20-25 nodes with room
// for scale and upgrades
resource "azurerm_subnet" "cluster" {
  name                 = "cluster-subnet"
  resource_group_name  = azurerm_resource_group.group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.10.0/24"]
}

resource "azurerm_private_dns_zone" "postgres" {
  name                = "private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "postgresdnslink"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  resource_group_name   = azurerm_resource_group.group.name
}

# resource "azurerm_subnet" "ingress" {
#   name                 = "ingress-subnet"
#   resource_group_name  = azurerm_resource_group.group.name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefixes     = ["10.0.2.0/24"]
# }


// NOTE: Because we're using Kubenet for the cluster, and also using AGIC, we need to
// associate the cluster's route table with the gateway subnet, too. To do this, we can
// create the route table first, and then assign it to both subnets instea of letting 
// AKS create the route table for us.
resource "azurerm_route_table" "aks" {
  name                = "aks-agentpool-routetable"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location

  disable_bgp_route_propagation = false
}

resource "azurerm_subnet_route_table_association" "cluster" {
  subnet_id      = azurerm_subnet.cluster.id
  route_table_id = azurerm_route_table.aks.id
}

resource "azurerm_subnet_route_table_association" "gateway" {
  subnet_id      = azurerm_subnet.gateway.id
  route_table_id = azurerm_route_table.aks.id
}