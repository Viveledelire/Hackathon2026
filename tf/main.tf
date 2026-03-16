terraform {
  required_version = ">= 1.11.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.64"
    }
  }

}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "polandcentral"
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "aks-qsdqzdsdsdgi"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "aks-qsdqzdsdsdgi"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2s_v3"
    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.example.kube_config_raw
  sensitive = true
}

resource "azurerm_container_registry" "example" {
  name                = "acrqsdqzdsdsdgi"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Basic"

  admin_enabled = true
}

resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.example.identity[0].principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.example.id
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "examplelaw"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "example" {
  name                = "example-app-insights"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  application_type    = "web"
}

resource "azurerm_role_assignment" "log_analytics" {
  principal_id         = azurerm_kubernetes_cluster.example.identity[0].principal_id
  role_definition_name = "Log Analytics Reader"
  scope                = azurerm_log_analytics_workspace.example.id
}
