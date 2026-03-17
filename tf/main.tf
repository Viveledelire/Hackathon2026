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

resource "azurerm_resource_group" "sup_de_vinci_hackathon" {
  name     = "sup-de-vinci-hackathon-resources"
  location = "polandcentral"
}

resource "azurerm_kubernetes_cluster" "devops03_aks" {
  name                = "devops03-aks-cluster"
  location            = azurerm_resource_group.sup_de_vinci_hackathon.location
  resource_group_name = azurerm_resource_group.sup_de_vinci_hackathon.name
  dns_prefix          = "devops03-aks"

  default_node_pool {
    name       = "defaultpool"
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
  value     = azurerm_kubernetes_cluster.devops03_aks.kube_config_raw
  sensitive = true
}

resource "azurerm_container_registry" "devops03_acr" {
  name                = "devops03acr"
  resource_group_name = azurerm_resource_group.sup_de_vinci_hackathon.name
  location            = azurerm_resource_group.sup_de_vinci_hackathon.location
  sku                 = "Basic"

  admin_enabled = true
}

resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.devops03_aks.identity[0].principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.devops03_acr.id
}

resource "azurerm_log_analytics_workspace" "sup_de_vinci_law" {
  name                = "sup-de-vinci-law"
  location            = azurerm_resource_group.sup_de_vinci_hackathon.location
  resource_group_name = azurerm_resource_group.sup_de_vinci_hackathon.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "devops03_app_insights" {
  name                = "devops03-app-insights"
  location            = azurerm_resource_group.sup_de_vinci_hackathon.location
  resource_group_name = azurerm_resource_group.sup_de_vinci_hackathon.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.sup_de_vinci_law.id
}

resource "azurerm_role_assignment" "monitor_workspace" {
  principal_id         = azurerm_kubernetes_cluster.devops03_aks.identity[0].principal_id
  role_definition_name = "Monitoring Metrics Publisher"
  scope                = azurerm_monitor_workspace.sup_de_vinci_monitor.id
}

resource "azurerm_monitor_workspace" "sup_de_vinci_monitor" {
  name                = "sup-de-vinci-monitor"
  resource_group_name = azurerm_resource_group.sup_de_vinci_hackathon.name
  location            = azurerm_resource_group.sup_de_vinci_hackathon.location
}

resource "azurerm_dashboard_grafana" "devops03_grafana" {
  name                              = "devops03-grafana"
  resource_group_name               = azurerm_resource_group.sup_de_vinci_hackathon.name
  location                          = "norwayeast"
  grafana_major_version             = 12
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = true
  public_network_access_enabled     = true

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.sup_de_vinci_monitor.id
  }
}

data "azurerm_client_config" "current_user" {}

resource "azurerm_role_assignment" "grafana_viewer" {
  principal_id         = data.azurerm_client_config.current_user.object_id
  role_definition_name = "Grafana Viewer"
  scope                = azurerm_dashboard_grafana.devops03_grafana.id
}

output "grafana_dashboard_url" {
  value = azurerm_dashboard_grafana.devops03_grafana.endpoint
}
