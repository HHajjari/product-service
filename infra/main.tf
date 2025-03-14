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

resource "azurerm_api_management" "apim" {
  name                = "apimproductservice"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "XYZ Group"
  publisher_email     = "hajjari@gmail.com"
  sku_name = "Developer_1" # Change based on your needs (Developer, Standard, Premium)
  virtual_network_type = "None" # Set to "Internal" if using VNet
}

resource "azurerm_api_management_api" "product_api" {
  name                = "product-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision           = "1"
  display_name       = "Product API"
  path              = "products"
  protocols         = ["https"]

  import {
    content_format = "swagger-json"
    content_value  = file("${path.module}/infra/swagger/product-service-swagger.json")
  }
}

resource "azurerm_api_management_backend" "aci_backend" {
  name                = "aci-backend"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  protocol           = "http"
  url               = "http://xyz-product-service-1-0-0.westeurope.azurecontainer.io"
}

resource "azurerm_api_management_api_operation_policy" "set_backend_policy" {
  api_name            = azurerm_api_management_api.product_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  operation_id        = "getAllProducts"

  xml_content = <<XML
  <policies>
      <inbound>
          <base />
          <set-backend-service base-url="http://xyz-product-service-1-0-0.westeurope.azurecontainer.io" />
      </inbound>
      <backend>
          <base />
      </backend>
      <outbound>
          <base />
      </outbound>
  </policies>
  XML
}
