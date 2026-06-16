locals {
  resource_group_names = {
    for key, rg in var.resource_groups : key => rg.resource_group_name
  }

  resource_group_locations = {
    for key, rg in var.resource_groups : key => coalesce(try(rg.location, null), var.azure_location)
  }

  resolve_resource_group_name = {
    for key, cfg in merge(
      { for k, v in var.storage_accounts : "storage_accounts:${k}" => v },
      { for k, v in var.key_vaults : "key_vaults:${k}" => v },
      { for k, v in var.key_vault_secrets : "key_vault_secrets:${k}" => v },
      { for k, v in var.key_vault_keys : "key_vault_keys:${k}" => v },
      { for k, v in var.vnets : "vnets:${k}" => v },
      { for k, v in var.network_security_groups : "network_security_groups:${k}" => v },
      { for k, v in var.load_balancers : "load_balancers:${k}" => v },
      { for k, v in var.application_gateways : "application_gateways:${k}" => v },
      { for k, v in var.function_apps : "function_apps:${k}" => v },
      { for k, v in var.cdn_profiles : "cdn_profiles:${k}" => v },
      { for k, v in var.container_registries : "container_registries:${k}" => v },
      { for k, v in var.rbac_roles : "rbac_roles:${k}" => v },
      { for k, v in var.virtual_machines : "virtual_machines:${k}" => v },
      { for k, v in var.postgresql_servers : "postgresql_servers:${k}" => v },
      { for k, v in var.api_management_services : "api_management_services:${k}" => v },
      { for k, v in var.service_bus_topics : "service_bus_topics:${k}" => v },
      { for k, v in var.service_bus_queues : "service_bus_queues:${k}" => v },
      { for k, v in var.storage_queues : "storage_queues:${k}" => v },
      { for k, v in var.aks_clusters : "aks_clusters:${k}" => v },
      { for k, v in var.container_apps : "container_apps:${k}" => v },
      { for k, v in var.storage_shares : "storage_shares:${k}" => v },
      { for k, v in var.aadb2c_directories : "aadb2c_directories:${k}" => v },
      { for k, v in var.event_hubs_namespaces : "event_hubs_namespaces:${k}" => v },
      ) : key => coalesce(
      try(cfg.resource_group_name, null),
      try(local.resource_group_names[cfg.resource_group_key], null)
    )
  }

  resolve_location = {
    for key, cfg in merge(
      { for k, v in var.storage_accounts : "storage_accounts:${k}" => v },
      { for k, v in var.key_vaults : "key_vaults:${k}" => v },
      { for k, v in var.key_vault_secrets : "key_vault_secrets:${k}" => v },
      { for k, v in var.key_vault_keys : "key_vault_keys:${k}" => v },
      { for k, v in var.vnets : "vnets:${k}" => v },
      { for k, v in var.network_security_groups : "network_security_groups:${k}" => v },
      { for k, v in var.load_balancers : "load_balancers:${k}" => v },
      { for k, v in var.application_gateways : "application_gateways:${k}" => v },
      { for k, v in var.function_apps : "function_apps:${k}" => v },
      { for k, v in var.cdn_profiles : "cdn_profiles:${k}" => v },
      { for k, v in var.container_registries : "container_registries:${k}" => v },
      { for k, v in var.rbac_roles : "rbac_roles:${k}" => v },
      { for k, v in var.virtual_machines : "virtual_machines:${k}" => v },
      { for k, v in var.postgresql_servers : "postgresql_servers:${k}" => v },
      { for k, v in var.api_management_services : "api_management_services:${k}" => v },
      { for k, v in var.service_bus_topics : "service_bus_topics:${k}" => v },
      { for k, v in var.service_bus_queues : "service_bus_queues:${k}" => v },
      { for k, v in var.storage_queues : "storage_queues:${k}" => v },
      { for k, v in var.aks_clusters : "aks_clusters:${k}" => v },
      { for k, v in var.container_apps : "container_apps:${k}" => v },
      { for k, v in var.storage_shares : "storage_shares:${k}" => v },
      { for k, v in var.aadb2c_directories : "aadb2c_directories:${k}" => v },
      { for k, v in var.event_hubs_namespaces : "event_hubs_namespaces:${k}" => v },
      ) : key => coalesce(
      try(cfg.location, null),
      try(local.resource_group_locations[cfg.resource_group_key], null),
      var.azure_location
    )
  }

  load_balancer_subnet_ids = {
    for name, lb in var.load_balancers : name => coalesce(
      try(lb.subnet_ids, null),
      try([
        for key in coalesce(try(lb.subnet_keys, null), []) :
        module.vnet[lb.vnet_key].public_subnet_ids[key]
      ], null),
      try(values(module.vnet[lb.vnet_key].public_subnet_ids), null)
    )
  }

  application_gateway_subnet_ids = {
    for name, agw in var.application_gateways : name => coalesce(
      try(agw.subnet_id, null),
      try(module.vnet[agw.vnet_key].public_subnet_ids[agw.subnet_key], null)
    )
  }

  nsg_vnet_ids = {
    for name, nsg in var.network_security_groups : name => try(
      module.vnet[nsg.vnet_key].vnet_id,
      null
    )
  }
}

