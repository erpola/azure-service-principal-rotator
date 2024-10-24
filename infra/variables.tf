variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "project" {
  description = "The name of the project"
  type        = string
}

variable "location" {
  description = "The location of the resources"
  type        = string
}

variable "environment" {
  description = "The environment of the resources"
  type        = string
}

variable "target_key_vault_name" {
  description = "The name of the key vault"
  type        = string
}

variable "target_key_vault_resource_group_name" {
  description = "The name of the resource group the key vault is in"
  type        = string
}

variable "target_key_vault_rotation_interval_in_days" {
  description = "The number of days between key rotations"
  type        = number
}

variable "run_cleanup" {
  description = "If 1, the function will remove any old keys"
  type        = number
  default     = 0
}

variable "subnet_base_cidr" {
  description = "The base CIDR for the subnets"
  type        = string
  default     = ""
}

variable "virtual_network_name" {
  description = "The name of the virtual network"
  type        = string
  default     = ""
}

variable "virtual_network_resource_group_name" {
  description = "The name of the resource group the virtual network is in"
  type        = string
  default     = ""
}

variable "public_network_access_enabled" {
  description = "If true, the function app will be accessible from the public internet"
  type        = bool
  default     = true
}