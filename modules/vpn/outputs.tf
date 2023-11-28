output "endpoint" {
  value       = local.use_vsi_vpn ? ibm_is_floating_ip.vpn[0].address : ibm_is_vpn_gateway.vpc[0].public_ip_address
  description = "The internet accessible endpoint for the VPN"
}
