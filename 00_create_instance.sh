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
    sudo echo "###### DEPLOY INSTANCE #######"
    rsync -r ./ $WORKDIR
    sleep 5
    cd $WORKDIR
    sudo bash 01_deploy.sh
    cd ..
else
    echo "directory/instance name found, deployment stopped"
fi



