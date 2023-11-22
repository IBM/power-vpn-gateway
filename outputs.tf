##############################################################################
# Terraform Outputs
##############################################################################

output "vpn_endpoint" {
  description = "The internet accessible endpoint for the VPN"
  value       = module.vpn.endpoint
}
