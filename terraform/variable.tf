variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "open_ports" {
  description = "List of ports to open in the network security group"
  type        = list(number)
  default     = [22, 80]
  validation {
    condition     = alltrue([for port in var.open_ports : port >= 1 && port <= 65535])
    error_message = "All ports must be valid port numbers between 1 and 65535."
  }
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
  default     = "acr"
}

variable "rg_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-assignment"
}

variable "location" {
  description = "Name of the Azure region name"
  type        = string
  default     = "France Central"
}

