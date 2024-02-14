variable "name" {
  type        = string
  description = "Name for the transit gateway. If the transit gateway exists, it will be used to add then connections supplied"
}

variable "connections" {
  type = list(object({
    network_type = string,
    network_id   = string
  }))
  default     = []
  description = "list of connections to add to transit gateway"
}

variable "resource_group_id" {
  description = "Resource group ID to create the transit gateway in"
  type        = string
}

variable "region" {
  description = "IBM Cloud region"
  type        = string
}
