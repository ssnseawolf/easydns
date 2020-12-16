#!/bin/sh

# User configuration
SERVER_IP_ADDR="192.168.0.4"        # IP address to use for your server. Typically 192.168.0.x or 192.168.1.x
SERVER_IP_NETMASK_CIDR="16"
GATEWAY_IP_ADDR="192.168.0.1"
DOMAIN="None"                       # If your home network has a domain name, like home.example.com, enter it here
DNS_SERVER_1="9.9.9.9"
DNS_SERVER_2="149.112.112.112"

# Download our new dnsmasq config file from our repository before we lose Internet connection
curl https://raw.githubusercontent.com/ssnseawolf/easydns-linux/master/dnsmasq.conf > ~/dnsmasq.conf
curl https://raw.githubusercontent.com/ssnseawolf/easydns-linux/master/netplan.yaml > ~/netplan.yaml

# Replace variables in our newly downloaded config file
sed -i "s/SERVER_IP_ADDR/$SERVER_IP_ADDR/" ~/dnsmasq.conf
sed -i "s/DOMAIN/$DOMAIN/" ~/dnsmasq.conf
sed -i "s/DOMAIN=None/ /" ~/dnsmasq.conf
sed -i "s/DNS_SERVER_1/$DNS_SERVER_1/" ~/dnsmasq.conf
sed -i "s/DNS_SERVER_2/$DNS_SERVER_2/" ~/dnsmasq.conf

# Replace variables in our newly downloaded netplan file
sed -i "s/SERVER_IP_ADDR/$SERVER_IP_ADDR/" ~/netplan.yaml
sed -i "s/SERVER_IP_NETMASK_CIDR/$SERVER_IP_NETMASK_CIDR/" ~/netplan.yaml
sed -i "s/GATEWAY_IP_ADDR/$GATEWAY_IP_ADDR/" ~/netplan.yaml

# Download dnsmasq before we cut the network connection
sudo apt install -y dnsmasq --download-only

# systemd-resolved has a stub listener on port 53 by default. It must go
echo "DNSStubListener=no" | sudo tee -a /etc/systemd/resolved.conf

sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved
sudo apt install -y dnsmasq

# Apply our config and netplan files
sudo rsync ~/dnsmasq.conf /etc/dnsmasq.conf --remove-source-files
sudo rm /etc/netplan/*.yaml
sudo rsync ~/netplan.yaml /etc/netplan/netplan.yaml
sudo netplan apply

# Restart dnsmasq now that our config file is in place
systemctl restart dnsmasq

# Create blacklist folder
mkdir -m 777 ~/home/

# Download blocklist
BLACKLIST_URL="https://raw.githubusercontent.com/notracking/hosts-blocklists/master/dnsmasq/dnsmasq.blacklist.txt"
sudo curl $BLACKLIST_URL > /home/dnsmasq.blacklist.txt

# Update ablock list as a cronjob
# Create a cron job to update adlist every two days
USERNAME=$(id -u -n)
CRONJOB=" 0 0 2-30/2 * * $USERNAME    curl $BlACKLIST_URL > ~/dnsmasq.blacklist.txt"
sudo echo $CRONJOB > /etc/cron.d/adblock-update