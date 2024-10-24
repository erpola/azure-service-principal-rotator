resource "azurerm_storage_account" "sa" {
  name                     = replace("${local.prefix}${random_id.rid.hex}sa", "-", "")
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
}