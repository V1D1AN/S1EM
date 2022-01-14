#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
echo "##########################################"
echo "######## UPDATE SURICATA RULES ###########"
echo "##########################################"
echo
docker exec -ti suricata suricata-update update-sources
docker exec -ti suricata suricata-update --no-test
echo
echo "##########################################"
echo "########## UPDATE YARA RULES #############"
echo "##########################################"
echo
git clone https://github.com/Yara-Rules/rules.git tmp
rm -fr rules/yara/*
rm -fr tmp/deprecated
rm -fr tmp/malware
rm -fr tmp/malware_index.yar
mv tmp/* rules/yara/
rm -fr tmp
cd rules/yara
bash index_gen.sh
cd -
docker restart stoq
docker restart cortex
echo
echo "##########################################"
echo "########## UPDATE SIGMA RULES ############"
echo "##########################################"
echo
docker image rm -f sigma:1.0
docker container prune -f
docker-compose -f sigma.yml build
docker-compose -f sigma.yml up -d


