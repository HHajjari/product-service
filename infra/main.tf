provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

# Ensure Resource Group Exists
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Ensure Azure Container Registry (ACR) Exists
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false

  lifecycle {
    prevent_destroy = true
  }
}

# Grant GitHub Actions permission to push images to ACR
resource "azurerm_role_assignment" "acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = var.github_oidc_principal_id
}

# Create Azure Container Instance (ACI) Using ACR
resource "azurerm_container_group" "aci" {
  name                = var.aci_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"

  container {
    name   = "placeholder-container"
    image  = "${azurerm_container_registry.acr.login_server}/busybox:latest"  # ✅ Using ACR instead of Docker Hub
    cpu    = var.cpu
    memory = var.memory

    environment_variables = {
      KEEP_ALIVE = "sh -c 'while true; do echo ACI is waiting for the real image; sleep 30; done'"
    }

    ports {
      port     = var.container_port
      protocol = "TCP"
    }
  }

  image_registry_credential {
    server   = azurerm_container_registry.acr.login_server
    username = null  # Use Managed Identity
    password = null
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Assign AcrPull Role to ACI Managed Identity
resource "azurerm_role_assignment" "aci_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_group.aci.identity[0].principal_id
}
