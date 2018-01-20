#! /bin/bash
#
# Start docker through docker-compose and also launch script that fix Kaporal hostnames
#
# Author: nkandel@altima-agency.com

# First ask for sudo password to avoid user missed it when prompt later
if (sudo true)
then
  # Remove all containers as we don't know if they previously hanged
  docker-compose down > /dev/null 2>&1
  # Launch containers and fix IP in parallel
  ./script/docker/fix-magento2-ip.sh & docker-compose up
  # Be sur to stop, kill and finally remove containers so they won't mix with others
  docker-compose down > /dev/null 2>&1
else
 echo "Please give your right sudo password" && exit 2
fi

