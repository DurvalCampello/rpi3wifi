#!/bin/bash
# Based on Adafruit Learning Technologies Onion Pi project
# More info: http://learn.adafruit.com/onion-pi

if (( $EUID != 0 )); then 
   echo "This must be run as root. Try 'sudo bash $0'." 
   exit 1 
fi


echo "
$(tput setaf 2)              .~~.   .~~.
$(tput setaf 6)   /         $(tput setaf 2)'. \ ' ' / .'$(tput setaf 6)         \ 
$(tput setaf 6)  |   /       $(tput setaf 1).~ .~~~..~.$(tput setaf 6)       \   |
$(tput setaf 6) |   |   /  $(tput setaf 1) : .~.'~'.~. :$(tput setaf 6)   \   |   |
$(tput setaf 6)|   |   |   $(tput setaf 1)~ (   ) (   ) ~$(tput setaf 6)   |   |   |
$(tput setaf 6)|   |  |   $(tput setaf 1)( : '~'.~.'~' : )$(tput setaf 6)   |  |   |
$(tput setaf 6)|   |   |   $(tput setaf 1)~ .~ (   ) ~. ~ $(tput setaf 6)  |   |   |
$(tput setaf 6) |   |   \   $(tput setaf 1)(  : '~' :  )$(tput setaf 6)   /   |   |
$(tput setaf 6)  |   \       $(tput setaf 1)'~ .~~~. ~'$(tput setaf 6)       /   |
$(tput setaf 6)   \              $(tput setaf 1)'~'$(tput setaf 6)              / 
$(tput bold ; tput setaf 4)            Raspberry PiFi$(tput sgr0)

"

echo "$(tput setaf 6)This script will configure your Raspberry Pi as a wireless access point.$(tput sgr0)"
read -p "$(tput bold ; tput setaf 2)Press [Enter] to begin, [Ctrl-C] to abort...$(tput sgr0)"

echo "$(tput setaf 6)Configuring hostapd...$(tput sgr0)"
echo "$(tput bold ; tput setaf 2)Type a 1-32 character SSID (name) for your PiFi network, then press [ENTER]:$(tput sgr0)"
read ssid
echo "$(tput setaf 6)PiFi network SSID set to $(tput bold)$ssid$(tput sgr0 ; tput setaf 6). Edit /etc/hostapd/hostapd.conf to change.$(tput sgr0)"

pwd1="0"
pwd2="1"
until [ $pwd1 == $pwd2 ]; do
  echo "$(tput bold ; tput setaf 2)Type a password to access your PiFi network, then press [ENTER]:$(tput sgr0)"
  read -s pwd1
  echo "$(tput bold ; tput setaf 2)Verify password to access your PiFi network, then press [ENTER]:$(tput sgr0)"
  read -s pwd2
done

if [ $pwd1 == $pwd2 ]; then
  echo "$(tput setaf 6)Password set. Edit /etc/hostapd/hostapd.conf to change.$(tput sgr0)" 
fi

 APPASS=$pwd1
 APSSID=$ssid
 
 apt-get remove --purge hostapd -y
 apt-get install hostapd dnsmasq -y
 
 cat > /etc/systemd/system/hostapd.service <<EOF
 [Unit]
 Description=Hostapd IEEE 802.11 Access Point
 After=sys-subsystem-net-devices-wlan0.device
 BindsTo=sys-subsystem-net-devices-wlan0.device
 [Service]
 Type=forking
 PIDFile=/var/run/hostapd.pid
 ExecStart=/usr/sbin/hostapd -B /etc/hostapd/hostapd.conf -P /var/run/hostapd.pid
 [Install]
 WantedBy=multi-user.target
 EOF
 
 cat > /etc/dnsmasq.conf <<EOF
 interface=wlan0
 dhcp-range=10.0.0.2,10.0.0.5,255.255.255.0,12h
 EOF
 
 cat > /etc/hostapd/hostapd.conf <<EOF
 interface=wlan0
 hw_mode=g
 channel=10
 auth_algs=1
 wpa=2
 wpa_key_mgmt=WPA-PSK
 wpa_pairwise=CCMP
 rsn_pairwise=CCMP
 wpa_passphrase=$APPASS
 ssid=$APSSID
 EOF
 
 sed -i -- 's/allow-hotplug wlan0//g' /etc/network/interfaces
 sed -i -- 's/iface wlan0 inet manual//g' /etc/network/interfaces
 sed -i -- 's/    wpa-conf \/etc\/wpa_supplicant\/wpa_supplicant.conf//g' /etc/network/interfaces
 
 cat >> /etc/network/interfaces <<EOF
     wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
 # Added by rPi Access Point Setup
 allow-hotplug wlan0
 iface wlan0 inet static
     address 10.0.0.1
     netmask 255.255.255.0
     network 10.0.0.0
     broadcast 10.0.0.255
 EOF
 
 echo "denyinterfaces wlan0" >> /etc/dhcpcd.conf
 
 systemctl enable hostapd
 
 echo "All done! Please reboot"
 


echo "$(tput setaf 6)Checking hostapd status...$(tput sgr0)"
service hostapd status
hostapd_result=$?

#if [ $hostapd_result == 3 ]; then
#  echo "ERROR: hostapd start failed."
#  exit 1
#fi

echo "$(tput setaf 6)Checking ISC DHCP server status...$(tput sgr0)"
service isc-dhcp-server status
dhcp_result=$?
    
#if [ $dhcp_result == 3 ]; then
#  echo "ERROR: ISC DHCP server failed to start."
#  exit 1
#fi


echo "$(tput setaf 6)Rebooting...$(tput sgr0)"
reboot

exit 0
