#!/usr/bin/env bash

pass_ver () {
  while [ true ]; 
  do
    echo
    echo "enter new password for $1"
    echo
    passwd $1 
    if [ $? -eq 0 ]; then 	
      break	
    fi
  done
}

if [ "$(whoami)" != "root" ]; then
  echo "this script must be ran as root"
  echo
  exit 1
fi

pass_ver root

echo
read -p "enter a username for your user: " username 
useradd -m -G wheel -s /bin/bash $username

pass_ver $username		

while [ ! $connected_to_internet ];
do
  echo
  read -p "is your ssid hidden? [y/N]: " hidden_ssid
 
  if [ $hidden_ssid = "y" 2> /dev/null ]; then 
    echo
    read -p "enter hidden SSID: " a
    ssid=$a
    read -sp "enter password: " a
    echo
    passwd="$(wpa_passphrase $ssid $a | grep -e "[ ]*psk" | tail -n1 | sed "s/[^0-9]*//")"
    cat /etc/netctl/examples/wireless-wpa | sed "s/wlan/mlan/g" | sed "s/#P/P/" | sed "s/#H/H/" | sed "s/MyNetwork/$ssid/" | sed "s/WirelessKey/$passwd/" > /etc/netctl/network
    netctl enable network && netctl start network 
  else
    echo
    wifi-menu -o
  fi

  root_dev="$(lsblk 2> /dev/null | grep "[/]$" | sed "s/[0-9a-z]*//" | sed "s/[^0-9a-z]*[ ].*//" | sed "s/[^0-9a-z]*//g" | sed "s/[p].*//")"

  c="$(ping -c 1 google.com 2>/dev/null | head -1 | sed "s/[ ].*//")"
  if [ $c ]; then
    echo
    echo "you are now connected to the internet"
    pacman -S sudo --noconfirm
    echo
    sed -i "80i $username ALL=(ALL) ALL" /etc/sudoers
    echo "new user $username has been added to sudoers list"
    echo
    connected_to_internet=true
  else
    if [ $hidden_ssid = "y" 2> /dev/null ]; then 
      netctl disable network 
      rm /etc/netctl/network
    fi
    echo
    echo "ssid and / or passphrase are invalid."
  fi
done

read -p "the system will now reboot. login as your newly created user to continue" a
reboot 
