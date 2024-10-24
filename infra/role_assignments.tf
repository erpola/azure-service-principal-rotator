// azurerm role assignments

resource "azurerm_role_assignment" "key_vault_secrets_officer" {
  scope                = data.azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

resource "azurerm_role_assignment" "subnet_network_contributor" {
  count                = length(azurerm_subnet.subnet) > 0 ? 1 : 0
  scope                = azurerm_subnet.subnet[0].id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

resource "azurerm_role_assignment" "sa_sbdo" {
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
  role_definition_name = "Storage Blob Data Owner"
  scope                = azurerm_storage_account.sa.id
}

resource "azurerm_role_assignment" "sa_share_contributor" {
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
  role_definition_name = "Storage File Data SMB Share Contributor"
  scope                = azurerm_storage_account.sa.id
}

// azuread role assignments

data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
}

resource "azuread_app_role_assignment" "msgraph_user_read_all" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["User.ReadWrite.All"]
  principal_object_id = azurerm_user_assigned_identity.identity.principal_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

resource "azuread_app_role_assignment" "msgraph_application_readwrite_all" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.All"]
  principal_object_id = azurerm_user_assigned_identity.identity.principal_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}