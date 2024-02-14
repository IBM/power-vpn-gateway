variable "name" {
  type        = string
  description = "Name of the PowerVS Workspace"
}

variable "location" {
  type        = string
  description = "Location of PowerVS Workspace"
}

variable "resource_group_id" {
  description = "Resource group ID to create the power workspace in"
  type        = string
}
