#!/usr/bin/env bash

sudo -i

apt-get update
apt-get -y upgrade

apt-get update

apt-get -y --force-yes install build-essential python-software-properties curl

# Setup X11
apt-get -y --force-yes install xfce4

echo "allowed_users=anybody" > /etc/X11/Xwrapper.config
echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config
echo "X11UseLocalhost yes" >> /etc/ssh/sshd_config
echo "   ForwardX11 yes" >> /etc/ssh/ssh_config

service ssh restart


# Setup TOR
apt-get -y --force-yes install tor-geoipdb torsocks tor

echo "ControlPort 9051" > /etc/tor/torrc
echo "CookieAuthentication 0" >> /etc/tor/torrc
echo "VirtualAddrNetwork 10.192.0.0/10" >> /etc/tor/torrc
echo "AutomapHostsOnResolve 1" >> /etc/tor/torrc
echo "TransPort 9040" >> /etc/tor/torrc
echo "DNSPort 53" >> /etc/tor/torrc


# destinations you don't want routed through Tor
NON_TOR="10.4.6.0/24 192.168.0.0/16 10.0.0.1/32"

# the UID Tor runs as
TOR_UID=`cat /etc/passwd | grep "debian-tor" | awk -F":" '{print $3}'`

# Tor's TransPort
TRANS_PORT="9040"

iptables -F
iptables -t nat -F

iptables -t nat -A OUTPUT -m owner --uid-owner $TOR_UID -j RETURN
iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 53
for NET in $NON_TOR 127.0.0.0/8 127.128.0.0/10; do
 iptables -t nat -A OUTPUT -d $NET -j RETURN
done
iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports $TRANS_PORT

iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
for NET in $NON_TOR 127.0.0.0/8; do
 iptables -A OUTPUT -d $NET -j ACCEPT
done
iptables -A OUTPUT -m owner --uid-owner $TOR_UID -j ACCEPT
iptables -A OUTPUT -j REJECT

sudo apt-get --force-yes -y install iptables-persistent

/etc/init.d/tor restart

# Setup Chrome
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list

sudo apt-get update
sudo apt-get --force-yes -y install google-chrome-stable
