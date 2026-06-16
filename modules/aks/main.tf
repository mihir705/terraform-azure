locals {
  default_node_pool_subnet_id = coalesce(
    try(var.default_node_pool.subnet_id, null),
    var.subnet_ids[0]
  )
}

check "subnet_count" {
  assert {
    condition     = length(var.subnet_ids) >= 1
    error_message = "At least one subnet_id is required."
  }
}

check "default_node_pool_scaling" {
  assert {
    condition = (
      !try(var.default_node_pool.enable_auto_scaling, false) ||
      (
        try(var.default_node_pool.min_count, null) != null &&
        try(var.default_node_pool.max_count, null) != null
      )
    )
    error_message = "default_node_pool min_count and max_count are required when enable_auto_scaling is true."
  }
}

check "additional_node_pool_scaling" {
  assert {
    condition = alltrue([
      for pool in var.additional_node_pools :
      !try(pool.enable_auto_scaling, false) || (
        try(pool.min_count, null) != null &&
        try(pool.max_count, null) != null
      )
    ])
    error_message = "Each additional node pool requires min_count and max_count when enable_auto_scaling is true."
  }
}

check "network_policy_plugin" {
  assert {
    condition     = var.network_policy == null || var.network_plugin == "azure"
    error_message = "network_policy requires network_plugin = azure."
  }
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  private_cluster_enabled           = var.private_cluster_enabled
  local_account_disabled            = var.local_account_disabled
  role_based_access_control_enabled = var.role_based_access_control_enabled
  azure_policy_enabled              = false

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.azure_rbac_enabled ? [1] : []

    content {
      azure_rbac_enabled     = true
      admin_group_object_ids = var.admin_group_object_ids
    }
  }

  default_node_pool {
    name                         = try(var.default_node_pool.name, "system")
    vm_size                      = var.default_node_pool.vm_size
    node_count             = try(var.default_node_pool.enable_auto_scaling, false) ? null : try(var.default_node_pool.node_count, 1)
    min_count              = try(var.default_node_pool.enable_auto_scaling, false) ? try(var.default_node_pool.min_count, null) : null
    max_count              = try(var.default_node_pool.enable_auto_scaling, false) ? try(var.default_node_pool.max_count, null) : null
    enable_auto_scaling  = try(var.default_node_pool.enable_auto_scaling, false)
    os_disk_size_gb        = try(var.default_node_pool.os_disk_size_gb, 128)
    os_disk_type           = try(var.default_node_pool.os_disk_type, "Managed")
    os_sku                 = try(var.default_node_pool.os_sku, "Ubuntu")
    zones                  = try(var.default_node_pool.zones, null)
    max_pods               = try(var.default_node_pool.max_pods, null)
    node_labels            = try(var.default_node_pool.node_labels, null)
    vnet_subnet_id         = local.default_node_pool_subnet_id
    only_critical_addons_enabled = try(var.default_node_pool.only_critical_addons_enabled, false)
  }

  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    pod_cidr          = var.network_plugin == "kubenet" ? var.pod_cidr : null
    outbound_type     = var.outbound_type
    load_balancer_sku = "standard"
  }

  dynamic "identity" {
    for_each = [var.identity]

    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  dynamic "oms_agent" {
    for_each = var.oms_agent != null ? [var.oms_agent] : []

    content {
      log_analytics_workspace_id = oms_agent.value.log_analytics_workspace_id
    }
  }

  dynamic "microsoft_defender" {
    for_each = var.microsoft_defender_enabled && var.oms_agent != null ? [1] : []

    content {
      log_analytics_workspace_id = var.oms_agent.log_analytics_workspace_id
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.additional_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  node_count            = try(each.value.enable_auto_scaling, false) ? null : try(each.value.node_count, 1)
  min_count             = try(each.value.enable_auto_scaling, false) ? try(each.value.min_count, null) : null
  max_count             = try(each.value.enable_auto_scaling, false) ? try(each.value.max_count, null) : null
  enable_auto_scaling = try(each.value.enable_auto_scaling, false)
  os_disk_size_gb       = try(each.value.os_disk_size_gb, 128)
  os_disk_type          = try(each.value.os_disk_type, "Managed")
  os_sku                = try(each.value.os_sku, "Ubuntu")
  zones                 = try(each.value.zones, null)
  max_pods              = try(each.value.max_pods, null)
  node_labels           = try(each.value.node_labels, null)
  node_taints           = try(each.value.node_taints, null)
  vnet_subnet_id        = coalesce(try(each.value.subnet_id, null), local.default_node_pool_subnet_id)
  mode                  = try(each.value.mode, "User")
  priority              = try(each.value.priority, "Regular")
  spot_max_price        = try(each.value.priority, "Regular") == "Spot" ? try(each.value.spot_max_price, -1) : null
  eviction_policy       = try(each.value.priority, "Regular") == "Spot" ? try(each.value.eviction_policy, "Delete") : null

  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
  })
}
