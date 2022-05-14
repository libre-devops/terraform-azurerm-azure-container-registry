variable "acr_name" {
  type        = string
  description = "The name of the acr"
}

variable "admin_enabled" {
  type        = bool
  description = "If an admin account is enabled for the ACR, defaults to true"
  default     = true
}

variable "anonymous_pull_enabled" {
  type        = bool
  description = "If anonymous pulling from your container registry is enabled, defaults to false"
  default     = false
}

variable "data_endpoint_enabled" {
  type        = bool
  description = "Whether the data endpoint for the registry is enabled, default true"
  default     = true
}

variable "export_policy_enabled" {
  type        = bool
  description = "If a export policy is enabled, note, only works on premium sku"
  default     = null
}

variable "identity_ids" {
  description = "Specifies a list of user managed identity ids to be assigned to the VM."
  type        = list(string)
  default     = []
}

variable "identity_type" {
  description = "The Managed Service Identity Type of this Virtual Machine."
  type        = string
  default     = ""
}

variable "location" {
  description = "The location for this resource to be put in"
  type        = string
}

variable "network_rule_bypass_option" {
  type        = string
  description = "Whether bypass is enabled, defaults to AzureServices"
  default     = "AzureServices"
}

variable "public_network_access_enabled" {
  type        = bool
  description = "If public access to your ACR should be enabled, defaults to true"
  default     = true
}

variable "quarantine_policy_enabled" {
  type        = bool
  description = "If a quarantine policy is enabled, note, only works on premium sku"
  default     = null
}

variable "rg_name" {
  description = "The name of the resource group, this module does not create a resource group, it is expecting the value of a resource group already exists"
  type        = string
  validation {
    condition     = length(var.rg_name) > 1 && length(var.rg_name) <= 24
    error_message = "Resource group name is not valid."
  }
}

variable "settings" {
  description = "Specifies the Authentication enabled or not"
  default     = false
  type        = any
}

variable "sku" {
  type        = string
  description = "The SKU of the ACR"
}

variable "tags" {
  type        = map(string)
  description = "A map of the tags to use on the resources that are deployed with this module."

  default = {
    source = "terraform"
  }
}

variable "zone_redundancy_enabled" {
  type        = bool
  description = "If a zone redundancy is enabled, note, only works on premium sku"
  default     = null
}
