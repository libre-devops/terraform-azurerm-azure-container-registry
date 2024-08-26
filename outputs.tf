output "agent_pool_ids" {
  description = "The IDs of the Azure Container Registry Agent Pools."
  value       = { for key, pool in azurerm_container_registry_agent_pool.agent_pool : key => pool.id }
}

output "agent_pool_locations" {
  description = "The locations of the Azure Container Registry Agent Pools."
  value       = { for key, pool in azurerm_container_registry_agent_pool.agent_pool : key => pool.location }
}

output "agent_pool_names" {
  description = "The names of the Azure Container Registry Agent Pools."
  value       = { for key, pool in azurerm_container_registry_agent_pool.agent_pool : key => pool.name }
}

output "registry_admin_passwords" {
  description = "The admin passwords of the created Azure Container Registries, if admin is enabled."
  value       = [for r in azurerm_container_registry.acr : r.admin_password]
}

output "registry_admin_usernames" {
  description = "The admin usernames of the created Azure Container Registries, if admin is enabled."
  value       = [for r in azurerm_container_registry.acr : r.admin_username]
}

output "registry_identities" {
  description = "The identities of the Azure Container Registries."
  value = {
    for key, registry in azurerm_container_registry.acr : key => {
      type         = try(registry.identity.0.type, null)
      principal_id = try(registry.identity.0.principal_id, null)
      tenant_id    = try(registry.identity.0.tenant_id, null)
    }
  }
}

output "registry_ids" {
  description = "The IDs of the created Azure Container Registries."
  value       = [for r in azurerm_container_registry.acr : r.id]
}

output "registry_locations" {
  description = "The locations of the created Azure Container Registries."
  value       = [for r in azurerm_container_registry.acr : r.location]
}

output "registry_login_servers" {
  description = "The login servers of the created Azure Container Registries."
  value       = [for r in azurerm_container_registry.acr : r.login_server]
}

output "registry_skus" {
  description = "The SKUs of the created Azure Container Registries."
  value       = [for r in azurerm_container_registry.acr : r.sku]
}

output "registry_tags" {
  description = "The tags associated with the created Azure Container Registries."
  value       = [for r in azurerm_container_registry.acr : r.tags]
}
