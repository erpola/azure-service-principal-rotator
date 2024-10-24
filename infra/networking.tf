resource "azurerm_subnet" "subnet" {
  count                = (var.virtual_network_name != "" && var.target_key_vault_resource_group_name != "") ? 1 : 0
  name                 = "${local.prefix}-snet"
  address_prefixes     = [var.subnet_base_cidr]
  resource_group_name  = var.virtual_network_resource_group_name
  virtual_network_name = var.virtual_network_name

  delegation {
    name = "${local.prefix}-snet-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}