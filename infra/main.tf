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

# Deploy an Azure Container Instance (ACI) with a basic image from public ACR
resource "azurerm_container_group" "aci" {
  name                = var.aci_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"

  container {
    name   = "hello-world"
    image  = "mcr.microsoft.com/hello-world"  # Public Azure ACR image
    cpu    = "0.5"
    memory = "0.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  restart_policy = "Always"
}

# Grant GitHub Actions permission to push images to ACR
resource "azurerm_role_assignment" "acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = var.github_oidc_principal_id
}

# Assign AcrPull Role to ACI Managed Identity (If ACI is created later)
resource "azurerm_role_assignment" "aci_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = var.github_oidc_principal_id
}
