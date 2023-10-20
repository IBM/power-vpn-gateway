output "public_ip" {
  value       = ibm_is_vpn_gateway.vpc.public_ip_address
  description = "Public IP of VPN Gateway"
}
