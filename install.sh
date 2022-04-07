#!/bin/bash
# Created by Nova
# Tested on PI 3 & Debian Stretch
# https://nova.ws/pi-tor-socks/

apt-get update
apt-get upgrade -y
apt-get install -y mc htop psmisc git make gcc python3-pip hostapd iptables-persistent wvdial tor tor-arm dnsmasq netdiag tcpdump

#Disable some garbage
systemctl disable avahi-daemon
systemctl stop avahi-daemon

#Stop curent service | we will start it later
systemctl stop tor
systemctl stop dnsmasq

# Install 3proxy
cd ~
git clone https://github.com/z3APA3A/3proxy
cd 3proxy/ && make -f Makefile.Linux
mkdir -p /lib/3proxy/
mv bin/TransparentPlugin.ld.so /lib/3proxy/
mv bin/PCREPlugin.ld.so /lib/3proxy/
mv bin/TrafficPlugin.ld.so /lib/3proxy/
mv bin/StringsPlugin.ld.so /lib/3proxy/
mv bin/3proxy /usr/bin/
cd ~
rm -rf 3proxy

# Install dnsproxy
cd ~
git clone https://github.com/jtripper/dns-tcp-socks-proxy
cd dns-tcp-socks-proxy && make
mkdir -p /etc/dnsproxy
mv dns_proxy.conf /etc/dnsproxy/
mv dns_proxy /usr/bin/
cd ~
rm -rf dns-tcp-socks-proxy

#Download Def Conf & install it
cd ~
curl https://nova.ws/dl/release/pi_tor_socks/pi_tor_socks_conf.tar.gz | tar xz
mv conf/dnsmasq.conf /etc/dnsmasq.conf
mv conf/dns_proxy.conf /etc/dnsproxy/dns_proxy.conf
mv conf/resolv.conf /etc/dnsproxy/resolv.conf
mv conf/hostapd.conf /etc/hostapd/hostapd.conf
mv conf/interfaces /etc/network/interfaces
mv conf/sysctl.conf /etc/sysctl.conf
mv conf/wvdial.conf /etc/wvdial.conf
mv conf/3proxy.cfg /etc/3proxy.cfg
mv conf/service/3proxy.service /lib/systemd/system/
mv conf/service/dnsproxy.service /lib/systemd/system/
mv conf/service/webmanager.service /lib/systemd/system/
cd ~
rm -rf conf

#Some change hostapd
sed -i /etc/default/hostapd -e '/DAEMON_CONF=/c DAEMON_CONF="/etc/hostapd/hostapd.conf"'

#Download web-manager interface & install it
git clone https://github.com/novaws/pi_tor_socks.git
mv app /opt/

## Install couple python libary
pip3 install flask
pip3 install requests
pip3 install pysocks

## Install & run our & other service
systemctl enable 3proxy
systemctl enable dnsproxy
systemctl enable webmanager
systemctl enable dnsmasq
systemctl enable tor
systemctl enable hostapd

#Install & save iptables rules
iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 22 -j REDIRECT --to-ports 22
iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 5000 -j REDIRECT --to-ports 5000
iptables -t nat -A PREROUTING -i wlan0 -p tcp --syn -j REDIRECT --to-ports 6666
iptables-save > /etc/iptables/rules.v4

## Seems all done but need reboot
echo "All done, need reboot"
reboot
