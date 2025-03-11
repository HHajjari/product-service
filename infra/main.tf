provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

# 🔹 Check if the Resource Group already exists
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# 🔹 Check if Azure Container Registry (ACR) already exists
data "azurerm_container_registry" "existing_acr" {
  name                = var.acr_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

# 🔹 If ACR doesn't exist, create a new one
resource "azurerm_container_registry" "acr" {
  count               = length(data.azurerm_container_registry.existing_acr.name) > 0 ? 0 : 1
  name                = var.acr_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true

  lifecycle {
    prevent_destroy = true  # ✅ Prevent accidental deletion
  }
}

# 🔹 Assign role to allow GitHub Actions to push to ACR (only if ACR exists)
resource "azurerm_role_assignment" "acr_pull_push" {
  scope                = data.azurerm_container_registry.existing_acr.id
  role_definition_name = "AcrPush"
  principal_id         = var.github_oidc_principal_id
}
