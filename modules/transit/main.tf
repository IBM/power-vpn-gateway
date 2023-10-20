# Look up transit gateways to see if one exists with the name supplied
# if it exists use it if not create a new one
# create connections for connections supplied

data "ibm_tg_gateways" "all" {}

locals {
  is_existing_gateway = contains(data.ibm_tg_gateways.all.transit_gateways[*].name, var.name)
  existing_gateways   = local.is_existing_gateway ? [data.ibm_tg_gateways.all.transit_gateways[index(data.ibm_tg_gateways.all.transit_gateways[*].name, var.name)]] : []
}

resource "ibm_tg_gateway" "new" {
  count          = length(local.existing_gateways) == 0 ? 1 : 0
  name           = var.name
  global         = false
  location       = var.region
  resource_group = var.resource_group_id
}

locals {
  gateway         = local.is_existing_gateway ? one(local.existing_gateways) : ibm_tg_gateway.new[0]
  connections_map = { for idx, val in var.connections : idx => val }
}

resource "ibm_tg_connection" "conn" {
  for_each     = local.connections_map
  gateway      = local.gateway.id
  network_type = each.value.network_type
  network_id   = each.value.network_id
  name         = format("%s-%s", var.name, each.key)
}
