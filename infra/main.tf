provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

# Fetch Existing Resource Group
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# 🔹 Fetch Existing Azure Container Registry (ACR)
data "azurerm_container_registry" "existing_acr" {
  name                = var.acr_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

# If ACR does not exist, create a new one
resource "azurerm_container_registry" "acr" {
  count               = length(data.azurerm_container_registry.existing_acr.name) > 0 ? 0 : 1
  name                = var.acr_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false  # Admin access disabled for security

  lifecycle {
    prevent_destroy = true  # Prevent accidental deletion
  }
}

# Grant GitHub Actions permission to push images to ACR
resource "azurerm_role_assignment" "acr_push" {
  scope                = data.azurerm_container_registry.existing_acr.id
  role_definition_name = "AcrPush"
  principal_id         = var.github_oidc_principal_id
}

# Create Azure Container Instance (ACI) with a Placeholder Image
resource "azurerm_container_group" "aci" {
  name                = var.aci_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  os_type             = "Linux"

  container {
    name   = "placeholder-container"
    image  = "busybox"  # Placeholder image
    cpu    = "1"
    memory = "1"

    command = ["sh", "-c", "while true; do echo 'ACI is waiting for the real image'; sleep 30; done"]  # Keeps container alive

    ports {
      port     = 8080
      protocol = "TCP"
    }
  }

  identity {
    type = "SystemAssigned"  # Enables Managed Identity for ACI
  }

  lifecycle {
    prevent_destroy = true  # Prevent accidental deletion
  }
}

# Assign AcrPull Role to ACI Managed Identity
resource "azurerm_role_assignment" "aci_acr_pull" {
  scope                = data.azurerm_container_registry.existing_acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_group.aci.identity[0].principal_id
}
