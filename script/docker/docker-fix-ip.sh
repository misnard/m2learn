#!/bin/bash
#
# Update hosts file in order to access docker containers easily and by hostname
#
# Author: Nicolas Kandel <nkandel@altima-agency.com>
#


HOST_FILE=/etc/hosts
DOCKER_SUFIX=.loc

function getAllHosts() {
  hosts=$(docker ps | grep tcp | awk '{print $NF}')
}


function getHostIP() {
  docker inspect $1 | grep '"IPAddress"' | awk '{print $2}' | tr -d '",n'
}

function removeDockerEntries() {
  # Remove all entries that we know extension
  sudo sed -i "/$1/d" $HOST_FILE
  # Remove entries created by docker-compose, which are not very clean for now
  sudo sed -i "/web_1/d" $HOST_FILE
  sudo sed -i "/web_2/d" $HOST_FILE
  sudo sed -i "/db_1/d" $HOST_FILE
  sudo sed -i "/db_2/d" $HOST_FILE
  sudo sed -i "/cache_1/d" $HOST_FILE
  sudo sed -i "/cache_2/d" $HOST_FILE
}

removeDockerEntries $DOCKER_SUFIX
getAllHosts
for host in $hosts
do
  sudo sed -i "/$host/d" $HOST_FILE
  echo $(getHostIP $host)  $host | sudo tee -a $HOST_FILE
done




#return 0

