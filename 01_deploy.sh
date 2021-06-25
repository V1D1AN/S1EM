#!/bin/bash
mv env.sample .env
echo "##########################################"
echo "###### CONFIGURING ACCOUNT ELASTIC #######"
echo "###### AND KIBANA API KEY          ######"
echo "##########################################"
echo  
password=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c14)
kibana_api_key=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c32)
echo "The Kibana api key is : " $kibana_api_key
echo "The master password Elastic set in .env:" $password
echo
sed -i "s/kibana_api_key/$kibana_api_key/g" kibana/kibana.yml
sed -i "s/changeme/$password/g" .env cortex/application.conf elastalert/elastalert.yaml filebeat/filebeat.yml metricbeat/metricbeat.yml metricbeat/modules.d/elasticsearch-xpack.yml metricbeat/modules.d/kibana-xpack.yml kibana/kibana.yml auditbeat/auditbeat.yml logstash/config/logstash.yml logstash/pipeline/300_output.conf sigma/dockerfile arkime/scripts/capture.sh arkime/scripts/config.sh arkime/scripts/import.sh arkime/scripts/init-db.sh arkime/scripts/viewer.sh arkime/config.ini
sed -i "s/elastic_opencti/$password/g" docker-compose.yml
echo
echo
echo "##########################################"
echo "####### CONFIGURING ADMIN ACCOUNT ########"
echo "##### FOR KIBANA / OPENCTI / ARKIME ######"
echo "##########################################"
echo
read -r -p "Enter the admin account (Must be like user@domain.tld):" admin_account
admin_account=$admin_account
sed -i "s/kibana_account/$admin_account/g" elasticsearch/user.json
sed -i "s/opencti_account/$admin_account/g" .env
sed -i "s/arkime_account/$admin_account/g" .env
echo
while true; do
    read -s -p "Password (Must be a password with at least 6 characters): " admin_password
    echo
    read -s -p "Password (again): " admin_password2
    echo
    [ "$admin_password" = "$admin_password2" ] && break
    echo "Please try again"
done
sed -i "s/kibana_password/$admin_password/g" elasticsearch/user.json
sed -i "s/opencti_password/$admin_password/g" .env
sed -i "s/arkime_password/$admin_password/g" .env
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
echo
docker-compose -f create-certs.yml run --rm create_certs
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
echo "############ DOCKER STARTING #############"
echo "##########################################"
echo
chmod u=rx ./arkime/scripts/*.sh
docker-compose up -d es01 es02 es03 kibana
docker-compose up -d
sleep 45
docker exec -ti cortex keytool -import -alias ca -file /opt/cortex/certificates/ca/ca.crt -keystore /usr/local/openjdk-8/jre/lib/security/cacerts --storepass changeit -noprompt
echo
echo
echo "##########################################"
echo "########## DEPLOY KIBANA INDEX ###########"
echo "##########################################"
echo
while [ "$(docker logs kibana | grep -i "server running")" == "" ]; do
  echo "Waiting for Kibana to come online.";
  sleep 5;
done
echo "Kibana is online"
echo
echo
docker exec es01 sh -c "curl -k -X POST 'https://127.0.0.1:9200/_security/user/$admin_account' -u 'elastic:$password' -H 'Content-Type: application/json' -d@/usr/share/elasticsearch/config/user.json"
for index in $(find kibana/index/* -type f); do docker exec kibana sh -c "curl -k -X POST 'https://kibana:5601/kibana/api/saved_objects/_import?overwrite=true' -u 'elastic:$password' -H 'kbn-xsrf: true' -H 'Content-Type: multipart/form-data' --form file=@/usr/share/$index"; done
for dashboard in $(find kibana/dashboard/* -type f); do docker exec kibana sh -c "curl -k -X POST 'https://kibana:5601/kibana/api/saved_objects/_import?overwrite=true' -u 'elastic:$password' -H 'kbn-xsrf: true' -H 'Content-Type: multipart/form-data' --form file=@/usr/share/$dashboard"; done
docker exec logstash sh -c "curl -k -X PUT 'https://es01:9200/_component_template/pfelk-settings?pretty' -u 'elastic:$password' -H 'Content-Type: application/json' -d@/usr/share/logstash/templates/pfelk-settings"
docker exec logstash sh -c "curl -k -X PUT 'https://es01:9200/_component_template/pfelk-mapping-ecs?pretty' -u 'elastic:$password' -H 'Content-Type: application/json' -d@/usr/share/logstash/templates/pfelk-mapping-ecs"
docker exec logstash sh -c "curl -k -X PUT 'https://es01:9200/_ilm/policy/pfelk-ilm?pretty' -u 'elastic:$password' -H 'Content-Type: application/json' -d@/usr/share/logstash/templates/pfelk-ilm"
docker exec logstash sh -c "curl -k -X PUT 'https://es01:9200/_index_template/pfelk?pretty' -u 'elastic:$password' -H 'Content-Type: application/json' -d@/usr/share/logstash/templates/pfelk"
docker exec logstash sh -c "curl -k -X PUT 'https://es01:9200/_index_template/pfelk-dhcp?pretty' -u 'elastic:$password' -H 'Content-Type: application/json' -d@/usr/share/logstash/templates/pfelk-dhcp"
docker exec logstash sh -c "curl -k -X PUT 'https://es01:9200/_index_template/pfelk-haproxy?pretty' -u 'elastic:$password' -H 'Content-Type: application/json' -d@/usr/share/logstash/templates/pfelk-haproxy"
docker exec logstash sh -c "curl -k -X PUT 'https://es01:9200/_index_template/pfelk-suricata?pretty' -u 'elastic:$password' -H 'Content-Type: application/json' -d@/usr/share/logstash/templates/pfelk-suricata"
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
mkdir tmp
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
echo
echo "#########################################"
echo "############ DEPLOY FINISH ##############"
echo "#########################################"
echo
echo "Access url: https://s1em.cyber.local"
echo "Use the user account $admin_account for access to Kibana / OpenCTI / Arkime"
echo "The user for MISP / TheHive / Cortex / Fleet is not configured"
echo "The master password of elastic is in \".env\" "
