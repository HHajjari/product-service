provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

# 🔹 Check if Resource Group Exists
data "azurerm_resource_group" "existing_rg" {
  name = var.resource_group_name
}

# 🔹 Create Resource Group Only If It Doesn't Exist
resource "azurerm_resource_group" "rg" {
  count    = length(data.azurerm_resource_group.existing_rg.name) > 0 ? 0 : 1
  name     = var.resource_group_name
  location = var.location
}

# 🔹 Fetch Existing Azure Container Registry (ACR)
data "azurerm_container_registry" "existing_acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
}

# 🔹 If ACR does not exist, create a new one
resource "azurerm_container_registry" "acr" {
  count               = length(data.azurerm_container_registry.existing_acr.name) > 0 ? 0 : 1
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false  # Admin access disabled for security

  lifecycle {
    prevent_destroy = true  # Prevent accidental deletion
  }
}

# 🔹 Grant GitHub Actions permission to push images to ACR
resource "azurerm_role_assignment" "acr_push" {
  scope                = data.azurerm_container_registry.existing_acr.id
  role_definition_name = "AcrPush"
  principal_id         = var.github_oidc_principal_id
}

# 🔹 Create Azure Container Instance (ACI) with a Placeholder Image
resource "azurerm_container_group" "aci" {
  name                = var.aci_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"

  container {
    name   = "placeholder-container"
    image  = "busybox"  # Placeholder image
    cpu    = "1"
    memory = "1"

    environment_variables = {
      KEEP_ALIVE = "sh -c 'while true; do echo ACI is waiting for the real image; sleep 30; done'"
    }

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

# 🔹 Assign AcrPull Role to ACI Managed Identity
resource "azurerm_role_assignment" "aci_acr_pull" {
  scope                = data.azurerm_container_registry.existing_acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_group.aci.identity[0].principal_id
}
