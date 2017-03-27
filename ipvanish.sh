# Version 1.0 03/27/2017
# Copyright (C) 2017 Steven Buehler
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU GPLv3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
#
# You must have an IPVanish account for this to work.
# You can get it at https://www.ipvanish.com/
#
# I have not tried other VPN services but reading reviews and recommendations,
# I found it to work perfectly for what I needed.  Not a bad price either.
# 
# I created this script for a Raspberry Pi LibreELEC/Kodi installation but it
# should work just fine for other Linux installations.  This script made it
# so much easier so that I don't have to do everything manually each new install
# that I do.  Plus, unless changed, it should always grab the latest .ovpn files
# from IPVanish. I have not tried it for other Linux versions though.
# For other than LibreELEC/Kodi installations, you might need or want to change
# the CONFIGDIR and CONFIGSZIP directory.
# 
# If you are running the Raspberry Pi LibreELEC/Kodi installation and already
# have your IPVanish username and password, just plug them into the script,
# upload the script to your /storage directory make the file executable
# (chmod +x ipvanish.sh) and run it.  As long as IPVanish doesn't change the URL
# of their configs.zip file, it will download it and run everything for you.
# For LibreELEC/Kodi users, to have it automatically connect when you boot up
# just add the following lines to your /storage/.config/autostart.sh script.
# If that file doesn't exist, just create it and run
# "chmod +x /storage/.config/autostart.sh" to make it executable.
# Without making it executable, it will not run automatically.
# 
# The following 3 lines to go into your /storage/.config/autostart.sh file.
# Use either "nano", "vi" or your favorite text editor.  If your script is in
# another directory, you will of course need to change that line here.
# (
#   /storage/ipvanish.sh
# ) &
# 
# You should ssh in and run this script manually at least the first time to make
# sure everything is working properly.  Before and after running it run the
# following command to see if your external IP has changed.
# curl ipinfo.io
# 
# The script default as I put it up is set to randomly pick a VPN server in the USA.
# You can narrow it down to one city or one server if you would like by changing
# the "CC=" variable.  I am not sure why, but it doesn't always choose the
# city/server that the randomness picks.  I think that might be on IPVanishes end.
# "Maybe" if the server it tries to connect to has too many connections already
# then IPVanish will assign it to a different server.  Not sure about that though.
# 
# There are a few variables that need to be checked/set in the script.
# The only required changes are for the IPVANISHUNAME and IPVANISHPASSWORD.
# 
#
# IPVANISHUNAME= your ipvanish username
# IPVANISHPASSWORD= your ipvanish password
# CONFIGDIR= Location of the .config directory, usually "/storage/.config"
# VPNDIR= Full path to .crt,.ovpn, and password file, usually $CONFIGDIR/vpn-config
# UNZIPCONFIGSZIP= if "1" it will unzip the ipvanish configs.zip file
#   Empty or anything but "1", it will not unzip a fresh copy.
#   If the there is not configs.zip file and the VPNDIR has no
#   .ovpn files in it, the script will stop.
# CONFIGSZIP= location of your ipvanish configs.zip file
# URLOFCONFIGSZIP="https://www.ipvanish.com/software/configs/configs.zip"
#	  if you leave this var blank, it will not ask you if you want to download it.
#	  configs.zip can be downloaded with
#	  "wget https://www.ipvanish.com/software/configs/configs.zip"
# CURPORT= is the Port # that is in the .ovpn files by default that needs changed.
#	  The script will change this to the "NEWPORT" port in all of the .ovpn files.
#	  As of this release, the port in all of the .ovpn files is a default "443"
#	  but IPVanish requires this to be changed to "1194".
# NEWPORT= is the Port # that you are changing the CURPORT too.
#	  Unless IPVanish changes something leave this as the default "1194"
# PASSFILE= the name of the password file that is needed to connect to the
#	  IPVanish VPN servers. This script creates it each time it is run.
# CERT= is the name of the certificate file and is in the downloaded configs.zip file.
#	  You shouldn't need to change this.
# CC= can be one of the following:                              
#	  CC="" Empty will randomly pick one from somewhere in the world
#	  CC="US" Country Code for random pick in a specific country
#	  CC="US-Atlanta" Country-City code for random pick of individual city                            
#	  CC="US-Atlanta-atl-a02" Full code to a Country/City/Server, will only use
#	  that particular server
# CCPRE="" is what the ovpn files start with BEFORE the Country Code.
#	  Normally you can just leave this alone.
#	  In the downloaded configs.zip file they all start with "ipvanish-" at the
#	  time of this release.
#
# If you run this file manually and see the error "sed: -i requires an argument"
#	that just means that it didn't find anything to change in one of the
#	egrep/sed commands

IPVANISHUNAME="ipvanishuname@yourdomain.com"
IPVANISHPASSWORD="ipvanishpassword"
CONFIGDIR="/storage/.config"
VPNDIR="$CONFIGDIR/vpn-config"
UNZIPCONFIGSZIP="1"
CONFIGSZIP="/storage/configs.zip"
#URLOFCONFIGSZIP=""
URLOFCONFIGSZIP="https://www.ipvanish.com/software/configs/configs.zip"
CURPORT="443"
NEWPORT="1194"
PASSFILE="pass.txt"
CERT="ca.ipvanish.com.crt"
CC="US"
CCPRE="ipvanish-"

if [ ! -z $URLOFCONFIGSZIP ]; then
  echo -n "Should I download a fresh ipvanish configs.zip file? (Y/N)"
  read YN
  case "$YN" in
    Y|y|YES|yes|Yes)
    wget -O $CONFIGSZIP $URLOFCONFIGSZIP 
    ;;
  *)
    if [ ! -e $CONFIGSZIP ] && [ ! -e $VPNDIR/*.ovpn ]; then                                                                                    
      printf "you must have either the ipvanish configs.zip file or the .ovpn files in $VPNDIR\n"                                         
      wget -O $CONFIGSZIP $URLOFCONFIGSZIP
    fi                                                                                                                                          
    ;;
  esac
fi


if [ ! -d "$VPNDIR" ]; then
  printf "$VPNDIR does not exist, creating it\n"
  mkdir $VPNDIR
  unzip -o $CONFIGSZIP -d $VPNDIR
else
  printf "$VPNDIR exists\n"
  if [ -e $CONFIGSZIP ] && [ "$UNZIPCONFIGSZIP" == "1" ]; then
    unzip -o $CONFIGSZIP -d $VPNDIR
  fi
fi

FILE=`ls -1 $VPNDIR/$CCPRE$CC*.ovpn | sed $((RANDOM%$(ls -1 $VPNDIR/$CCPRE$CC*.ovpn |wc -w)+1))!d\;q`          
printf "\n\n\nopenvpn $FILE\n\n\n"                                                                             
printf "$IPVANISHUNAME\n$IPVANISHPASSWORD\n" > $VPNDIR/$PASSFILE
egrep -l "^remote.*$CURPORT$" $VPNDIR/*.ovpn | xargs sed -i "s|$CURPORT|$NEWPORT|g"
egrep -l "^auth-user-pass$" $VPNDIR/*.ovpn | xargs sed -i "s|auth-user-pass|auth-user-pass $VPNDIR/$PASSFILE|g"
egrep -l "^ca $CERT$" $VPNDIR/*.ovpn | xargs sed -i "s|ca.*|ca $VPNDIR/$CERT|g"
(
openvpn $FILE
sleep 10s
printf "\n\n"
curl ipinfo.io
printf "\n\n"
)& 

sleep 10s
printf "\n\nWe used $FILE\n\n"
curl ipinfo.io

