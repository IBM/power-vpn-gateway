data "ibm_is_vpc_address_prefixes" "vpc" {
  vpc = var.vpc_id
}

# Wait for the data lookup of existing address prefixes
# We want to exclude this address prefix when adding to
# the routed local prefixes of the gateway connection
resource "ibm_is_vpc_address_prefix" "prefix" {
  depends_on = [
    data.ibm_is_vpc_address_prefixes.vpc
  ]

  name = format("%s-%s", var.name, "prefix")
  zone = var.zone
  vpc  = var.vpc_id
  cidr = var.subnet_cidr
}

resource "ibm_is_subnet" "subnet" {
  depends_on = [
    ibm_is_vpc_address_prefix.prefix
  ]

  ipv4_cidr_block = var.subnet_cidr
  name            = format("%s-%s", var.name, "subnet")
  vpc             = var.vpc_id
  zone            = var.zone
  resource_group  = var.resource_group_id
}

resource "ibm_is_vpn_gateway" "vpc" {
  name           = var.name
  subnet         = ibm_is_subnet.subnet.id
  resource_group = var.resource_group_id
  mode           = "policy"
}

resource "ibm_is_vpn_gateway_connection" "conn" {
  name           = format("%s-%s", var.name, "connection")
  vpn_gateway    = ibm_is_vpn_gateway.vpc.id
  peer_address   = var.peer_address
  peer_cidrs     = var.client_cidrs
  local_cidrs    = concat(var.additional_local_cidrs, data.ibm_is_vpc_address_prefixes.vpc.address_prefixes[*].cidr)
  preshared_key  = var.preshared_key
  admin_state_up = true
}

# Allows VPN Server <=> Transit Gateway traffic
resource "ibm_is_vpc_routing_table" "transit" {
  vpc                              = ibm_is_subnet.subnet.vpc
  name                             = format("%s-%s", var.name, "route-table-vpn-server-transit")
  route_transit_gateway_ingress    = true
  accept_routes_from_resource_type = ["vpn_gateway"]
}

locals {
  cidr_map = { for idx, val in var.client_cidrs : idx => val }
}

# Allows VPN Clients <=> Transit Gateway traffic
resource "ibm_is_vpc_address_prefix" "client_prefix" {
  depends_on = [
    ibm_is_vpn_gateway_connection.conn
  ]

  for_each = local.cidr_map
  name     = format("%s-%s-%s", var.name, "prefix-vpn-client", each.key)
  zone     = var.zone
  vpc      = var.vpc_id
  cidr     = each.value
}
