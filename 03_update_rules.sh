#!/bin/bash

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
rm tmp/malware/MALW_AZORULT.yar
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
docker-compose -f sigma.yml build
docker image prune -f
docker-compose -f sigma.yml up -d


