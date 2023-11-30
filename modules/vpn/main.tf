data "ibm_is_vpc_address_prefixes" "vpc" {
  vpc = var.vpc_id
}

data "ibm_is_vpc" "vpn" {
  identifier = var.vpc_id
}

data "ibm_is_image" "vpn_base" {
  name = var.vsi_vpn_base_image_name
}

# Both local and remote identities must be specified to use VSI VPN
locals {
  use_vsi_vpn = var.identity_local != "" && var.identity_remote != "" ? true : false
  local_cidrs = concat(var.additional_local_cidrs, data.ibm_is_vpc_address_prefixes.vpc.address_prefixes[*].cidr)
  cidr_map    = { for idx, val in var.client_cidrs : idx => val }
  region      = format("%s-%s", split("-", var.zone)[0], split("-", var.zone)[1])
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
  count          = local.use_vsi_vpn ? 0 : 1
  name           = var.name
  subnet         = ibm_is_subnet.subnet.id
  resource_group = var.resource_group_id
  mode           = "policy"
}

resource "ibm_is_vpn_gateway_connection" "conn" {
  count          = local.use_vsi_vpn ? 0 : 1
  name           = format("%s-%s", var.name, "connection")
  vpn_gateway    = ibm_is_vpn_gateway.vpc[0].id
  peer_address   = var.peer_address
  peer_cidrs     = var.client_cidrs
  local_cidrs    = local.local_cidrs
  preshared_key  = var.preshared_key
  admin_state_up = true
}

resource "ibm_is_security_group" "vpn" {
  count          = local.use_vsi_vpn ? 1 : 0
  name           = format("%s-%s", var.name, "vpn-sg")
  vpc            = var.vpc_id
  resource_group = var.resource_group_id
}

resource "ibm_is_security_group_rule" "ike_phase_1" {
  count     = local.use_vsi_vpn ? 1 : 0
  direction = "inbound"
  group     = ibm_is_security_group.vpn[0].id
  remote    = var.peer_address
  udp {
    port_min = 500
    port_max = 500
  }
}

resource "ibm_is_security_group_rule" "ike_phase_2" {
  count     = local.use_vsi_vpn ? 1 : 0
  direction = "inbound"
  group     = ibm_is_security_group.vpn[0].id
  remote    = var.peer_address
  udp {
    port_min = 4500
    port_max = 4500
  }
}

# These CIDRs may be represented outside of VPC, we need to
# allow them ingress to the VPN so they can be routed out.
resource "ibm_is_security_group_rule" "ingress_additional" {
  count     = local.use_vsi_vpn ? length(var.additional_local_cidrs) : 0
  direction = "inbound"
  group     = ibm_is_security_group.vpn[0].id
  remote    = var.additional_local_cidrs[count.index]
}

resource "ibm_is_security_group_rule" "out_all" {
  count     = local.use_vsi_vpn ? 1 : 0
  direction = "outbound"
  group     = ibm_is_security_group.vpn[0].id
  remote    = "0.0.0.0/0"
}

resource "ibm_is_floating_ip" "vpn" {
  count          = local.use_vsi_vpn ? 1 : 0
  name           = format("%s-%s", var.name, "fip")
  resource_group = var.resource_group_id
  zone           = var.zone
}

data "ibm_is_ssh_key" "vpn" {
  count = local.use_vsi_vpn ? var.vsi_vpn_ssh_key_name != "" ? 1 : 0 : 0
  name  = var.vsi_vpn_ssh_key_name
}

locals {
  libreswan_configuration = templatefile(format("%s/%s", path.module, "templates/pvs.conf.tpl"), {
    identity_local  = var.identity_local,
    identity_remote = var.identity_remote,
    peer_address    = var.peer_address,
    client_cidrs    = join(",", var.client_cidrs),
    local_cidrs     = join(",", local.local_cidrs)
  })
  libreswan_secrets = templatefile(format("%s/%s", path.module, "templates/pvs.secrets.tpl"), {
    identity_local  = var.identity_local,
    identity_remote = var.identity_remote,
    preshared_key   = var.preshared_key
  })
}