module "resource_group" {
  source = "../../modules/resource-group"

  for_each = var.resource_groups

  resource_group_name = each.value.resource_group_name
  location            = coalesce(try(each.value.location, null), var.azure_location)
  tags                = merge(var.default_tags, try(each.value.tags, {}))
}

module "storage_account" {
  source = "../../modules/storage-account"

  for_each = var.storage_accounts

  resource_group_name      = local.resolve_resource_group_name["storage_accounts:${each.key}"]
  location                 = local.resolve_location["storage_accounts:${each.key}"]
  storage_account_name     = each.value.storage_account_name
  account_tier             = try(each.value.account_tier, "Standard")
  account_replication_type = try(each.value.account_replication_type, "LRS")
  versioning_enabled       = try(each.value.versioning_enabled, false)
  containers               = try(each.value.containers, {})
  tags                     = merge(var.default_tags, try(each.value.tags, {}))
}

module "key_vault" {
  source = "../../modules/key-vault"

  for_each = var.key_vaults

  resource_group_name      = local.resolve_resource_group_name["key_vaults:${each.key}"]
  location                 = local.resolve_location["key_vaults:${each.key}"]
  name                     = each.value.name
  sku_name                 = try(each.value.sku_name, "standard")
  purge_protection_enabled = try(each.value.purge_protection_enabled, true)
  tags                     = merge(var.default_tags, try(each.value.tags, {}))
}

module "key_vault_secret" {
  source = "../../modules/key-vault-secret"

  for_each = var.key_vault_secrets

  resource_group_name = local.resolve_resource_group_name["key_vault_secrets:${each.key}"]
  location            = local.resolve_location["key_vault_secrets:${each.key}"]
  name                = each.value.name
  key_vault_id        = try(each.value.key_vault_id, null)
  vault_key = try(each.value.vault_key, null) != null ? {
    name                = module.key_vault[each.value.vault_key].key_vault_name
    resource_group_name = local.resolve_resource_group_name["key_vaults:${each.value.vault_key}"]
  } : null
  secret_value             = try(each.value.secret_value, null)
  generate_random_password = try(each.value.generate_random_password, null)
  tags                     = merge(var.default_tags, try(each.value.tags, {}))
}

module "key_vault_key" {
  source = "../../modules/key-vault-key"

  for_each = var.key_vault_keys

  resource_group_name = local.resolve_resource_group_name["key_vault_keys:${each.key}"]
  location            = local.resolve_location["key_vault_keys:${each.key}"]
  name                = each.value.name
  key_vault_id        = try(each.value.key_vault_id, null)
  vault_key = try(each.value.vault_key, null) != null ? {
    name                = module.key_vault[each.value.vault_key].key_vault_name
    resource_group_name = local.resolve_resource_group_name["key_vaults:${each.value.vault_key}"]
  } : null
  key_type = try(each.value.key_type, "RSA")
  key_size = try(each.value.key_size, 2048)
  key_opts = try(each.value.key_opts, ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"])
  tags     = merge(var.default_tags, try(each.value.tags, {}))
}

module "vnet" {
  source = "../../modules/vnet"

