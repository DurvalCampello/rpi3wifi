#!/bin/bash
# Based on Adafruit Learning Technologies Onion Pi project
# More info: http://learn.adafruit.com/onion-pi

if (( $EUID != 0 )); then 
   echo "This must be run as root. Try 'sudo bash $0'." 
   exit 1 
fi


echo "
$(tput setaf 2)              .~~.   .~~.
$(tput setaf 6)   /         $(tput setaf 2)'. \ ' ' / .'$(tput setaf 6)         \ 
$(tput setaf 6)  |   /       $(tput setaf 1).~ .~~~..~.$(tput setaf 6)       \   |
$(tput setaf 6) |   |   /  $(tput setaf 1) : .~.'~'.~. :$(tput setaf 6)   \   |   |
$(tput setaf 6)|   |   |   $(tput setaf 1)~ (   ) (   ) ~$(tput setaf 6)   |   |   |
$(tput setaf 6)|   |  |   $(tput setaf 1)( : '~'.~.'~' : )$(tput setaf 6)   |  |   |
$(tput setaf 6)|   |   |   $(tput setaf 1)~ .~ (   ) ~. ~ $(tput setaf 6)  |   |   |
$(tput setaf 6) |   |   \   $(tput setaf 1)(  : '~' :  )$(tput setaf 6)   /   |   |
$(tput setaf 6)  |   \       $(tput setaf 1)'~ .~~~. ~'$(tput setaf 6)       /   |
$(tput setaf 6)   \              $(tput setaf 1)'~'$(tput setaf 6)              / 
$(tput bold ; tput setaf 4)            Raspberry PiFi$(tput sgr0)
"

echo "$(tput setaf 6)This script will configure your Raspberry Pi 3 as a wireless access point.$(tput sgr0)"
read -p "$(tput bold ; tput setaf 2)Press [Enter] to begin, [Ctrl-C] to abort...$(tput sgr0)"

echo "$(tput setaf 6)Configuring hostapd...$(tput sgr0)"
echo "$(tput bold ; tput setaf 2)Type a 1-32 character SSID (name) for your PiFi network, then press [ENTER]:$(tput sgr0)"
read ssid
echo "$(tput setaf 6)PiFi network SSID set to $(tput bold)$ssid$(tput sgr0 ; tput setaf 6). Edit /etc/hostapd/hostapd.conf to change.$(tput sgr0)"

pwd1="0"
pwd2="1"
until [ $pwd1 == $pwd2 ]; do
  echo "$(tput bold ; tput setaf 2)Type a password(At least 8 characters) to access your PiFi network, then press [ENTER]:$(tput sgr0)"
  read -s pwd1
  echo "$(tput bold ; tput setaf 2)Verify password to access your PiFi network, then press [ENTER]:$(tput sgr0)"
  read -s pwd2
done

if [ $pwd1 == $pwd2 ]; then
  echo "$(tput setaf 6)Password set. Edit /etc/hostapd/hostapd.conf to change.$(tput sgr0)" 
fi

 APPASS=$pwd1
 APSSID=$ssid
