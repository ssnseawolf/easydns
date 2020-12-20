#!/bin/bash

# User configuration
SERVER_IP_ADDR=""        # IP address to use for your server. Typically 192.168.0.x or 192.168.1.x
SERVER_IP_NETMASK_CIDR=""
GATEWAY_IP_ADDR="1"
DNS_SERVER_1="9.9.9.9"
DNS_SERVER_2="149.112.112.112"

# Sudo
su -

# Request default IP
read -p "Static IP to set. Default is 192.168.1.10: " SERVER_IP_ADDR
read -p "CIDR subnet (no slash, i.e. 16 or 24). Default is 24: " SERVER_IP_NETMASK_CIDR
read -p "Gateway IP. Default is 192.168.1.1: " GATEWAY_IP_ADDR
SERVER_IP_ADDR=${SERVER_IP_ADDR:-192.168.1.10}
SERVER_IP_NETMASK_CIDR=${SERVER_IP_NETMASK_CIDR:-24}
GATEWAY_IP_ADDR=${GATEWAY_IP_ADDR:-192.168.1.1}

# Download our new dnsmasq config file from our repository before we lose Internet connection
curl https://raw.githubusercontent.com/ssnseawolf/easydns-linux/master/dnsmasq.conf > ~/dnsmasq.conf
curl https://raw.githubusercontent.com/ssnseawolf/easydns-linux/master/netplan.yaml > ~/netplan.yaml

# Replace variables in our newly downloaded config file
sed -i "s/SERVER_IP_ADDR/$SERVER_IP_ADDR/" ~/dnsmasq.conf
sed -i "s/DNS_SERVER_1/$DNS_SERVER_1/" ~/dnsmasq.conf
sed -i "s/DNS_SERVER_2/$DNS_SERVER_2/" ~/dnsmasq.conf

# Replace variables in our newly downloaded netplan file
sed -i "s/SERVER_IP_ADDR/$SERVER_IP_ADDR/" ~/netplan.yaml
sed -i "s/SERVER_IP_NETMASK_CIDR/$SERVER_IP_NETMASK_CIDR/" ~/netplan.yaml
sed -i "s/GATEWAY_IP_ADDR/$GATEWAY_IP_ADDR/" ~/netplan.yaml

# Download blocklist for first time
BLACKLIST_URL="https://raw.githubusercontent.com/notracking/hosts-blocklists/master/dnsmasq/dnsmasq.blacklist.txt"
curl $BLACKLIST_URL | tee /etc/dnsmasq.blacklist.txt > /dev/null

# Cut our Internet as we switch off systemd-resolved
#sudo systemctl disable systemd-resolved
dnf install -y dnsmasq

# Make sure server is updated and install bind-utils (optional, but nice for dig)
dnf -y upgrade
dnf install -y bind-utils

# Enable automatic updates with automatic reboot
dnf install -y dnf-automatic
AUTOMATIC_UPDATE_URL="https://raw.githubusercontent.com/ssnseawolf/easydns-linux/master/automatic.conf"
curl $AUTOMATIC_UPDATE_URL | tee /etc/dnf/automatic.conf

# Apply our config and netplan files
nmcli connection modify eth0 IPv4.address $SERVER_IP_ADDR/$SERVER_IP_NETMASK_CIDR
nmcli connection modify enp1s0 IPv4.gateway $GATEWAY_IP_ADDR
nmcli connection modify enp1s0 IPv4.method manual

# Update ablock list as a cronjob
# Create a cron job to update adlist every day at midnight with a 1 hour random offset
CRONJOB="0 1 * * * root    perl -le 'sleep rand 3600' && curl $BLACKLIST_URL | tee /etc/dnsmasq.blacklist.txt"
echo "$CRONJOB" | sudo tee -a /etc/crontab

# We lazy
reboot