  for_each = var.vnets

  name                   = each.value.name
  resource_group_name    = local.resolve_resource_group_name["vnets:${each.key}"]
  location               = local.resolve_location["vnets:${each.key}"]
  address_space          = each.value.address_space
  public_subnets         = each.value.public_subnets
  private_subnets        = each.value.private_subnets
  enable_nat_gateway     = try(each.value.enable_nat_gateway, true)
  single_nat_gateway     = try(each.value.single_nat_gateway, true)
  one_nat_gateway_per_az = try(each.value.one_nat_gateway_per_az, false)
  tags                   = merge(var.default_tags, try(each.value.tags, {}))

  depends_on = [module.resource_group]
}

module "nsg" {
  source = "../../modules/nsg"

  for_each = var.network_security_groups

  name                = each.value.name
  resource_group_name = local.resolve_resource_group_name["network_security_groups:${each.key}"]
  location            = local.resolve_location["network_security_groups:${each.key}"]
  vnet_id             = local.nsg_vnet_ids[each.key]
  description         = try(each.value.description, null)
  ingress_rules       = try(each.value.ingress_rules, [])
  egress_rules        = try(each.value.egress_rules, null)
  tags                = merge(var.default_tags, try(each.value.tags, {}))
}

module "load_balancer" {
  source = "../../modules/load-balancer"

  for_each = var.load_balancers

  name                = each.value.name
  resource_group_name = local.resolve_resource_group_name["load_balancers:${each.key}"]
  location            = local.resolve_location["load_balancers:${each.key}"]
  vnet_id             = module.vnet[each.value.vnet_key].vnet_id
  internal            = try(each.value.internal, false)
  subnet_ids          = local.load_balancer_subnet_ids[each.key]
  target_groups       = each.value.target_groups
  listeners           = each.value.listeners
  tags                = merge(var.default_tags, try(each.value.tags, {}))
}

module "application_gateway" {
  source = "../../modules/application-gateway"

  for_each = var.application_gateways

  name                = each.value.name
  resource_group_name = local.resolve_resource_group_name["application_gateways:${each.key}"]
  location            = local.resolve_location["application_gateways:${each.key}"]
  vnet_id             = module.vnet[each.value.vnet_key].vnet_id
  subnet_id           = local.application_gateway_subnet_ids[each.key]
  internal            = try(each.value.internal, false)
  enable_waf          = try(each.value.enable_waf, false)
  target_groups       = each.value.target_groups
  listeners           = each.value.listeners
  tags                = merge(var.default_tags, try(each.value.tags, {}))
}

module "function_app" {
  source = "../../modules/function-app"

  for_each = var.function_apps

  name                = each.value.name
  resource_group_name = local.resolve_resource_group_name["function_apps:${each.key}"]
  location            = local.resolve_location["function_apps:${each.key}"]
  os_type             = try(each.value.os_type, "Linux")
  service_plan_sku    = try(each.value.service_plan_sku, "Y1")
  runtime_name        = try(each.value.runtime_name, "python")
  runtime_version     = try(each.value.runtime_version, "3.12")
  package_source_dir  = try(each.value.package_source_dir, null)
  app_settings        = try(each.value.app_settings, {})
  storage_account_id = coalesce(
    try(each.value.storage_account_id, null),
    try(module.storage_account[each.value.storage_account_key].storage_account_id, null)
  )
  vnet_integration = coalesce(
    try(each.value.vnet_integration, null),
    try(each.value.vnet_key, null) != null ? {
      subnet_id = module.vnet[each.value.vnet_key].private_subnet_ids[each.value.subnet_key]
    } : null
  )
  tags = merge(var.default_tags, try(each.value.tags, {}))
}

module "cdn" {
  source = "../../modules/cdn"

  for_each = var.cdn_profiles

  name                = try(each.value.name, each.key)
  endpoint_name       = try(each.value.endpoint_name, "${each.key}-endpoint")
  resource_group_name = local.resolve_resource_group_name["cdn_profiles:${each.key}"]
  location            = local.resolve_location["cdn_profiles:${each.key}"]
  origin_host_name = coalesce(
    try(each.value.origin_host_name, null),
    try(module.storage_account[each.value.storage_account_key].primary_blob_host, null)
  )
  tags = merge(var.default_tags, try(each.value.tags, {}))
}

module "container_registry" {
  source = "../../modules/container-registry"

