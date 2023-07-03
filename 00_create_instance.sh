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
if ! command_exists curl
  then
        echo "Please install curl"
        exit
  else
        echo "curl installed"
fi
if ! command_exists jq
  then
        echo "Please install jq"
        exit
  else
        echo "jq installed"
fi
if ! command_exists ifconfig
  then
        echo "Please install ifconfig"
        exit
  else
        echo "ifconfig installed"
fi
if ! command_exists netstat
  then
        echo "Please install netstat"
        exit
  else
        echo "netstat installed"
fi
if ! command_exists openssl
  then
        echo "Please install openssl"
        exit
  else
        echo "openssl installed"
fi
if ! command_exists rsync
  then
        echo "Please install rsync"
        exit
  else
        echo "rsync installed"
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
	echo "INSTANCE=$name" >> env.sample
    sudo bash 01_deploy.sh
    cd ..
else
    echo "directory/instance name found, deployment stopped"
fi