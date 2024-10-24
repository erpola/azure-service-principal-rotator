data "azurerm_key_vault" "kv" {
  name                = var.target_key_vault_name
  resource_group_name = var.target_key_vault_resource_group_name
}

data "azuread_application_published_app_ids" "well_known" {}