  for_each = var.container_registries

  name                = each.value.name
  resource_group_name = local.resolve_resource_group_name["container_registries:${each.key}"]
  location            = local.resolve_location["container_registries:${each.key}"]
  sku                 = try(each.value.sku, "Basic")
  admin_enabled       = try(each.value.admin_enabled, false)
  tags                = merge(var.default_tags, try(each.value.tags, {}))
}

module "rbac_role" {
  source = "../../modules/rbac-role"

  for_each = var.rbac_roles

  name                          = each.value.name
  resource_group_name           = local.resolve_resource_group_name["rbac_roles:${each.key}"]
  location                      = local.resolve_location["rbac_roles:${each.key}"]
  identity_type                 = try(each.value.identity_type, "user_assigned")
  create_user_assigned_identity = try(each.value.create_user_assigned_identity, true)
  existing_principal_id         = try(each.value.existing_principal_id, null)
  create_service_principal      = try(each.value.create_service_principal, true)
  application_display_name      = try(each.value.application_display_name, null)
  custom_role_definitions       = try(each.value.custom_role_definitions, {})
  role_assignments              = try(each.value.role_assignments, {})
  tags                          = merge(var.default_tags, try(each.value.tags, {}))
}

module "virtual_machine" {
  source = "../../modules/virtual-machine"

  for_each = var.virtual_machines

  name                = each.value.name
  resource_group_name = local.resolve_resource_group_name["virtual_machines:${each.key}"]
  location            = local.resolve_location["virtual_machines:${each.key}"]
  size                = each.value.size
  subnet_id = coalesce(
    try(each.value.subnet_id, null),
    try(module.vnet[each.value.vnet_key].private_subnet_ids[each.value.subnet_key], null),
    try(module.vnet[each.value.vnet_key].public_subnet_ids[each.value.subnet_key], null)
  )
  nsg_id = coalesce(
    try(each.value.nsg_id, null),
    try(module.nsg[each.value.nsg_key].network_security_group_id, null)
  )
  admin_username = try(each.value.admin_username, "azureuser")
  tags           = merge(var.default_tags, try(each.value.tags, {}))
}

module "postgresql_flexible" {
  source = "../../modules/postgresql-flexible"

  for_each = var.postgresql_servers

  name                = each.value.name
  resource_group_name = local.resolve_resource_group_name["postgresql_servers:${each.key}"]
  location            = local.resolve_location["postgresql_servers:${each.key}"]
  sku_name            = each.value.sku_name
  storage_mb          = try(each.value.storage_mb, 32768)
  administrator_login = each.value.administrator_login
  tags                = merge(var.default_tags, try(each.value.tags, {}))
}

module "api_management" {
  source = "../../modules/api-management"

  for_each = var.api_management_services

  name                = each.value.name
  resource_group_name = local.resolve_resource_group_name["api_management_services:${each.key}"]
  location            = local.resolve_location["api_management_services:${each.key}"]
  publisher_name      = each.value.publisher_name
  publisher_email     = each.value.publisher_email
  sku_name            = try(each.value.sku_name, "Developer_1")
  tags                = merge(var.default_tags, try(each.value.tags, {}))
}

module "service_bus_topic" {
  source = "../../modules/service-bus-topic"

  for_each = var.service_bus_topics

  resource_group_name = local.resolve_resource_group_name["service_bus_topics:${each.key}"]
  location            = local.resolve_location["service_bus_topics:${each.key}"]
  namespace_name      = each.value.namespace_name
  name                = try(each.value.name, each.key)
  subscriptions       = try(each.value.subscriptions, {})
  tags                = merge(var.default_tags, try(each.value.tags, {}))
}

module "service_bus_queue" {
  source = "../../modules/service-bus-queue"

  for_each = var.service_bus_queues

