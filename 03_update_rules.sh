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
git clone https://github.com/Neo23x0/signature-base tmp
rm -fr rules/yara/signature-base/*
mv tmp/yara/* rules/yara/signature-base/
rm -fr tmp
cd rules/yara
rm index.yar ./signature-base/general_cloaking.yar ./signature-base/generic_anomalies.yar ./signature-base/yara_mixed_ext_vars.yar ./signature-base/thor_inverse_matches.yar
for i in `ls $(pwd)/signature-base`; do echo "include \"./signature-base/$i\"" >> index.yar; done
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


