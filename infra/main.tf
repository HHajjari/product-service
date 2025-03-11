provider "azurerm" {
  features {}

  subscription_id = var.subscription_id  # ✅ Added Subscription ID
}

# 🔹 Ensure Resource Group Exists (Create if Missing)
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# 🔹 Ensure Azure Container Registry (ACR) Exists
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false  # Admin access disabled for security

  lifecycle {
    prevent_destroy = true  # Prevent accidental deletion
  }
}

# 🔹 Grant GitHub Actions permission to push images to ACR
resource "azurerm_role_assignment" "acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = var.github_oidc_principal_id
}

# 🔹 Create Azure Container Instance (ACI) with a Placeholder Image
resource "azurerm_container_group" "aci" {
  name                = var.aci_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"

  container {
    name   = "placeholder-container"
    image  = var.image_name  # Uses the `image_name` variable
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

  identity {
    type = "SystemAssigned"  # Enables Managed Identity for ACI
  }

  lifecycle {
    prevent_destroy = true  # Prevent accidental deletion
  }
}

# 🔹 Assign AcrPull Role to ACI Managed Identity
resource "azurerm_role_assignment" "aci_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_group.aci.identity[0].principal_id
}
