resource "ibm_is_vpc" "vpn_vpc" {
  name           = var.name
  resource_group = var.resource_group_id
}
