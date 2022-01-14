provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_admin_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate)
}

resource "kubernetes_namespace" "airflow" {
  metadata {
    name = "airflow"
  }
}

# Read more about setting Airflow variables here: 
# https://github.com/apache/airflow/blob/5e46c1770fc0e76556669dc60bd20553b986667b/chart/templates/_helpers.yaml
# You can use this to lookup the value name for putting inside of the data section in the K8S secrets below.

resource "kubernetes_secret" "backend_metadata" {
   metadata {
     name = "airflow-connection-metadata"
     namespace = kubernetes_namespace.airflow.metadata.0.name
   }
   data = {
      connection = "postgresql://${var.dbserver_username}:${local.database_password}@${azurerm_postgresql_flexible_server.server.fqdn}:6432/${azurerm_postgresql_flexible_server_database.metadata.name}?sslmode=require"
   }
   type = "Opaque"
}

# *** NOTE: Watch out for the extra "db+" in this secret value ***
resource "kubernetes_secret" "backend_results" {
   metadata {
     name = "airflow-connection-results"
     namespace = kubernetes_namespace.airflow.metadata.0.name
   }
   data = {
      connection = "db+postgresql://${var.dbserver_username}:${local.database_password}@${azurerm_postgresql_flexible_server.server.fqdn}:6432/${azurerm_postgresql_flexible_server_database.results.name}?sslmode=require"
   }
   type = "Opaque"
}

resource "kubernetes_secret" "redis_connection" {
   metadata {
     name = "airflow-connection-redis"
     namespace = kubernetes_namespace.airflow.metadata.0.name
   }
   data = {
      connection = "rediss://redis-user:${azurerm_redis_cache.cache.primary_access_key}@${azurerm_redis_cache.cache.hostname}:${azurerm_redis_cache.cache.ssl_port}/0?ssl_cert_reqs=required"
   }
   type = "Opaque"
}