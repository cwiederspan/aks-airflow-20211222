terraform {
  required_version = ">= 1.0"
  
  backend "azurerm" {
    environment = "public"
  }

  required_providers {
    azurerm = {
      version = "~> 2.90"
    }
    
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.7"
    }

    random = {
      version = "~> 3.1"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "base_name" {
  type        = string
  description = "A base for the naming scheme."
}

variable "location" {
  type        = string
  description = "The Azure region where the resources will be created."
}

variable "aks_version" {
  type        = string
  description = "The version of Kubernetes to install and use."
  default     = "1.22.4"
}

variable "node_count" {
  type        = number
  description = "The number of nodes to create in the default node pool."
  default     = 1
}

variable "node_vm_sku" {
  type        = string
  description = "The VM SKU to use for the default nodes."
  default     = "Standard_DS2_v2"
}

variable "aks_admin_group_id" {
  type        = string
  description = "The ID of an AAD group that will be assigned as the AAD Admin for the Kubernetes cluster."
}

variable "dbserver_username" {
  type        = string
  description = "The admin username for the Postgres server."
  default     = "psqladmin"
}

variable "dbserver_password" {
  type        = string
  description = "The admin password for the Postgres server."
  nullable    = true
  default     = null
}

locals {
  database_password = coalesce(var.dbserver_password, random_string.database_password.result)
}

resource "azurerm_resource_group" "group" {
  name     = var.base_name
  location = var.location
}

resource "random_id" "server" {
  byte_length = 8
}

resource "random_string" "database_password" {
  length  = 16
  special = false
}

# resource "random_string" "webserverkey" {
#   length           = 16
#   special          = false
# }