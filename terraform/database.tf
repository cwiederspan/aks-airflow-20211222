resource "azurerm_postgresql_flexible_server" "server" {

  name                   = var.base_name
  resource_group_name    = azurerm_resource_group.group.name
  location               = azurerm_resource_group.group.location
  version                = "13"

  delegated_subnet_id    = azurerm_subnet.data.id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres.id

  administrator_login    = var.dbserver_username
  administrator_password = var.dbserver_password
  # zone                   = "1"

  storage_mb = 32768

  sku_name   = "GP_Standard_D2ds_v4"
  
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgres
  ]

  lifecycle {
    ignore_changes = [
      zone,
      high_availability.0.standby_availability_zone
    ]
  }
}

resource "azurerm_postgresql_flexible_server_database" "airflow" {
  name      = "airflow"
  server_id = azurerm_postgresql_flexible_server.server.id
  # collation = "en_US.utf8"
  # charset   = "utf8"
}