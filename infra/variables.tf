variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group Name"
  type        = string
  default     = "my-resource-group"  # Change as needed
}

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "West Europe"
}

variable "acr_name" {
  description = "Azure Container Registry Name"
  type        = string
}

variable "github_oidc_principal_id" {
  description = "GitHub OIDC Principal ID"
  type        = string
}
