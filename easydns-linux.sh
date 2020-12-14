#!/bin/sh

# User configuration
SERVER_IP_ADDR="192.168.0.4/16"        # IP address to use for your server. Typically 192.168.0.x or 192.168.1.x
GATEWAY_IP_ADDR="192.168.0.1"
DOMAIN="None"                       # If your home network has a domain name, like home.example.com, enter it here
DNS_SERVER_1="9.9.9.9"
DNS_SERVER_2="149.112.112.112"

# Download our new dnsmasq config file from our repository before we lose Internet connection
curl https://raw.githubusercontent.com/ssnseawolf/easydns-linux/master/dnsmasq.conf > ~/dnsmasq.conf
curl https://raw.githubusercontent.com/ssnseawolf/easydns-linux/master/dnsmasq.conf > ~/netplan.yaml

# Replace variables in our newly downloaded config file
sed -i "s/SERVER_IP_ADDR/$SERVER_IP_ADDR/" ~/dnsmasq.conf
sed -i "s/DOMAIN/$DOMAIN/" ~/dnsmasq.conf
sed -i "s/DOMAIN=None//" ~/dnsmasq.conf
sed -i "s/DNS_SERVER_1/$DNS_SERVER_1/" ~/dnsmasq.conf
sed -i "s/DNS_SERVER_2/$DNS_SERVER_2/" ~/dnsmasq.conf

# Replace variables in our newly downloaded netplan file
sed -i "s/SERVER_IP_ADDR/$SERVER_IP_ADDR/" ~/netplan.yaml
sed -i "s/GATEWAY_IP_ADDR/$GATEWAY_IP_ADDR/" ~/netplan.yaml

# Install dnsmasq
sudo apt install -y dnsmasq

# Apply our config and netplan files
sudo rsync ~/dnsmasq.conf /etc/dnsmasq.conf --remove-source-files
sudo rsync ~/netplan.conf /etc/netplan/*.yaml --remove-source-files 
sudo netplan apply

# systemd-resolved has a stub listener on port 53 by default. It must go
echo "DNSStubListener=no" | sudo tee -a /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

# Set IP address


# Restart dnsmasq after updating the blacklist
systemctl start dnsmasq


# Download blocklist
sudo curl https://raw.githubusercontent.com/notracking/hosts-blocklists/master/dnsmasq/dnsmasq.blacklist.txt > ~/dnsmasq.blacklist.txt

# Run this file as a cron job
# Every other day cron: 0 0 2-30/2 * * /home/update-blacklist.sh

# Create a cron job to update adlist every two days
# Formatted to look pretty in the cron list
#CRONJOB=" 0 0 2-30/2 * * root    /home/update-blacklist.sh"