resource "ibm_is_instance" "vpn" {
  count   = local.use_vsi_vpn ? 1 : 0
  name    = format("%s-%s", var.name, "vpn")
  image   = data.ibm_is_image.vpn_base.id
  profile = var.vsi_vpn_profile
  primary_network_interface {
    subnet            = ibm_is_subnet.subnet.id
    security_groups   = [ibm_is_security_group.vpn[0].id]
    allow_ip_spoofing = true
  }
  vpc  = var.vpc_id
  zone = var.zone
  keys = var.vsi_vpn_ssh_key_name == "" ? [] : [data.ibm_is_ssh_key.vpn[0].id]
  user_data = format("%s\n%s", "#cloud-config", yamlencode({
    write_files = [
      {
        content     = file(format("%s/%s", path.module, "scripts/vpn.sh"))
        path        = "/tmp/vpn.sh"
        permissions = "0755"
        owner       = "root"
      },
      {
        content     = local.libreswan_configuration
        path        = "/etc/ipsec.d/pvs.conf"
        permissions = "0600"
        owner       = "root"
      },
      {
        content     = local.libreswan_secrets
        path        = "/etc/ipsec.d/pvs.secrets"
        permissions = "0600"
        owner       = "root"
      },
      {
        content     = file(format("%s/%s", path.module, "conf/95-ipsec.conf"))
        path        = "/etc/sysctl.d/95-ipsec.conf"
        permissions = "0600"
        owner       = "root"
      },
      {
        content     = file(format("%s/%s", path.module, "conf/iptables.conf"))
        path        = "/etc/sysconfig/iptables"
        permissions = "0600"
        owner       = "root"
      }
    ],
    runcmd = [
      "/tmp/vpn.sh"
    ]
  }))
  resource_group = var.resource_group_id
}

resource "ibm_is_instance_network_interface_floating_ip" "vpn" {
  count             = local.use_vsi_vpn ? 1 : 0
  instance          = ibm_is_instance.vpn[0].id
  network_interface = ibm_is_instance.vpn[0].primary_network_interface[0].id
  floating_ip       = ibm_is_floating_ip.vpn[0].id
}

# Allows VPN Server <=> Transit Gateway traffic
resource "ibm_is_vpc_routing_table" "transit" {
  vpc                              = ibm_is_subnet.subnet.vpc
  name                             = format("%s-%s", var.name, "route-table-vpn-server-transit")
  route_transit_gateway_ingress    = true
  accept_routes_from_resource_type = local.use_vsi_vpn ? [] : ["vpn_gateway"]
}

# Set next hop for client addresses for Power routes
# Only needed when we are deploying the VSI VPN
resource "ibm_is_vpc_routing_table_route" "transit_vpn_vsi" {
  count         = local.use_vsi_vpn ? length(local.cidr_map) : 0
  vpc           = var.vpc_id
  routing_table = ibm_is_vpc_routing_table.transit.routing_table
  zone          = var.zone
  name          = format("%s-%s-%s", var.name, "transit-vpn-vsi", count.index)
  destination   = local.cidr_map[count.index]
  action        = "deliver"
  next_hop      = ibm_is_instance.vpn[0].primary_network_interface[0].primary_ip[0].address
}

# Set next hop for client addresses for VPC default routes
# Only needed when we are deploying the VSI VPN
# Each zone needs to include the client routes
resource "ibm_is_vpc_routing_table_route" "vpc_vpn_vsi" {
  count         = local.use_vsi_vpn ? length(local.cidr_map) * 3 : 0
  vpc           = var.vpc_id
  routing_table = data.ibm_is_vpc.vpn.default_routing_table
  zone          = format("%s-%s", local.region, (count.index % 3) + 1)
  name          = format("%s-%s-%s", var.name, "default-vpn-vsi", count.index)
  destination   = local.cidr_map[floor(count.index / 3)]
  action        = "deliver"
  next_hop      = ibm_is_instance.vpn[0].primary_network_interface[0].primary_ip[0].address
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
  cidr     = split("/", each.value)[1] > 29 ? format("%s/29", cidrhost(format("%s/29", split("/", each.value)[0]), 0)) : each.value
}
