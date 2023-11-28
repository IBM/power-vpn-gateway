locals {
  service_type = "power-iaas"
  plan         = "power-virtual-server-group"
}

resource "ibm_resource_instance" "powervs_workspace" {
  name              = var.name
  service           = local.service_type
  plan              = local.plan
  location          = var.location
  resource_group_id = var.resource_group_id
}
