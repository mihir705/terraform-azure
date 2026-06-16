locals {
  apis = {
    for key, api in var.apis : key => {
      name                  = coalesce(try(api.name, null), key)
      display_name          = api.display_name
      path                  = api.path
      protocols             = api.protocols
      revision              = api.revision
      revision_description  = try(api.revision_description, null)
      service_url           = try(api.service_url, null)
      subscription_required = api.subscription_required
      import                = try(api.import, null)
    }
  }
}

check "apis_required" {
  assert {
    condition     = length(var.apis) > 0
    error_message = "At least one API is required."
  }
}

check "operation_api_keys" {
  assert {
    condition = alltrue([
      for operation in var.operations :
      contains(keys(var.apis), operation.api_key)
    ])
    error_message = "Each operation must reference a valid api_key."
  }
}

check "product_api_keys" {
  assert {
    condition = alltrue([
      for product in var.products :
      alltrue([
        for api_key in coalesce(try(product.api_keys, null), []) :
        contains(keys(var.apis), api_key)
      ])
    ])
    error_message = "Each product api_keys entry must reference a defined API."
  }
}

check "subnet_required_for_vnet" {
  assert {
    condition     = var.virtual_network_type == "None" || var.subnet_id != null
    error_message = "subnet_id is required when virtual_network_type is External or Internal."
  }
}

check "backend_protocols" {
  assert {
    condition = alltrue([
      for backend in var.backends :
      contains(["http", "soap"], backend.protocol)
    ])
    error_message = "backend protocol must be http or soap."
  }
}

check "operation_methods" {
  assert {
    condition = alltrue([
      for operation in var.operations :
      contains(["GET", "PUT", "POST", "DELETE", "PATCH", "HEAD", "OPTIONS", "TRACE"], upper(operation.method))
    ])
    error_message = "operation method must be a valid HTTP verb."
  }
}

resource "azurerm_api_management" "service" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name

  virtual_network_type = var.virtual_network_type

  dynamic "virtual_network_configuration" {
    for_each = var.virtual_network_type != "None" ? [1] : []

    content {
      subnet_id = var.subnet_id
    }
  }

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []

    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" ? var.user_assigned_identity_ids : null
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "azurerm_api_management_backend" "backend" {
  for_each = var.backends

  name                = each.key
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.service.name
  protocol            = each.value.protocol
  url                 = each.value.url
  description         = try(each.value.description, null)

  dynamic "tls" {
    for_each = try(each.value.tls, null) != null ? [each.value.tls] : []

    content {
      validate_certificate_chain = tls.value.validate_certificate_chain
      validate_certificate_name  = tls.value.validate_certificate_name
    }
  }
}

resource "azurerm_api_management_api" "api" {
  for_each = local.apis

  name                  = each.value.name
  resource_group_name   = var.resource_group_name
  api_management_name   = azurerm_api_management.service.name
  revision              = each.value.revision
  display_name          = each.value.display_name
  path                  = each.value.path
  protocols             = each.value.protocols
  revision_description  = each.value.revision_description
  service_url           = each.value.service_url
  subscription_required = each.value.subscription_required

  dynamic "import" {
    for_each = each.value.import != null ? [each.value.import] : []

    content {
      content_format = import.value.content_format
      content_value  = import.value.content_value
    }
  }
}

resource "azurerm_api_management_api_operation" "operation" {
  for_each = var.operations

  operation_id        = each.value.operation_id
  api_name            = azurerm_api_management_api.api[each.value.api_key].name
  api_management_name = azurerm_api_management.service.name
  resource_group_name = var.resource_group_name
  display_name        = each.value.display_name
  method              = upper(each.value.method)
  url_template        = each.value.url_template
  description         = try(each.value.description, null)

  dynamic "template_parameter" {
    for_each = coalesce(try(each.value.template_parameter, null), {})

    content {
      name        = template_parameter.key
      type        = template_parameter.value.type
      required    = template_parameter.value.required
      description = try(template_parameter.value.description, null)
    }
  }
}

resource "azurerm_api_management_product" "product" {
  for_each = var.products

  product_id            = coalesce(try(each.value.product_id, null), each.key)
  api_management_name   = azurerm_api_management.service.name
  resource_group_name   = var.resource_group_name
  display_name          = each.value.display_name
  description           = try(each.value.description, null)
  subscription_required = each.value.subscription_required
  approval_required     = each.value.approval_required
  published             = each.value.published
}

resource "azurerm_api_management_product_api" "product_api" {
  for_each = {
    for item in flatten([
      for product_key, product in var.products : [
        for api_key in coalesce(try(product.api_keys, null), []) : {
          id          = "${product_key}-${api_key}"
          product_key = product_key
          api_key     = api_key
        }
      ]
    ]) : item.id => item
  }

  api_name            = azurerm_api_management_api.api[each.value.api_key].name
  product_id          = azurerm_api_management_product.product[each.value.product_key].product_id
  api_management_name = azurerm_api_management.service.name
  resource_group_name = var.resource_group_name
}
