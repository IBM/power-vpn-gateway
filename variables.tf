##############################################################################
# Account Variables
##############################################################################

variable "ibmcloud_api_key" {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources"
  type        = string
  sensitive   = true
}

variable "power_workspace_location" {
  description = <<-EOD
    The location used to create the power workspace.

    Available locations are: dal10, dal12, us-south, us-east, wdc06, wdc07, sao01, sao04, tor01, mon01, eu-de-1, eu-de-2, lon04, lon06, syd04, syd05, tok04, osa21
    Please see [PowerVS Locations](https://cloud.ibm.com/docs/power-iaas?topic=power-iaas-creating-power-virtual-server) for an updated list.
  EOD
  type        = string
}

variable "resource_group_name" {
  description = <<-EOD
    Resource Group to create new resources in (Resource Group name is case sensitive).
  EOD
  type        = string
}

variable "name" {
  description = <<-EOD
    The name used for the new Power Workspace, Transit Gateway, and VPC.
    Other resources created will use this for their basename and be suffixed by a random identifier.
  EOD
  type        = string
}

variable "client_cidrs" {
  description = <<-EOD
    List of CIDRs for the client network to be routed by the VPN gateway to the Power and VPC network.

    Use the format ["cidr_1", "cidr_2"] to specify this variable.
  EOD
  type        = list(string)
}

variable "power_cidrs" {
  description = <<-EOD
    List of CIDRs for the PowerVS Workspace to be routed by the VPN gateway to the client network.
    Because these will be connected through Direct Link, please avoid using IPs in these CIDRs:
    10.0.0.0/14, 10.200.0.0/14, 10.198.0.0/15, and 10.254.0.0/16. Otherwise, they may not be
    routed through the VPN.

    Use the format ["cidr_1", "cidr_2"] to specify this variable.
  EOD
  type        = list(string)
}

variable "preshared_key" {
  description = <<-EOD
    Key configured on the peer gateway. The key is usually a complex string similar to a password, for example: 3j9atsxOzAtr1O1VEY.

    Preshared key must be at least 16 characters.
  EOD
  type        = string

  validation {
    condition     = length(var.preshared_key) >= 16
    error_message = "Preshared Key must be at least 16 characters."
  }

  validation {
    condition     = can(regex("^[-+&!@#$%^*(),.:_a-zA-Z0-9]+$", var.preshared_key))
    error_message = "Preshared key must match the pattern ^[-+&!@#$%^*(),.:_a-zA-Z0-9]+$"
  }
}

variable "peer_address" {
  description = "The peer address identifies the gateway address that is not within the address prefixes for your VPC."
  type        = string
}

variable "transit_gateway_name" {
  description = <<-EOD
    Optional variable to specify the name of an existing transit gateway, if supplied it will be assumed that you've connected
    your power workspace to it. A connection to the VPC containing the VPN Server will be added, but not for the Power Workspace.
    Supplying this variable will also suppress Power Workspace creation.
  EOD
  type        = string
  default     = ""
}

variable "power_cloud_connection_speed" {
  description = <<-EOD
    Optional variable to specify the speed of the cloud connection (speed in megabits per second).
    This only applies to locations WITHOUT Power Edge Routers.

    Supported values are 50, 100, 200, 500, 1000, 2000, 5000, 10000. Default Value is 1000.
  EOD
  type        = number
  default     = 1000
}

variable "power_workspace_name" {
  description = <<-EOD
    Optional variable to specify the name of an existing power workspace.
    If supplied the workspace will be used to connect the VPN with.
  EOD
  type        = string
  default     = ""
}

variable "vpn_subnet_cidr" {
  description = <<-EOD
    Optional variable to specify the CIDR for subnet the VPN will be in. You should only need to change this
    if you have a conflict with your Power Workspace Subnets or with a VPC connected with this solution.
  EOD
  type        = string
  default     = "10.134.0.0/28"
}

variable "identity_local" {
  description = "Optional local identity for VPN configuration. Must also specify `identity_remote`."
  type        = string
  default     = ""
}

variable "identity_remote" {
  description = "Optional remote identity for VPN configuration. Must also specify `identity_local`."
  type        = string
  default     = ""
}

variable "create_default_vpc_address_prefixes" {
  description = <<-EOD
    Optional variable to indicate whether a default address prefix should be created for each zone in this VPC.
  EOD
  type        = bool
  default     = true
}

variable "data_location_file_path" {
  description = <<-EOD
    Debug variable to indicated where the file with PER location data is stored.
    This variable is used for testing, and should not normally be altered.
  EOD
  type        = string
  default     = "./data/locations.yaml"
}

variable "vsi_vpn_ssh_key_name" {
  description = <<-EOD
    Debug variable to specify an existing ssh key by name to use with VPN VSI (identity support).
    Variables `identity_remote` and `identity_local` must also be specified.
  EOD
  type        = string
  default     = ""
}
