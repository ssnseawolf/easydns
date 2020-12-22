# easydns-linux

A simple script to get a full-blown adblocking DNS server up and running with as few clicks and little knowledge as possible.

This script is designed to be simple, basic and straightforward. It is not designed to be used in a variety of environments, only a fresh Ubuntu Server install or very similar.


1. Download and install a fresh copy of Ubuntu Server, preferably on a virtual machine as root.
2. ```bash <(curl -s https://raw.githubusercontent.com/ssnseawolf/easydns/master/easydns.sh)```

Machine will reboot with an adblocking DNS server for your network. If you need to use a different static IP or configure other options, change it at the top of the script beforehand.

## Credit ##
This software uses the exellent [notracking](https://github.com/notracking/hosts-blocklists) blocklist.
