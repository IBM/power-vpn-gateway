#!/bin/bash

# Write config files (done by cloud-init)
# * Create /etc/sysctl.d/95-ipsec.conf
# * Create /etc/sysconfig/iptables
# * Create /etc/ipsec.d/<connection>.conf
# * Create /etc/ipsec.d/<connection.secrets

# Install packages to enable VPN and manage iptables
dnf install -y libreswan iptables iptables-services

# Our sysctl config was written after sysctl ran at startup
# we need to load it manually and then reload our connections
sysctl -p /etc/sysctl.d/95-ipsec.conf
nmcli connection reload

# Start and enable the services we need
systemctl enable --now iptables
systemctl enable --now ipsec
