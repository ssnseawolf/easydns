#!/bin/bash

# User configuration
SERVER_IP_ADDR=""        # IP address to use for your server. Typically 192.168.0.x or 192.168.1.x
SERVER_IP_NETMASK_CIDR=""
GATEWAY_IP_ADDR="1"
DNS_SERVER_1="9.9.9.9"
DNS_SERVER_2="149.112.112.112"
HOSTNAME=""


# Request default IP
read -p "Static IP [192.168.1.10] " SERVER_IP_ADDR
read -p "CIDR subnet (no slash, i.e. '16' or '24') [24]: " SERVER_IP_NETMASK_CIDR
read -p "Gateway IP. [192.168.1.1] " GATEWAY_IP_ADDR
read -p "Hostname [dns]: " HOSTNAME
SERVER_IP_ADDR=${SERVER_IP_ADDR:-192.168.1.10}
SERVER_IP_NETMASK_CIDR=${SERVER_IP_NETMASK_CIDR:-24}
GATEWAY_IP_ADDR=${GATEWAY_IP_ADDR:-192.168.1.1}
HOSTNAME=${HOSTNAME:-dns}

# Replace variables in our newly downloaded config file
sed -i "s/SERVER_IP_ADDR/$SERVER_IP_ADDR/" ~/dnsmasq.conf
sed -i "s/HOSTNAME/$HOSTNAME/" ~/dnsmasq.conf
sed -i "s/domain=DOMAIN//" ~/dnsmasq.conf
sed -i "s/DNS_SERVER_1/$DNS_SERVER_1/" ~/dnsmasq.conf
sed -i "s/DNS_SERVER_2/$DNS_SERVER_2/" ~/dnsmasq.conf

# Download blocklist for first time
# Uncomment for dnsmasq >=2.80 (RHEL 9?)
#BLACKLIST_URLS="https://raw.githubusercontent.com/notracking/hosts-blocklists/master/dnsmasq/dnsmasq.blacklist.txt"
#curl $BLACKLIST_URLS | tee /etc/dnsmasq.blacklist.txt > /dev/null

# Only for dnsmasq <2.80 (Delete in RHEL 9?)
BLACKLIST_HOSTNAMES="https://raw.githubusercontent.com/notracking/hosts-blocklists/master/hostnames.txt"
BLACKLIST_DOMAINS="https://raw.githubusercontent.com/notracking/hosts-blocklists/master/domains.txt"
UPDATE_SCRIPT_URL="https://raw.githubusercontent.com/ssnseawolf/easydns/master/pre-2.80-dnsmasq-cron-update.sh"
curl $BLACKLIST_URLS | tee /etc/dnsmasq.hostnames.txt > /dev/null
curl $BLACKLIST_IPS | tee /etc/dnsmasq.domains.txt > /dev/null
curl $UPDATE_SCRIPT_URL | tee /etc/cron.daily/adblocking_update > /dev/null # Use the wonderful notracking update script
chmod +x /etc/cron.daily/adblocking_update

# Make sure server is updated
dnf -y upgrade
dnf install -y bind-utils   # For dig utility, not necessary

# Configure dnsmasq
dnf install -y dnsmasq      # DNS server
systemctl enable dnsmasq    # Enable dnsmasq on startup
$DNSMASQ_CONF =https://raw.githubusercontent.com/ssnseawolf/easydns/master/dnsmasq.conf
curl $DNSMASQ_CONF | tee /etc/dnsmasq.conf > /dev/null

# Punch a hole through the firewall for DNS
firewall-cmd --add-service=dns --permanent

# Enable automatic system updates with automatic reboot
dnf install -y dnf-automatic
AUTOMATIC_UPDATE_URL="https://raw.githubusercontent.com/ssnseawolf/easydns/master/automatic.conf"
curl $AUTOMATIC_UPDATE_URL | tee /etc/dnf/automatic.conf

# Configure our network settings
nmcli connection modify eth0 IPv4.address $SERVER_IP_ADDR/$SERVER_IP_NETMASK_CIDR
nmcli connection modify eth0 IPv4.gateway $GATEWAY_IP_ADDR
nmcli connection modify eth0 IPv4.method manual

# Update adblock list daily
# Uncomment for dnsmasq >=2.80 (RHEL 9?)
# CRONJOB="0 0 1 * * root    perl -le 'sleep rand 3600' && curl $BLACKLIST_URLS | tee /etc/dnsmasq.blacklist.txt"
# crontab -l > cronlist
# echo "$CRONJOB" >> cronlist
# crontab cronlist
# rm cronlist


# Disable the built-in systemd-resolved DNS
systemctl disable systemd-resolved

# We lazy
reboot