output "container_registries" {
  description = "Map of registry name to the full container registry object."
  value       = azurerm_container_registry.this
  sensitive   = true
}

output "container_registry_ids" {
  description = "Map of registry name to id."
  value       = { for k, r in azurerm_container_registry.this : k => r.id }
}

output "container_registry_ids_zipmap" {
  description = "Map of registry name to { name, id } for easy composition."
  value       = { for k, r in azurerm_container_registry.this : k => { name = r.name, id = r.id } }
}

output "identity_principal_ids" {
  description = "Map of registry name to { system_assigned } principal id (null where absent)."
  value = {
    for k, r in azurerm_container_registry.this : k => {
      system_assigned = try(r.identity[0].principal_id, null)
    }
  }
}

output "login_servers" {
  description = "Map of registry name to its login server (the pull/push host)."
  value       = { for k, r in azurerm_container_registry.this : k => r.login_server }
}
