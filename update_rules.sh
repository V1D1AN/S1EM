#!/bin/bash

echo "##########################################"
echo "######## UPDATE SURICATA RULES ###########"
echo "##########################################"

docker exec -ti suricata suricata-update update-sources
docker exec -ti suricata suricata-update --no-test

echo "##########################################"
echo "########## UPDATE YARA RULES #############"
echo "##########################################"

mkdir tmp
git clone https://github.com/Yara-Rules/rules.git tmp
rm -fr stoq/rules/yara/*
rm tmp/malware/MALW_AZORULT.yar
mv tmp/* stoq/rules/yara/
rm -fr tmp
cd stoq/rules/yara
bash index_gen.sh
docker restart stoq
