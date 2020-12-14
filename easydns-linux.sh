#!/bin/sh
# Turns a standard Ubuntu Server installation into a DNS server for your home with no effort

# Configuration
SERVER_IP_ADDR="192.168.0.4"    # The IP address to use for your server. Typically 192.168.0.x or 192.168.1.x
USERNAME="root" 
DOMAIN=""                       # If your home network has a domain name, like home.example.com, enter it here
DNS_SERVER_1="9.9.9.9"
DNS_SERVER_2="149.112.112.112"

# Download our new dnsmasq config file from our repository before we lose Internet connection
sudo curl https://raw.githubusercontent.com/ssnseawolf/easydns-linux/master/dnsmasq.conf > ~/dnsmasq.conf

# Replace variables in our newly downloaded config file
sed -i "s/SERVER_IP_ADDR/$SERVER_IP_ADDR" ~/dnsmasq.conf
sed -i "s/DOMAIN/$DOMAIN" ~/dnsmasq.conf
sed -i "s/DNS_SERVER_1/$DNS_SERVER_1" ~/dnsmasq.conf
sed -i "s/DNS_SERVER_2/$DNS_SERVER_2" ~/dnsmasq.conf

# Install dnsmasq
sudo apt install -y dnsmasq

# systemd-resolved has a stub listener on port 53 by default. It must go
echo "DNSStubListener=no" | sudo tee -a /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

# Copy our new dnsmasq config file over
sudo rsync ~/dnsmasq.conf /etc/dnsmasq.conf --remove-source-files 

# Restart dnsmasq after updating the blacklist
systemctl reload dnsmasq


# Download blocklist
sudo curl https://raw.githubusercontent.com/notracking/hosts-blocklists/master/dnsmasq/dnsmasq.blacklist.txt > /home/dnsmasq.blacklist.txt

# Run this file as a cron job
# Every other day cron: 0 0 2-30/2 * * /home/update-blacklist.sh

# Create a cron job to update adlist every two days
# Formatted to look pretty in the cron list
#CRONJOB=" 0 0 2-30/2 * * root    /home/update-blacklist.sh"