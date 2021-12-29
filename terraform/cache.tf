resource "azurerm_redis_cache" "cache" {
  name                = var.base_name
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location

  capacity            = 1
  family              = "P"
  sku_name            = "Premium"
  minimum_tls_version = "1.2"
  # enable_non_ssl_port = true        # Open port 6379

  public_network_access_enabled = false

  subnet_id = azurerm_subnet.cache.id
  
  redis_configuration {

  }
}