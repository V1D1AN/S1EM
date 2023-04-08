#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

read -p "Enter instance name (no subdirectory name) [ex: production]: " name
name=${name:-production}


SCRIPTDIR="$(pwd)"
# set WORKDIR
WORKDIR="${SCRIPTDIR}/$name"
if [[ ! -d $WORKDIR ]]
then
    echo "$WORKDIR not exists on your filesystem."
else
    cd $WORKDIR
    sudo echo "#### DELETE INSTANCE #### "
    docker compose kill 
    echo y | docker compose rm  
    echo y | docker network prune
    echo y | docker system prune
    echo y | docker volume rm $(docker volume ls -q --filter dangling=true)
    cd ..
    sudo rm -rf $WORKDIR
fi





