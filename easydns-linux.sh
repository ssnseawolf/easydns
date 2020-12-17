#!/bin/sh

# User configuration
SERVER_IP_ADDR=""        # IP address to use for your server. Typically 192.168.0.x or 192.168.1.x
SERVER_IP_NETMASK_CIDR=""
GATEWAY_IP_ADDR="1"
DOMAIN=""                       # If your home network has a domain name, like home.example.com, enter it here
DNS_SERVER_1="9.9.9.9"
DNS_SERVER_2="149.112.112.112"

# Request default IP
read -p "Static IP to set. Default is 192.168.1.10: " SERVER_IP_ADDR
read -p "CIDR subnet (no slash, i.e. 16 or 24). Default is 24: " SERVER_IP_NETMASK_CIDR
read -p "Gateway IP. Default is 192.168.1.1: " GATEWAY_IP_ADDR
read -p "Domain (e.x. example.com). Default is no domain: " DOMAIN
SERVER_IP_ADDR=${SERVER_IP_ADDR:-192.168.1.10}
SERVER_IP_NETMASK_CIDR=${SERVER_IP_NETMASK_CIDR:-24}
GATEWAY_IP_ADDR=${GATEWAY_IP_ADDR:-192.168.1.1}

# Download our new dnsmasq config file from our repository before we lose Internet connection
curl https://raw.githubusercontent.com/ssnseawolf/easydns-linux/master/dnsmasq.conf > ~/dnsmasq.conf
curl https://raw.githubusercontent.com/ssnseawolf/easydns-linux/master/netplan.yaml > ~/netplan.yaml

# Replace variables in our newly downloaded config file
sed -i "s/SERVER_IP_ADDR/$SERVER_IP_ADDR/" ~/dnsmasq.conf
sed -i "s/DOMAIN/$DOMAIN/" ~/dnsmasq.conf
sed -i "s/domain=None/#domain=None/" ~/dnsmasq.conf
sed -i "s/DNS_SERVER_1/$DNS_SERVER_1/" ~/dnsmasq.conf
sed -i "s/DNS_SERVER_2/$DNS_SERVER_2/" ~/dnsmasq.conf

# Replace variables in our newly downloaded netplan file
sed -i "s/SERVER_IP_ADDR/$SERVER_IP_ADDR/" ~/netplan.yaml
sed -i "s/SERVER_IP_NETMASK_CIDR/$SERVER_IP_NETMASK_CIDR/" ~/netplan.yaml
sed -i "s/GATEWAY_IP_ADDR/$GATEWAY_IP_ADDR/" ~/netplan.yaml

# Download blocklist for first time
BLACKLIST_URL="https://raw.githubusercontent.com/notracking/hosts-blocklists/master/dnsmasq/dnsmasq.blacklist.txt"
curl $BLACKLIST_URL | sudo tee /etc/dnsmasq.blacklist.txt > /dev/null

# Make sure server is updated
sudo apt update
sudo apt upgrade -y

# Enable automatic updates with automatic reboot
export DEBIAN_FRONTEND=noninteractive # Turn off interactive mode first
sudo dpkg-reconfigure --frontend noninteractive --priority=low unattended-upgrades
echo 'Unattended-Upgrade::Automatic-Reboot "true";' | sudo tee -a /etc/apt/apt.conf.d/*auto-upgrades
sudo apt install -y update-notifier-common # Must be installed for automatic reboot

# Download dnsmasq before we cut the network connection
sudo apt install -y dnsmasq --download-only

# Cut our Internet as we switch off systemd-resolved
#sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo apt install -y dnsmasq

# Apply our config and netplan files
sudo rsync ~/dnsmasq.conf /etc/dnsmasq.conf --remove-source-files
sudo rm /etc/netplan/*.yaml
sudo rsync ~/netplan.yaml /etc/netplan/netplan.yaml

# Update ablock list as a cronjob
# Create a cron job to update adlist every day at midnight with a 1 hour random offset
CRONJOB="0 1 * * * root    perl -le 'sleep rand 3600' && curl $BLACKLIST_URL | tee /etc/dnsmasq.blacklist.txt"
echo "$CRONJOB" | sudo tee -a /etc/crontab

# Lazy machine restart
reboot