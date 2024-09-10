variable "name" {
  description = "Name used for resources created"
  type        = string
}

variable "resource_group_id" {
  description = "Resource group ID to create VPC in"
  type        = string
}

variable "address_prefix_management" {
  description = "Indicates whether a default address prefix should be created automatically `auto` or manually `manual` for each zone in this VPC"
  type        = string
}
