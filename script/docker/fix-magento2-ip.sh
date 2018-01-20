#! /bin/bash
#
# Fix hostnames for project, not in a very clean way but it works
#
# Author: nkandel@altima-agency.com

HOST_FILE=/etc/hosts

sleep 7

echo 
echo
echo == Fixing IPs for magento2.loc ==

./script/docker/docker-fix-ip.sh

CURRENT_FOLDER=${PWD##*/}
# Manage lower case
CURRENT_FOLDER="${CURRENT_FOLDER,,}"

WEB=$CURRENT_FOLDER"_web_1"
WEB_FULL=$WEB" magento2.loc"
echo "   $WEB > $WEB_FULL"
$(sudo sed -i "s/$WEB/$WEB_FULL/g" $HOST_FILE)
echo == IPs fixed... done ==
