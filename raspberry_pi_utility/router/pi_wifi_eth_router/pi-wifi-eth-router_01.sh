#!/bin/bash

WIFI_SSID="Elbötos Hood"
WIFI_PASS="Albert18"

#koppla pi till wifi 
sudo tee /etc/netplan/01-wifi.yaml > /dev/null <<EOF
network:
  version: 2
  renderer: networkd
  wifis:
    wlan0:
      dhcp4: true
      access-points:
        "$WIFI_SSID":
          password: "$WIFI_PASS"
EOF

sudo netplan apply

# ge ethernet fixed address, enkelhetens skull
sudo tee /etc/netplan/02-eth.yaml > /dev/null <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses: [192.168.4.1/24]
EOF

sudo netplan apply
sudo ip link set eth0 up

# riktigt klurigt, ubuntu standar sw blockerar dns och dhcp hosting (so dnsmasq can use port 53) 
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo rm -f /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf

# gör iptables kända över omstarter
sudo apt update
sudo apt install -y dnsmasq iptables-persistent

# backa upp befintlig dnsmasq.conf
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
# ange vilken address som mottar data från klient, och vilka addresser klienter kan anta samt regler.
sudo tee /etc/dnsmasq.d/eth0.conf > /dev/null <<EOF
interface=eth0
bind-interfaces
listen-address=192.168.4.1
dhcp-range=192.168.4.50,192.168.4.150,12h
server=1.1.1.1
server=8.8.8.8
EOF

sudo systemctl restart dnsmasq
sudo systemctl enable dnsmasq

# ip-forwarding tillåter klienter kika på pi adressbord.
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-ipforward.conf
sudo sysctl --system

# lägg till postrouting på det som skickas via wifi till router, dvs maskera ursprungsaddr
sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
# # logik för hur data rör sig genom klienter till pidongle til router och tvärtom. 
sudo iptables -A FORWARD -i wlan0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o wlan0 -j ACCEPT

# Save iptables for reboot
sudo netfilter-persistent save
sudo systemctl enable netfilter-persistent
