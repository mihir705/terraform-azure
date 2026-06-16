resource "azurerm_aadb2c_directory" "directory" {
  country_code           = var.country_code
  data_residency_location = coalesce(var.data_residency_location, var.country_code)
  display_name            = var.display_name
  domain_name            = var.domain_name
  resource_group_name    = var.resource_group_name
  sku_name               = var.sku_name

  tags = merge(var.tags, {
    Name = var.display_name
  })
}
