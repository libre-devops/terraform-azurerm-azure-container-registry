output "acr_admin_password" {
  description = "The Username associated with the Container Registry Admin account - if the admin account is enabled."
  value       = var.admin_enabled == true ? azurerm_container_registry.acr.admin_password : null
  sensitive   = true
}

output "acr_admin_username" {
  description = "The Username associated with the Container Registry Admin account - if the admin account is enabled."
  value       = var.admin_enabled == true ? azurerm_container_registry.acr.admin_username : null
}

output "acr_id" {
  description = "The ID of the Container Registry"
  value       = azurerm_container_registry.acr.id
}

output "acr_login_server" {
  description = "The URL that can be used to log into the container registry"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_principal_id" {
  value       = azurerm_container_registry.acr.identity[0].principal_id
  description = "Client ID of system assigned managed identity if created"
}
