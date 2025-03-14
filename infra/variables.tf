variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group Name"
  type        = string
}

variable "location" {
  description = "Azure Region"
  type        = string
}

variable "acr_name" {
  description = "Azure Container Registry Name"
  type        = string
}

variable "aci_name" {
  description = "Azure Container Instance Name"
  type        = string
}

variable "github_oidc_principal_id" {
  description = "GitHub OIDC Principal ID (for authentication to ACR)"
  type        = string
}