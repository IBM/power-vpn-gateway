resource "ibm_pi_cloud_connection" "cloud_connection" {
  pi_cloud_instance_id                = var.power_workspace_id # GUID
  pi_cloud_connection_name            = var.name
  pi_cloud_connection_speed           = tostring(var.cloud_connection_speed)
  pi_cloud_connection_transit_enabled = true
}

# The Cloud Connection creates a Direct Link as part of the create.
# However, it does not wait for the DL to become ready
# TODO: Investigate if there is a way to test DL state
resource "time_sleep" "wait_for_dl" {
  depends_on      = [ibm_pi_cloud_connection.cloud_connection]
  create_duration = "60s"
}

data "ibm_dl_gateway" "powervs_dl_gateway" {
  depends_on = [time_sleep.wait_for_dl]
  name       = ibm_pi_cloud_connection.cloud_connection.pi_cloud_connection_name
}
