resource "azurerm_application_insights" "ai" {
  name                = "${local.prefix}-ai"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  tags                = local.tags
}