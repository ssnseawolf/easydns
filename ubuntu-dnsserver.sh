#!/bin/sh
# Turns a standard Ubuntu Server installation into a DNS server for your home with no effort

# Configuration
SERVER_IP_ADDR="192.168.0.3"    # The IP address to use for your server. Typically 192.168.0.x or 192.168.1.x
USERNAME="root" 
DOMAIN=""                       # If your home network has a domain name, like home.example.com, enter it here
DNS_SERVER_1="9.9.9.9"
DNS_SERVER_2="149.112.112.112"

# Run this file as a cron job
# Every other day cron: 0 0 2-30/2 * * /home/update-blacklist.sh
curl -SLso /home/dnsmasq.blacklist.txt https://raw.githubusercontent.com/notracking/hosts-blocklists/master/dnsmasq/dnsmasq.blacklist.txt


# Create a cron job to update adlist every two days
# Formatted to look pretty in the cron list
CRONJOB=" 0 0 2-30/2 * * root    /home/update-blacklist.sh"

# Restart dnsmasq after updating the blacklist
systemctl reload dnsmasq

# dnsmasq configuration
sudo rm /etc/dnsmasq.conf                   # Delete the old dnsmasq configuration file and make a new one with only the values we need.
listen-address=127.0.0.1,SERVER_IP_ADDR     # Ignore domains in the blocklist (127.0.0.1, essentially) and listen for DNS requests on our IP address (SERVER_IP_ADDR)
port=53                                     # The standard port to listen on for DNS requests

domain-needed                               # Don't send unecessary requests and protect your privacy a bit
bogus-priv                                  # Still don't send unecessary requests and protect your privacy a bit more

strict-order                                # Don't randomly select DNS servers. Always use the first server (127.0.0.1, this computer's adblock list) first
expand-hosts
domain=DOMAIN
dnssec                                      # DNSSec helps us stay secure by making it difficult for the forces of evil to serve you bad domain records
cache-size=10000

no-resolv                                   # Ignore the /etc/resolv.conf file to list our nameservers. We'll do it on the next three lines
server=127.0.0.1                            # This "server" is this computer, and will cache requests as well as block ads
server=DNS_SERVER_1                         # First outside DNS server we check when a request comes in
server=DNS_SERVER_2                         # Second outside DNS server we check when a request comes in

conf-file=/etc/dnsmasq.conf

