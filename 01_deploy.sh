#!/bin/bash
mv env.sample .env
echo "##########################################"
echo "###### CONFIGURING ACCOUNT ELASTIC #######"
echo "##########################################"
echo  
password=$(cat .env | head -n 1 | awk -F= '{print $2}')
echo "The master password Elastic set in .env:" $password
echo
read -p "Confirm (y/n) ?" confirm

case $confirm in
        [yY][eE][sS]|[yY])
        sed -i "s/changeme/$password/g" .env cortex/application.conf elastalert/elastalert.yaml filebeat/filebeat.yml metricbeat/metricbeat.yml kibana/kibana.yml auditbeat/auditbeat.yml logstash/config/logstash.yml logstash/pipeline/300_output.conf sigma/dockerfile arkime/scripts/capture.sh arkime/scripts/config.sh arkime/scripts/import.sh arkime/scripts/init-db.sh arkime/scripts/viewer.sh arkime/config.ini
        sed -i "s/elastic_opencti/$password/g" docker-compose.yml
        ;;
        [nN][oO]|[nN])
        ;; *)
        echo "Invalid input ..."
     exit 1
     ;;
esac
echo
echo "##########################################"
echo "###### CONFIGURING KIBANA ACCOUNT #######"
echo "##########################################"
echo
echo
read -r -p "Enter the user for Kibana:" kibana_account
kibana_account=$kibana_account
echo
echo
read -r -sp "Enter the password for Kibana:" kibana_password
kibana_password=$kibana_password
echo
echo
echo "##########################################"
echo "###### CONFIGURING OPENCTI ACCOUNT #######"
echo "##########################################"
echo
echo
read -r -p "Enter the user for OpenCTI:" opencti_account
opencti_account=$opencti_account
sed -i "s/opencti_account/$opencti_account/g" .env
echo
echo
read -r -sp "Enter the password for OpenCTI:" opencti_password
opencti_password=$opencti_password
sed -i "s/opencti_password/$opencti_password/g" .env
echo
echo
echo "##########################################"
echo "####### CONFIGURING ARKIME ACCOUNT #######"
echo "##########################################"
echo
echo
read -r -p "Enter the user for Arkime:" arkime_account
arkime_account=$arkime_account
sed -i "s/arkime_account/$arkime_account/g" docker-compose.yml
echo
echo
read -r -sp "Enter the password for Arkime:" arkime_password
arkime_password=$arkime_password
sed -i "s/arkime_password/$arkime_password/g" docker-compose.yml
echo
echo
echo "##########################################"
echo "#### CONFIGURING MONITORING INTERFACE ####"
echo "##########################################"
echo
ip a | egrep -A 2 "ens[[:digit:]]{1,3}:|eth[[:digit:]]{1,3}:"
echo
echo
read -r -p "Enter the monitoring interface (ex:ens32):" monitoring_interface
monitoring_interface=$monitoring_interface
sed -i "s/network_monitoring/$monitoring_interface/g" docker-compose.yml
echo
echo
echo "##########################################"
echo "######### GENERATE CERTIFICATE ###########"
echo "##########################################"
mkdir ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ssl/server.key -out ssl/server.crt
chmod 600 ssl/server.key ssl/server.crt
echo
echo
echo "##########################################"
echo "########## DOCKER DOWNLOADING ############"
echo "##########################################"
echo
docker-compose pull
echo
echo
echo "##########################################"
echo "########## DOCKER DOWNLOADING ############"
echo "##########################################"
echo
docker-compose up -d elasticsearch kibana
docker-compose up -d
sleep 45
echo
echo
echo "##########################################"
echo "######## UPDATE SURICATA RULES ###########"
echo "##########################################"
echo
docker exec -ti suricata suricata-update update-sources
docker exec -ti suricata suricata-update --no-test
echo
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
rm ./signature-base/general_cloaking.yar ./signature-base/generic_anomalies.yar ./signature-base/yara_mixed_ext_vars.yar ./signature-base/thor_inverse_matches.yar
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
echo
echo
echo "##########################################"
echo "########## DEPLOY KIBANA INDEX ###########"
echo "##########################################"
echo
while [ "$(curl --insecure https://localhost/kibana 2> /dev/null | grep "Bad Gateway" )" ]; do
  echo "Waiting for Kibana to come online.";
  sleep 5;
done
echo
echo
echo
docker exec -ti elasticsearch elasticsearch-users useradd $kibana_account -p $kibana_password -r superuser
for index in $(find kibana/index/* -type f); do docker exec kibana sh -c "curl -X POST 'http://kibana:5601/kibana/api/saved_objects/_import?overwrite=true' -u 'elastic:$password' -H 'kbn-xsrf: true' -H 'Content-Type: multipart/form-data' --form file=@/usr/share/$index"; done
echo
