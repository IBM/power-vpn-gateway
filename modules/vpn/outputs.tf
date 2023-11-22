output "endpoint" {
  value       = ibm_is_vpn_gateway.vpc.public_ip_address
  description = "The internet accessible endpoint for the VPN"
}
