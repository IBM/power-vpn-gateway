##############################################################################
# Terraform Main IaC
##############################################################################
# Generate random identifier
resource "random_string" "resource_identifier" {
  length  = 5
  upper   = false
  numeric = false
  lower   = true
  special = false
}

locals {
  uname = format("%s-%s", var.name, random_string.resource_identifier.result)
}

data "ibm_resource_group" "group" {
  name = var.resource_group_name
}

module "vpc" {
  source                    = "./modules/vpc"
  name                      = var.name
  resource_group_id         = data.ibm_resource_group.group.id
  address_prefix_management = var.create_default_vpc_address_prefixes ? "auto" : "manual"
}

module "vpn" {
  source                 = "./modules/vpn"
  name                   = var.name
  resource_group_id      = data.ibm_resource_group.group.id
  client_cidrs           = var.client_cidrs
  additional_local_cidrs = var.power_cidrs
  subnet_cidr            = var.vpn_subnet_cidr
  zone                   = local.location.vpc_zone
  vpc_id                 = module.vpc.vpc.id
  preshared_key          = var.preshared_key
  peer_address           = var.peer_address
  identity_local         = var.identity_local
  identity_remote        = var.identity_remote
  vsi_vpn_ssh_key_name   = var.vsi_vpn_ssh_key_name
}

# If a power workspace name is provided, look it up
data "ibm_resource_instance" "power_workspace" {
  count   = var.power_workspace_name == "" ? 0 : 1
  name    = var.power_workspace_name
  service = "power-iaas"
}

# Only create a new power workspace when neither an existing
# power workspace or transit gateway are supplied
module "power" {
  count             = var.power_workspace_name == "" && var.transit_gateway_name == "" ? 1 : 0
  source            = "./modules/power"
  name              = var.name
  resource_group_id = data.ibm_resource_group.group.id
  location          = var.power_workspace_location
}

locals {
  power_workspace = var.transit_gateway_name == "" ? var.power_workspace_name == "" ? module.power[0].workspace : data.ibm_resource_instance.power_workspace[0] : null
  per_enabled     = var.per_override ? true : local.location.per_enabled
}

# For locations that are not PER enabled create a Cloud Connection that is Transit Gateway enabled.
# This allows us to use the Directlink connection it created and attach it to our Transit Gateway.
# If an existing Transit Gateway is supplied, we assume that this connection (or PER) is already
# connected to the Transit Gateway and will not create the cloud connection to enable it.
module "cloud_connection" {
  count                  = var.transit_gateway_name != "" || local.per_enabled ? 0 : 1
  source                 = "./modules/cloud-connection"
  name                   = local.uname
  cloud_connection_speed = var.power_cloud_connection_speed
  power_workspace_id     = local.power_workspace.guid
  providers              = { ibm = ibm.power }
}

# Connect the VPC and Power Workspace to the Transit Gateway
# If the Workspace is PER enabled it maybe directly connected to
# the Gateway, otherwise the Directlink Gateway created by
# the Cloud Connection is used. If a Transit Gateway is
# supplied, only create the VPC connection.
locals {
  vpc_connection = {
    network_type = "vpc"
    network_id   = module.vpc.vpc.crn
  }
  power_connection = {
    network_type = "power_virtual_server"
    network_id   = var.transit_gateway_name == "" ? local.power_workspace.id : ""
  }
  directlink_connection = {
    network_type = "directlink"
    network_id   = length(module.cloud_connection) == 0 ? "" : module.cloud_connection[0].dl_gateway.crn
  }
  connections = var.transit_gateway_name != "" ? [local.vpc_connection] : local.per_enabled ? [local.vpc_connection, local.power_connection] : [local.vpc_connection, local.directlink_connection]
}

module "transit" {
  source            = "./modules/transit"
  name              = var.transit_gateway_name == "" ? var.name : var.transit_gateway_name
  region            = local.location.vpc_region
  resource_group_id = data.ibm_resource_group.group.id
  connections       = local.connections
}
