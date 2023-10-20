variable "vpc_id" {
  description = "VPC ID of VPC where VPN will be created"
  type        = string
}

variable "zone" {
  description = "Zone where VPN will be located"
  type        = string
}

variable "client_cidrs" {
  description = "CIDRs in peer gatway to be routed by this gateway"
  type        = list(string)
}

variable "subnet_cidr" {
  description = "CIDR for VPN server ip space"
  type        = string
}

variable "name" {
  description = "basename used for resources created"
  type        = string
}

variable "resource_group_id" {
  description = "Resource group ID to create VPN in"
  type        = string
}

variable "peer_address" {
  description = "Address of peer (remote) VPN"
  type        = string
}

variable "preshared_key" {
  description = "Preshare key shared between the peer gateway"
  type        = string
  sensitive   = true
}

variable "additional_local_cidrs" {
  description = "Additional CIDRs to be routed by the VPN Gateway (VPC address prefixes are included by default)"
  type        = list(string)
  default     = []
}
