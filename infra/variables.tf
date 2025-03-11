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

variable "github_oidc_principal_id" {
  description = "GitHub OIDC Principal ID (for authentication to ACR)"
  type        = string
}

variable "aci_name" {
  description = "Name of the Azure Container Instance"
  type        = string
}

variable "image_name" {
  description = "Name of the Docker image in ACR"
  type        = string
  default     = "spring-boot-app"  # Default to your Spring Boot app image
}

variable "placeholder_image" {
  description = "Initial placeholder image for ACI"
  type        = string
  default     = "busybox"  # ✅ Placeholder image to avoid downtime
}

variable "cpu" {
  description = "CPU allocation for ACI"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory allocation for ACI (GB)"
  type        = number
  default     = 1
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 8080
}
