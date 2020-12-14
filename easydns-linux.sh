#!/bin/sh
# Turns a standard Ubuntu Server installation into a DNS server for your home with no effort

# Configuration
SERVER_IP_ADDR="192.168.0.4"    # The IP address to use for your server. Typically 192.168.0.x or 192.168.1.x
USERNAME="root" 
DOMAIN=""                       # If your home network has a domain name, like home.example.com, enter it here
DNS_SERVER_1="9.9.9.9"
DNS_SERVER_2="149.112.112.112"
DNSMASQ_CONFIG_PATH="/home/ssnseawolf/update-blacklist"

# We're modifying spooky bits and must run as root
sudo -i

# Do downloading first
# Download our new dnsmasq config file from our repository
sudo curl https://raw.githubusercontent.com/ssnseawolf/easydns-linux/master/dnsmasq.conf > /etc/dnsmasq.conf

# Download blocklist
sudo curl https://raw.githubusercontent.com/notracking/hosts-blocklists/master/dnsmasq/dnsmasq.blacklist.txt > /home/dnsmasq.blacklist.txt


# systemd-resolved has a stub listener on port 53 by default. It must go
sudo echo "DNSStubListener=no" >> /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

# Install dnsmasq
sudo apt install -y dnsmasq



# Run this file as a cron job
# Every other day cron: 0 0 2-30/2 * * /home/update-blacklist.sh


# Create a cron job to update adlist every two days
# Formatted to look pretty in the cron list
#CRONJOB=" 0 0 2-30/2 * * root    /home/update-blacklist.sh"

# Restart dnsmasq after updating the blacklist
systemctl reload dnsmasq