  resource_group_name = local.resolve_resource_group_name["service_bus_queues:${each.key}"]
  location            = local.resolve_location["service_bus_queues:${each.key}"]
  namespace_name      = try(each.value.namespace_name, "${each.key}-ns")
  name                = try(each.value.name, each.key)
  create_dlq          = try(each.value.create_dlq, false)
  tags                = merge(var.default_tags, try(each.value.tags, {}))
}

module "storage_queue" {
  source = "../../modules/storage-queue"

  for_each = var.storage_queues

  resource_group_name    = local.resolve_resource_group_name["storage_queues:${each.key}"]
  location               = local.resolve_location["storage_queues:${each.key}"]
  name                   = try(each.value.name, each.key)
  create_storage_account = try(each.value.create_storage_account, false)
  existing_storage_account_name = coalesce(
    try(each.value.existing_storage_account_name, null),
    try(each.value.storage_account_name, null),
    try(module.storage_account[each.value.storage_account_key].storage_account_name, null)
  )
  existing_storage_account_resource_group_name = coalesce(
    try(each.value.existing_storage_account_resource_group_name, null),
    try(local.resolve_resource_group_name["storage_accounts:${each.value.storage_account_key}"], null)
  )
  tags = merge(var.default_tags, try(each.value.tags, {}))
}

module "aks" {
  source = "../../modules/aks"

  for_each = var.aks_clusters

  name                = each.value.name
  resource_group_name = local.resolve_resource_group_name["aks_clusters:${each.key}"]
  location            = local.resolve_location["aks_clusters:${each.key}"]
  kubernetes_version  = each.value.kubernetes_version
  dns_prefix          = try(each.value.dns_prefix, each.value.name)
  subnet_ids = coalesce(
    try(each.value.subnet_ids, null),
    try(values(module.vnet[each.value.vnet_key].private_subnet_ids), null)
  )
  default_node_pool     = each.value.default_node_pool
  additional_node_pools = try(each.value.additional_node_pools, {})
  tags                  = merge(var.default_tags, try(each.value.tags, {}))
}

module "container_apps" {
  source = "../../modules/container-apps"

  for_each = var.container_apps

  name                = each.value.name
  resource_group_name = local.resolve_resource_group_name["container_apps:${each.key}"]
  location            = local.resolve_location["container_apps:${each.key}"]
  infrastructure_subnet_id = coalesce(
    try(each.value.infrastructure_subnet_id, null),
    try(module.vnet[each.value.vnet_key].private_subnet_ids[each.value.subnet_key], null)
  )
  container_apps = try(each.value.container_apps, each.value.apps)
  tags           = merge(var.default_tags, try(each.value.tags, {}))
}

module "storage_share" {
  source = "../../modules/storage-share"

  for_each = var.storage_shares

  name                = each.value.name
  resource_group_name = local.resolve_resource_group_name["storage_shares:${each.key}"]
  location            = local.resolve_location["storage_shares:${each.key}"]
  storage_account_name = coalesce(
    try(each.value.storage_account_name, null),
    try(module.storage_account[each.value.storage_account_key].storage_account_name, null)
  )
  quota_gb = try(each.value.quota_gb, 100)
  tags     = merge(var.default_tags, try(each.value.tags, {}))
}

module "aadb2c" {
  source = "../../modules/aadb2c"

  for_each = var.aadb2c_directories

  display_name        = each.value.display_name
  domain_name         = each.value.domain_name
  resource_group_name = local.resolve_resource_group_name["aadb2c_directories:${each.key}"]
  country_code        = try(each.value.country_code, "US")
  tags                = merge(var.default_tags, try(each.value.tags, {}))
}

module "event_hubs" {
  source = "../../modules/event-hubs"

  for_each = var.event_hubs_namespaces

  namespace_name      = each.value.namespace_name
  resource_group_name = local.resolve_resource_group_name["event_hubs_namespaces:${each.key}"]
  location            = local.resolve_location["event_hubs_namespaces:${each.key}"]
  sku                 = try(each.value.sku, "Standard")
  capacity            = try(each.value.capacity, 1)
  event_hub_name      = try(each.value.event_hub_name, "kafka")
  partition_count     = try(each.value.partition_count, 2)
  consumer_groups     = try(each.value.consumer_groups, [])
  tags                = merge(var.default_tags, try(each.value.tags, {}))
}
