#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
echo "##########################################"
echo "########## CHECK PREREQUISITE ############"
echo "##########################################"
echo
echo
command_exists () {
    command -v $1 >/dev/null 2>&1;
}
if ! command_exists docker;
  then
        echo "Please install docker"
        exit
  else
        echo "docker installed"
fi
if ! command_exists docker-compose
  then
        echo "Please install docker-compose"
        exit
  else
        echo "docker-compose installed"
fi
if ! command_exists jq
  then
        echo "Please install jq"
        exit
  else
        echo "jq installed"
fi
echo
echo
echo "##########################################"
echo "######### CONFIGURING INSTANCE ###########"
echo "##########################################"
echo
echo
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



