#!/bin/bash

# User configuration
SERVER_IP_ADDR=""        # IP address to use for your server. Typically 192.168.0.x or 192.168.1.x
SERVER_IP_NETMASK_CIDR=""
GATEWAY_IP_ADDR="1"
DNS_SERVER_1="1.1.1.1"
DNS_SERVER_2="1.0.0.1"
AD_DOMAIN_NAME=""
AD_DC_IP=""


# Request default IP
read -p "Static IP [192.168.1.10] " SERVER_IP_ADDR
read -p "CIDR subnet (no slash, i.e. '16' or '24') [24]: " SERVER_IP_NETMASK_CIDR
read -p "Gateway IP. [192.168.1.1] " GATEWAY_IP_ADDR
echo "Leave the next two prompts blank if you are not using Active Directory."
echo "If you're not sure, it's a good bet that you are not using Active Directory."
read -p "AD hostname [None]: " AD_DOMAIN_NAME
read -p "AD DC IP [None]:" AD_DC_IP
SERVER_IP_ADDR=${SERVER_IP_ADDR:-192.168.1.10}
SERVER_IP_NETMASK_CIDR=${SERVER_IP_NETMASK_CIDR:-24}
GATEWAY_IP_ADDR=${GATEWAY_IP_ADDR:-192.168.1.1}

# Download blocklist for first time
# Uncomment for dnsmasq >=2.80 (RHEL 9?)
#BLACKLIST_URLS="https://raw.githubusercontent.com/notracking/hosts-blocklists/master/dnsmasq/dnsmasq.blacklist.txt"
#curl $BLACKLIST_URLS | tee /etc/dnsmasq.blacklist.txt > /dev/null

# Only for dnsmasq <2.80 (Delete in RHEL 9?)
BLACKLIST_HOSTNAMES="https://raw.githubusercontent.com/notracking/hosts-blocklists/master/hostnames.txt"
BLACKLIST_DOMAINS="https://raw.githubusercontent.com/notracking/hosts-blocklists/master/domains.txt"
UPDATE_SCRIPT_URL="https://raw.githubusercontent.com/ssnseawolf/easydns/master/pre-2.80-dnsmasq-cron-update.sh"
curl $BLACKLIST_HOSTNAMES | tee /etc/dnsmasq.hostnames.txt > /dev/null
curl $BLACKLIST_DOMAINS | tee /etc/dnsmasq.domains.txt > /dev/null
curl $UPDATE_SCRIPT_URL | tee /etc/cron.daily/update_adblock > /dev/null # Use the wonderful notracking update script
chmod +x /etc/cron.daily/update_adblock

# Make sure server is updated
dnf -y upgrade
dnf install -y bind-utils   # For dig utility, not necessary

# Configure dnsmasq
dnf install -y dnsmasq      # DNS server
systemctl enable dnsmasq    # Enable dnsmasq on startup
DNSMASQ_CONF=https://raw.githubusercontent.com/ssnseawolf/easydns/master/dnsmasq.conf
curl $DNSMASQ_CONF | tee /etc/dnsmasq.conf > /dev/null
sed -i "s/SERVER_IP_ADDR/$SERVER_IP_ADDR/" /etc/dnsmasq.conf
sed -i "s/DNS_SERVER_1/$DNS_SERVER_1/" /etc/dnsmasq.conf
sed -i "s/DNS_SERVER_2/$DNS_SERVER_2/" /etc/dnsmasq.conf
sed -i "s/AD_DOMAIN_NAME/$AD_DOMAIN_NAME/" /etc/dnsmasq.conf
sed -i "s/AD_DC_IP/$AD_DC_IP/" /etc/dnsmasq.conf
sed -i "s/server=\/AD_DOMAIN_NAME\/AD_DC_IP\///" /etc/dnsmasq.conf

# Punch a hole through the firewall for DNS
firewall-cmd --add-service=dns --permanent

# Enable automatic system updates with automatic reboot
dnf install -y dnf-automatic

# Replace variables in our newly downloaded config file
AUTOMATIC_UPDATE_URL="https://raw.githubusercontent.com/ssnseawolf/easydns/master/automatic.conf"
curl $AUTOMATIC_UPDATE_URL | tee /etc/dnf/automatic.conf

# Finally, enable automatic updates
systemctl enable dnf-automatic-install.timer
systemctl start dnf-automatic-install.timer

# Configure our network settings
nmcli connection modify eth0 IPv4.address $SERVER_IP_ADDR/$SERVER_IP_NETMASK_CIDR
nmcli connection modify eth0 IPv4.gateway $GATEWAY_IP_ADDR
nmcli connection modify eth0 IPv4.method manual

# Set our nameserver in resolv.conf (no-resolv flag doesn't work in 2.79 - Try again in RHEL 9?)
echo "nameserver 127.0.0.1" | tee /etc/resolv.conf
echo "nameserver $DNS_SERVER_1" | tee -a /etc/resolv.conf
echo "nameserver $DNS_SERVER_2" | tee -a /etc/resolv.conf

# Update adblock list daily
# Uncomment for dnsmasq >=2.80 (RHEL 9?)
# CRONJOB="0 0 1 * * root    perl -le 'sleep rand 3600' && curl $BLACKLIST_URLS | tee /etc/dnsmasq.blacklist.txt"
# crontab -l > cronlist
# echo "$CRONJOB" >> cronlist
# crontab cronlist
# rm cronlist

# Log out after an hour
echo "TIMEOUT=3600" | tee ~/.bashrc

# Disable the built-in systemd-resolved DNS and remove ssh
systemctl disable systemd-resolved
systemctl disable sshd

# We lazy
reboot