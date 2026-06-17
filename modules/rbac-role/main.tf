locals {
  user_assigned_identity_name = coalesce(var.user_assigned_identity_name, var.name)
  application_display_name    = coalesce(var.application_display_name, var.name)

  principal_id = (
    var.identity_type == "existing_principal" ? var.existing_principal_id :
    var.identity_type == "user_assigned" ? (
      var.create_user_assigned_identity ? azurerm_user_assigned_identity.identity[0].principal_id : null
    ) :
    var.create_service_principal ? azuread_service_principal.sp[0].object_id : null
  )

  custom_role_definition_ids = {
    for key, role in azurerm_role_definition.custom :
    key => role.role_definition_resource_id
  }
}

check "user_assigned_location_required" {
  assert {
    condition = var.identity_type != "user_assigned" || !var.create_user_assigned_identity || (
      var.resource_group_name != null && var.location != null
    )
    error_message = "resource_group_name and location are required when creating a user-assigned identity."
  }
}

check "existing_principal_required" {
  assert {
    condition     = var.identity_type != "existing_principal" || var.existing_principal_id != null
    error_message = "existing_principal_id is required when identity_type is existing_principal."
  }
}

check "service_principal_display_name" {
  assert {
    condition = var.identity_type != "service_principal" || !var.create_service_principal || (
      local.application_display_name != null && local.application_display_name != ""
    )
    error_message = "application_display_name is required when creating a service principal."
  }
}

check "role_assignment_source_exclusive" {
  assert {
    condition = alltrue([
      for assignment in var.role_assignments :
      length(compact([
        try(assignment.role_definition_id, null),
        try(assignment.role_definition_name, null),
        try(assignment.custom_role_definition_key, null),
      ])) == 1
    ])
    error_message = "Each role assignment must set exactly one of role_definition_id, role_definition_name, or custom_role_definition_key."
  }
}

check "custom_role_assignment_keys" {
  assert {
    condition = alltrue([
      for assignment in var.role_assignments :
      try(assignment.custom_role_definition_key, null) == null ||
      contains(keys(var.custom_role_definitions), assignment.custom_role_definition_key)
    ])
    error_message = "Each custom_role_definition_key must reference a defined custom role."
  }
}

check "custom_role_permissions" {
  assert {
    condition = alltrue([
      for role in var.custom_role_definitions :
      length(role.permissions.actions) > 0 ||
      length(role.permissions.not_actions) > 0 ||
      length(role.permissions.data_actions) > 0 ||
      length(role.permissions.not_data_actions) > 0
    ])
    error_message = "Each custom role must define at least one permission action set."
  }
}

resource "azurerm_user_assigned_identity" "identity" {
  count = var.identity_type == "user_assigned" && var.create_user_assigned_identity ? 1 : 0

  name                = local.user_assigned_identity_name
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = merge(var.tags, {
    Name = local.user_assigned_identity_name
  })
}

resource "azuread_application" "app" {
  count = var.identity_type == "service_principal" && var.create_service_principal ? 1 : 0

  display_name     = local.application_display_name
  sign_in_audience = var.sign_in_audience
}

resource "azuread_service_principal" "sp" {
  count = var.identity_type == "service_principal" && var.create_service_principal ? 1 : 0

  client_id = azuread_application.app[0].client_id
}

resource "azurerm_role_definition" "custom" {
  for_each = var.custom_role_definitions

  name        = coalesce(try(each.value.role_name, null), "${var.name}-${each.key}")
  scope       = each.value.scope
  description = try(each.value.description, "Custom role ${each.key} for ${var.name}")

  permissions {
    actions          = each.value.permissions.actions
    not_actions      = each.value.permissions.not_actions
    data_actions     = each.value.permissions.data_actions
    not_data_actions = each.value.permissions.not_data_actions
  }

  assignable_scopes = coalesce(
    try(each.value.assignable_scopes, null),
    [each.value.scope]
  )
}

resource "azurerm_role_assignment" "assignment" {
  for_each = var.role_assignments

  scope              = each.value.scope
  role_definition_id = coalesce(
    try(each.value.role_definition_id, null),
    try(each.value.custom_role_definition_key, null) != null ? local.custom_role_definition_ids[each.value.custom_role_definition_key] : null,
    try(data.azurerm_role_definition.builtin[each.key].id, null)
  )
  principal_id = local.principal_id
  description          = try(each.value.description, null)
}

data "azurerm_role_definition" "builtin" {
  for_each = {
    for key, assignment in var.role_assignments :
    key => assignment
    if try(assignment.role_definition_name, null) != null && try(assignment.role_definition_id, null) == null && try(assignment.custom_role_definition_key, null) == null
  }

  name  = each.value.role_definition_name
  scope = each.value.scope
}
