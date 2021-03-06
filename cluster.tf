resource "azurerm_kubernetes_cluster" "sandbox-cluster" {

  name                = "sandbox-cluster"
  location            = azurerm_resource_group.aks-sandbox.location
  resource_group_name = azurerm_resource_group.aks-sandbox.name
  dns_prefix          = "sandbox-cluster"
  kubernetes_version  = "1.18.8"

  network_profile {
    network_plugin     = "azure"
    dns_service_ip     = "10.0.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
    service_cidr       = "10.0.0.0/16"
  }

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
    vnet_subnet_id = azurerm_subnet.sandbox_subnet.id
  }

  windows_profile {
    admin_username = "mbsadmin"
    admin_password = var.admin_password
  }

  service_principal {
    client_id     = azuread_service_principal.aks-sandbox.application_id
    client_secret = random_password.aks-sandbox-sp-password.result
  }

}

resource "azurerm_role_assignment" "aks_sp_container_registry" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azuread_service_principal.aks-sandbox.object_id
}

resource "azurerm_kubernetes_cluster_node_pool" "windows_pool" {

  kubernetes_cluster_id = azurerm_kubernetes_cluster.sandbox-cluster.id
  name = "pool2"
  node_count = 1
  vm_size = "Standard_D4_v3"
  os_type = "Windows"
  vnet_subnet_id = azurerm_subnet.sandbox_subnet.id

}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.sandbox-cluster.kube_config.0.client_certificate
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.sandbox-cluster.kube_config_raw
}
