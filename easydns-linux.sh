#!/bin/sh
# Turns a standard Ubuntu Server installation into a DNS server for your home with no effort

# Configuration
SERVER_IP_ADDR="192.168.0.3"    # The IP address to use for your server. Typically 192.168.0.x or 192.168.1.x
USERNAME="root" 
DOMAIN=""                       # If your home network has a domain name, like home.example.com, enter it here
DNS_SERVER_1="9.9.9.9"
DNS_SERVER_2="149.112.112.112"
DNSMASQ_CONFIG_PATH="/home/ssnseawolf/update-blacklist"

# Download the dnsmasq config file from this repository
sudo curl -SLso /etc/dnsmasq.conf

# Run this file as a cron job
# Every other day cron: 0 0 2-30/2 * * /home/update-blacklist.sh
curl -SLso /home/dnsmasq.blacklist.txt https://raw.githubusercontent.com/notracking/hosts-blocklists/master/dnsmasq/dnsmasq.blacklist.txt


# Create a cron job to update adlist every two days
# Formatted to look pretty in the cron list
#CRONJOB=" 0 0 2-30/2 * * root    /home/update-blacklist.sh"

# Restart dnsmasq after updating the blacklist
systemctl reload dnsmasq

# Delete the old dnsmasq configuration file and make a new one with only the values we need.
rm /etc/dnsmasq.conf
curl -SLso /etc/dnsmasq.conf https://raw.githubusercontent.com/ssnseawolf/easydns-linux/master/dnsmasq.conf

