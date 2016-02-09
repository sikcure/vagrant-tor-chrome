#!/usr/bin/env bash

sudo -i

timedatectl set-timezone UTC

apt-get -y --force-yes install build-essential python-software-properties ntp curl git nfs-common portmap openvpn

# Fixing HGFS issue on reboot
echo "answer AUTO_KMODS_ENABLED yes" | tee -a /etc/vmware-tools/locations

# Setup Chrome
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

# Get Chrome
echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list

apt-get update
apt-get -y upgrade

apt-get -y --force-yes install iptables-persistent xfce4 google-chrome-stable tor-geoipdb torsocks tor

# Setup X11
echo "allowed_users=anybody" > /etc/X11/Xwrapper.config
echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config
echo "X11UseLocalhost yes" >> /etc/ssh/sshd_config
echo "   ForwardX11 yes" >> /etc/ssh/ssh_config


# Setup openvpn

echo 'AUTOSTART="tor"'

# Setup tor
echo "ControlPort 9051" > /etc/tor/torrc
echo "CookieAuthentication 0" >> /etc/tor/torrc
echo "VirtualAddrNetwork 10.192.0.0/10" >> /etc/tor/torrc
echo "AutomapHostsOnResolve 1" >> /etc/tor/torrc
echo "TransPort 9040" >> /etc/tor/torrc
echo "DNSPort 53" >> /etc/tor/torrc

# destinations you don't want routed through Tor
NON_TOR=`ip route | sed -n "2,1000p" | awk -F" " '{print $1}'`

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

service iptables-persistent save
service tor restart

service ssh restart

# Sort out Dropbox
apt-get install python-cairo python-gobject-2 libxml2-dev libxslt1-dev python-dev python-gtk2
apt-get install -f
wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
./.dropbox-dist/dropboxd

# Install Keybase
curl -O https://dist.keybase.io/linux/deb/keybase-latest-amd64.deb \
&& dpkg -i keybase-latest-amd64.deb
