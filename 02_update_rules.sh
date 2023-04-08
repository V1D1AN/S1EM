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
mkdir tmp
git clone https://github.com/malpedia/signator-rules tmp
rm rules/yara/*.yar
mv tmp/rules/* rules/yara/
rm -fr tmp
cd rules/yara
bash index_gen.sh
rm index_w_mobile.yar
cd -
docker restart cortex
echo
echo "##########################################"
echo "########## UPDATE SIGMA RULES ############"
echo "##########################################"
echo
docker image rm -f sigma:1.0
docker container prune -f
docker compose -f sigma.yml build
docker compose -f sigma.yml up -d


