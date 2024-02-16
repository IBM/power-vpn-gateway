variable "name" {
  type        = string
  description = "Name for Power Cloud Connection"
}

variable "power_workspace_id" {
  type        = string
  description = "GUID of the Power Workspace to create the connection for"
}

variable "cloud_connection_speed" {
  type        = number
  description = "Speed of the cloud connection (speed in megabits per second). Supported values are 50, 100, 200, 500, 1000, 2000, 5000, 10000."
}
