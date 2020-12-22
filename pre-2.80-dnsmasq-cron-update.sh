#!/bin/bash
#
# Modified from the notracking hosts-blocking update script 
# https://github.com/notracking/hosts-blocklists/wiki/Install-dnsmasq-(old:-pre-v2.80)
#
# ABOUT
# This is a simple autoupdate and whitelist script for the notracking blocklists.
# notracking lists: https://github.com/notracking/hosts-blocklists
# script source: https://github.com/notracking/hosts-blocklists-scripts
#
# HOWTO
# For Debian based systems
#  - Install curl: sudo apt install curl
#  - Download this file to: /etc/cron.daily/adblocking_update
#  - Mark it as executable: sudo chmod +x /etc/cron.daily/adblocking_update
#  - Update the CONFIG section in this script: sudo nano /etc/cron.daily/adblocking_update
#  - Do a test run: sudo /etc/cron.daily/adblocking_update
#
# WHITELISTING
# Any line in the blocklist that contains one of the lines in the whitelist will be automatically removed.
# Only rules that include a dot '.' will be used to avoid simple mistakes.
#
######## CONFIG ########
listdir=/etc
########################

echo -n "[+] Downloading notracking updates: "
curl --silent -o $listdir/dnsmasq.hostnames.txt https://raw.githubusercontent.com/notracking/hosts-blocklists/master/hostnames.txt
curl --silent -o $listdir/dnsmasq.domains.txt https://raw.githubusercontent.com/notracking/hosts-blocklists/master/domains.txt
echo "OK!"

echo -n "[+] Applying whitelist: "
touch $listdir/whitelist.txt # create empty whitelist in case it does not exist
while IFS= read -r line; do # IFS= to prevent read from remove leading or tailing spaces
  if [[ $line == *"."* ]] # line must at least contain a '.' to avoid simple mistakes
  then
    line="${line%%[[:cntrl:]]}" # removes tailing newline

    grep -v "${line}" $listdir/dnsmasq.hostnames.txt > $listdir/dnsmasq.hostnames.tmp.txt
    grep -v "${line}" $listdir/dnsmasq.domains.txt > $listdir/dnsmasq.domains.tmp.txt

    mv $listdir/dnsmasq.hostnames.tmp.txt $listdir/dnsmasq.hostnames.txt
    mv $listdir/dnsmasq.domains.tmp.txt $listdir/dnsmasq.domains.txt
  fi
done < $listdir/dnsmasq.whitelist.txt
echo "OK!"

echo -n "[+] Restarting Dnsmasq: "
service dnsmasq restart
echo "OK!"