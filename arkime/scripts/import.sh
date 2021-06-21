#!/bin/bash

err_msg () { printf '\033[0;31m[ ERROR ]\033[0m' && echo -e "\t"$(date)"\t"$BASH_SOURCE"\t"$1; }
warn_msg () { printf '\033[1;33m[ WARN ]\033[0m' && echo -e "\t"$(date)"\t"$BASH_SOURCE"\t"$1; }
info_msg () { printf '\033[0;36m[ INFO ]\033[0m' && echo -e "\t"$(date)"\t"$BASH_SOURCE"\t"$1; }

FLAG="/arkime/bin/flags"

info_msg "[ Arkime Import ] has been started."

## WAIT FOR ELASTICSEARCH TO COME ONLINE ##
#
while [ "$(curl -k https://elastic:changeme@es01:9200/_cluster/health?pretty 2> /dev/null | grep status | awk -F '"' '{print $4}')" != "green" ]; do 
  warn_msg "Waiting for ElasticSearch to come online..."; 
  sleep 5; 
done

info_msg "ElasticSearch is online."

## CONFIGURE ARKIME & CREATE USER ##
#
if [ -e "$FLAG/conf_arkime" ]; then

  /arkime/bin/config.sh;

  ## WAIT FOR INIT-DB ##
  #
  while [ "$(curl arkime:8005 2> /dev/null)" != "Unauthorized" ]; do 
    warn_msg "Waiting for [ Arkime Viewer ] to come online...";
    sleep 5; 
  done;

  info_msg "[ Arkime Viewer ] is online.";

  ## CREATE USER ## 
  #
  /arkime/bin/add-user.sh;

  rm $FLAG/conf_arkime;
fi

## ENABLE PCAP DOWNLOAD FROM VIEWER ##
#
info_msg "Enabling access to imported .pcap files for [ Arkime Viewer ] over port 8005."
cd $ARKIME_DIR/viewer && ../bin/node ./viewer.js -c ../etc/config.ini | tee -a /arkime/log/$(hostname).log > /dev/null &

info_msg "[ Arkime Import ] is now watching %root%/import/ for .pcap files."

inotifywait -m --format '%f' -e close_write /import/ | while read FILE
do
   cp /import/$FILE /arkime/data 
   chmod +r /arkime/data/$FILE;
   $ARKIME_DIR/bin/moloch-capture -r /arkime/data/$FILE | tee -a /arkime/log/$(hostname).log > /dev/null;
done;


err_msg "Powering down [ Arkime Import ]..."

#'lost'21jn
