resource "azurerm_user_assigned_identity" "cplane" {
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  name                = "${var.base_name}-cplane-msi"
}

resource "azurerm_user_assigned_identity" "kubelet" {
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  name                = "${var.base_name}-kubelet-msi"
}

# resource "azurerm_container_registry" "acr" {
#   name                = "${replace(var.base_name, "-", "")}"
#   resource_group_name = azurerm_resource_group.group.name
#   location            = azurerm_resource_group.group.location
#   sku                 = "Standard"
#   admin_enabled       = false
# }

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.base_name
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  dns_prefix          = var.base_name
  kubernetes_version  = var.aks_version

  automatic_channel_upgrade = "patch"

  default_node_pool {
    name                 = "lnx000"
    node_count           = var.node_count
    vm_size              = var.node_vm_sku
    orchestrator_version = var.aks_version

    # node_taints
    # node_labels

    # Required for advanced networking
    vnet_subnet_id = azurerm_subnet.cluster.id
  }
  
  identity {
    type                      = "UserAssigned"
    user_assigned_identity_id = azurerm_user_assigned_identity.cplane.id
  }
  
  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet.id
  }
  
  role_based_access_control {
    enabled = true

    azure_active_directory {
      managed            = true
      azure_rbac_enabled = true
      
      admin_group_object_ids = [
        var.aks_admin_group_id
      ]
    }
  }
  
  addon_profile {
    
    # azure_policy {
    #   enabled = true
    # }

    http_application_routing {
      enabled = false
    }

    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id
    }

    ingress_application_gateway {
      enabled      = true
      gateway_name = var.base_name
      subnet_id    = azurerm_subnet.gateway.id
    }
  }

  # network_profile {
  #   network_plugin     = "azure"
  #   service_cidr       = "172.16.0.0/16"
  #   dns_service_ip     = "172.16.0.10"
  #   docker_bridge_cidr = "172.24.0.1/16"

  #   #network_policy     = "calico"
  # }

  network_profile {
    network_plugin = "kubenet"
  }

  # lifecycle {
  #   prevent_destroy = true
  # }

  depends_on = [
    azurerm_role_assignment.make_aks_kubelet_id_contributor #,
    # azurerm_role_assignment.route_table_contributor,
    # azurerm_subnet_route_table_association.cluster #,           // Make sure the route table is associated before starting the cluster
    # azurerm_subnet_route_table_association.gateway            // Not really needed, but nice to have
  ]
}

# data "azurerm_container_registry" "acr" {
#   resource_group_name  = var.acr_rg_name
#   name                 = var.acr_name
# }

# resource "azurerm_role_assignment" "acrpull_role_kubelet" {
#   scope                            = azurerm_container_registry.acr.id
#   role_definition_name             = "AcrPull"
#   principal_id                     = azurerm_user_assigned_identity.kubelet.principal_id
# }

resource "azurerm_role_assignment" "make_aks_kubelet_id_contributor" {
  scope                = azurerm_user_assigned_identity.kubelet.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.cplane.principal_id
}

// Because we're using a bring your own route table with kubenet, we need to make sure the kubelet
// identity has Network Contributor rights to that route table.
// https://docs.microsoft.com/en-us/azure/aks/configure-kubenet#bring-your-own-subnet-and-route-table-with-kubenet
# resource "azurerm_role_assignment" "route_table_contributor" {
#   scope                = azurerm_route_table.aks.id
#   role_definition_name = "Network Contributor"
#   principal_id         = azurerm_user_assigned_identity.cplane.principal_id
# }