resource "azurerm_application_insights" "insights" {
  name                = "${var.base_name}-appi"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  application_type    = "web"

  #tags = "${var.tags}"
}

resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "${var.base_name}-wksp"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  #tags = "${var.tags}"
}

resource "azurerm_log_analytics_solution" "containerinsights" {
  solution_name         = "ContainerInsights"
  resource_group_name   = azurerm_resource_group.group.name
  location              = azurerm_resource_group.group.location
  workspace_resource_id = azurerm_log_analytics_workspace.workspace.id
  workspace_name        = azurerm_log_analytics_workspace.workspace.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}