if [[ $# -eq 2 ]]; then
        APSSID=$2
fi

echo "$(tput setaf 6)Installing Necessarys Packages.$(tput sgr0)" 
apt-get remove --purge hostapd -y
apt-get install aptitude libnl-route-3-* -y
aptitude install hostapd dnsmasq -y


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

cat > /etc/default/hostapd << EOF
# Defaults for hostapd initscript
#
# See /usr/share/doc/hostapd/README.Debian for information about alternative
# methods of managing hostapd.
#
# Uncomment and set DAEMON_CONF to the absolute path of a hostapd configuration
# file and hostapd will be started during system boot. An example configuration
# file can be found at /usr/share/doc/hostapd/examples/hostapd.conf.gz
#
DAEMON_CONF="/etc/hostapd/hostapd.conf"
# Additional daemon options to be appended to hostapd command:-
#       -d   show more debug messages (-dd for even more)
#       -K   include key data in debug messages
#       -t   include timestamps in some debug messages
#
# Note that -B (daemon mode) and -P (pidfile) options are automatically
# configured by the init.d script and must not be added to DAEMON_OPTS.
#
#DAEMON_OPTS=""
EOF

cat >/etc/sysctl.conf <<EOF
#
# /etc/sysctl.conf - Configuration file for setting system variables
# See /etc/sysctl.d/ for additional system variables.
# See sysctl.conf (5) for information.
#

#kernel.domainname = example.com

# Uncomment the following to stop low-level messages on console
#kernel.printk = 3 4 1 3

##############################################################3
# Functions previously found in netbase
#

# Uncomment the next two lines to enable Spoof protection (reverse-path filter)
# Turn on Source Address Verification in all interfaces to
# prevent some spoofing attacks
#net.ipv4.conf.default.rp_filter=1
#net.ipv4.conf.all.rp_filter=1

# Uncomment the next line to enable TCP/IP SYN cookies
# See http://lwn.net/Articles/277146/
# Note: This may impact IPv6 TCP sessions too
#net.ipv4.tcp_syncookies=1

# Uncomment the next line to enable packet forwarding for IPv4
net.ipv4.ip_forward=1

# Uncomment the next line to enable packet forwarding for IPv6
#  Enabling this option disables Stateless Address Autoconfiguration
#  based on Router Advertisements for this host
#net.ipv6.conf.all.forwarding=1


###################################################################
# Additional settings - these settings can improve the network
# security of the host and prevent against some network attacks
# including spoofing attacks and man in the middle attacks through
# redirection. Some network environments, however, require that these
# settings are disabled so review and enable them as needed.
#
# Do not accept ICMP redirects (prevent MITM attacks)
#net.ipv4.conf.all.accept_redirects = 0
#net.ipv6.conf.all.accept_redirects = 0
# _or_
# Accept ICMP redirects only for gateways listed in our default
# gateway list (enabled by default)
# net.ipv4.conf.all.secure_redirects = 1
#
# Do not send ICMP redirects (we are not a router)
#net.ipv4.conf.all.send_redirects = 0
#
# Do not accept IP source route packets (we are not a router)
#net.ipv4.conf.all.accept_source_route = 0
#net.ipv6.conf.all.accept_source_route = 0
#
# Log Martian Packets
#net.ipv4.conf.all.log_martians = 1
#

EOF

cat > /etc/rc.local <<EOF
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

# Print the IP address
_IP=$(hostname -I) || true
if [ "$_IP" ]; then
  printf "My IP address is %s\n" "$_IP"
fi
iptables-restore < /etc/iptables.ipv4.nat  
exit 0
EOF

echo "$(tput setaf 6)DNSAmasq configurated.$(tput sgr0)"
cat > /etc/dnsmasq.conf <<EOF
interface=wlan0      # Use interface wlan0  
listen-address=10.0.0.1 # Explicitly specify the address to listen on  
bind-interfaces      # Bind to the interface to make sure we aren't sending things elsewhere  
server=8.8.8.8       # Forward DNS requests to Google DNS  
domain-needed        # Don't forward short names  
bogus-priv           # Never forward addresses in the non-routed address spaces.  
dhcp-range=10.0.0.50,10.0.0.150,12h # Assign IP addresses between 172.24.1.50 and 172.24.1.150 with a 12 hour lease time  
EOF

cat > /lib/systemd/system/dnsmasq.service <<EOF
[Unit]
escription=dnsmasq - A lightweight DHCP and caching DNS server
After=network-online.target
wants=network-online.target

[Service]
Type=forking
PIDFile=/var/run/dnsmasq/dnsmasq.pid

# Test the config file and refuse starting if it is not valid.
ExecStartPre=/usr/sbin/dnsmasq --test

# We run dnsmasq via the /etc/init.d/dnsmasq script which acts as a
# wrapper picking up extra configuration files and then execs dnsmasq
# itself, when called with the "systemd-exec" function.
ExecStart=/etc/init.d/dnsmasq systemd-exec

# The systemd-*-resolvconf functions configure (and deconfigure)
# resolvconf to work with the dnsmasq DNS server. They're called liek
# this to get correct error handling (ie don't start-resolvconf if the
# dnsmasq daemon fails to start.
ExecStartPost=/etc/init.d/dnsmasq systemd-start-resolvconf
ExecStop=/etc/init.d/dnsmasq systemd-stop-resolvconf


ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF

echo "$(tput setaf 6)Hostapad Configurated.$(tput sgr0)"
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
        #wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
# Added by rPi Access Point Setup
allow-hotplug wlan0
iface wlan0 inet static
        address 10.0.0.1
        netmask 255.255.255.0
        network 10.0.0.0
        broadcast 10.0.0.255
        wireless-mode Master

EOF
echo "$(tput setaf 6)Configuring your wlan0 interface with a static IP.$(tput sgr0)"
echo "denyinterfaces wlan0" >> /etc/dhcpcd.conf

sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE  
sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT  
sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
  
echo "$(tput setaf 6)Saving IP tables...$(tput sgr0)"
sh -c "iptables-save > /etc/iptables.ipv4.nat"

systemctl enable hostapd

echo "All done! Rebooting now"
reboot
