variable "AZP_URL" {
  type        = string
  description = "Passed as TF_VAR"
  sensitive   = true
}

variable "AZP_TOKEN" {
  type        = string
  description = "Passed as TF_VAR"
  sensitive   = true
}

variable "AZP_POOL" {
  type        = string
  description = "Passed as TF_VAR, defaults to Default"
  default     = "Default"
}