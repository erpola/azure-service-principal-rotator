subscription_id = "<your-subscription-id>"
project         = "sp-rotator"
location        = "<your-desired-location>"
environment     = "<your-environment>"

target_key_vault_name                      = "<the-name-of-your-key-vault>"
target_key_vault_resource_group_name       = "<the-name-of-the-resource-group-the-key-vault-is-in>"
target_key_vault_rotation_interval_in_days = "<the-number-of-days-between-key-rotations>"
run_cleanup                                = "<if-1-the-function-will-remove-any-old-keys>"

subnet_base_cidr                    = "<the-base-cidr-for-the-subnets>"
virtual_network_name                = "<the-name-of-the-virtual-network>"
virtual_network_resource_group_name = "<the-name-of-the-resource-group-the-virtual-network-is-in>"
public_network_access_enabled       = "<if-true-the-subnet-will-have-public-network-access-enabled>"