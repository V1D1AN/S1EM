#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
cp env.sample .env
echo "##########################################"
echo "###### CONFIGURING ACCOUNT ELASTIC #######"
echo "###### AND KIBANA API KEY          ######"
echo "##########################################"
echo  
password=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c14)
kibana_password=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c14)
kibana_api_key=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c32)
cortex_api=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c32)
echo "The master password Elastic set in .env:" $password
echo "The master password Kibana set in .env:" $kibana_password
echo "The Kibana api key is : " $kibana_api_key
echo
sed -i "s|kibana_api_key|$kibana_api_key|g" kibana/kibana.yml
sed -i "s|changeme|$password|g" .env cortex/application.conf thehive/application.conf elastalert/elastalert.yaml filebeat/filebeat.yml metricbeat/metricbeat.yml heartbeat/heartbeat.yml metricbeat/modules.d/elasticsearch-xpack.yml metricbeat/modules.d/kibana-xpack.yml kibana/kibana.yml auditbeat/auditbeat.yml logstash/config/logstash.yml logstash/pipeline/beats/300_output_beats.conf logstash/pipeline/stoq/300_output_stoq.conf logstash/pipeline/pfelk/300_output_pfelk.conf sigma/dockerfile arkime/scripts/capture.sh arkime/scripts/config.sh arkime/scripts/import.sh arkime/scripts/init-db.sh arkime/scripts/viewer.sh arkime/config.ini cortex/Elasticsearch_IP.json cortex/Elasticsearch_Hash.json
sed -i "s|kibana_changeme|$kibana_password|g" .env
echo
echo
echo "##########################################"
echo "####### CONFIGURING ADMIN ACCOUNT ########"
echo "##### FOR KIBANA / OPENCTI / ARKIME ######"
echo "#####       THEHIVE / CORTEX        ######"
echo "##########################################"
echo
echo
read -r -p "Enter the admin account (Must be like user@domain.tld):" admin_account
admin_account=$admin_account
read -r -p "Enter the organization:" organization
organization=$organization
sed -i "s|opencti_account|$admin_account|g" .env
sed -i "s|arkime_account|$admin_account|g" .env
sed -i "s|n8n_account|$admin_account|g" .env
echo
while true; do
    read -s -p "Password (Must be a password with at least 6 characters): " admin_password
    echo
    read -s -p "Password (again): " admin_password2
    echo
    [ "$admin_password" = "$admin_password2" ] && break
    echo "Please try again"
done
sed -i "s|opencti_password|$admin_password|g" .env
sed -i "s|arkime_password|$admin_password|g" .env
sed -i "s|n8n_password|$admin_password|g" .env
echo
echo
echo "##########################################"
echo "####### CONFIGURING HOSTNAME S1EM ########"
echo "##########################################"
echo
echo
read -r -p "Enter the hostname of the solution S1EM (ex: s1em.cyber.local):" s1em_hostname
s1em_hostname=$s1em_hostname
sed -i "s|s1em_hostname|$s1em_hostname|g" docker-compose.yml thehive/application.conf cortex/MISP.json misp/config.php rules/elastalert/*.yml homer/config.yml filebeat/modules.d/threatintel.yml .env
echo
echo
echo "##########################################"
echo "####### CONFIGURING ACCOUNT MWDB #########"
echo "##########################################"
echo
echo
cd mwdb
bash ./gen_vars.sh
mwdb_password=$(cat mwdb-vars.env | grep MWDB_ADMIN_PASSWORD | cut -b 21-)
sed -i "s|mwdb_password|$mwdb_password|g" karton.ini
cd -
mwdb_postgres=$(sed -n "3p" mwdb/postgres-vars.env | cut -c19-)
sed -i "s|mwdb_postgres|$mwdb_postgres|g" postgres/databases.sh
echo
echo
echo "##########################################"
echo "#### CONFIGURING MONITORING INTERFACE ####"
echo "##########################################"
echo
echo
ip a | egrep -A 2 "ens[[:digit:]]{1,3}:|eth[[:digit:]]{1,3}:"
echo
echo
read -r -p "Enter the monitoring interface (ex:ens32):" monitoring_interface
monitoring_interface=$monitoring_interface
sed -i "s|network_monitoring|$monitoring_interface|g" docker-compose.yml suricata/suricata.yaml
########### Set Service to enable Promiscuous mode on monitoring interface on boot
# set service path
serviceConfigurationFile="/usr/lib/systemd/system/S1EM-promiscuous.service"
cp ./S1EM-promiscuous.service ${serviceConfigurationFile}
chmod 600 ${serviceConfigurationFile}
# set monitoring_interface name in service_configuration_file
sed -i "s;<monitoring_interface>;${monitoring_interface};" ${serviceConfigurationFile}
# reload systemd to implement new service
systemctl daemon-reload
# enable service
systemctl enable S1EM-promiscuous
# start service
systemctl start S1EM-promiscuous
###########
echo
echo
echo "##########################################"
echo "######### GENERATE CERTIFICATE ###########"
echo "##########################################"
echo
echo
docker-compose run --rm certificates
echo
echo
echo "##########################################"
echo "########## DOCKER DOWNLOADING ############"
echo "##########################################"
echo
echo
docker-compose pull
echo
echo
echo "##########################################"
echo "########## STARTING TRAEFIK ##############"
echo "##########################################"
echo
echo
docker-compose up -d traefik
echo
echo
echo "##########################################"
echo "############# STARTING HOMER #############"
echo "##########################################"
echo
echo
docker-compose up -d homer
echo
echo
echo "##########################################"
echo "##### STARTING ELASTICSEARCH/KIBANA ######"
echo "##########################################"
echo
echo
docker-compose up -d es01 es02 es03 kibana
while [ "$(docker exec es01 sh -c 'curl -sk https://127.0.0.1:9200 -u elastic:$password')" == "" ]; do
  echo "Waiting for Elasticsearch to come online.";
  sleep 15;
done
echo
echo
echo "##########################################"
echo "########## DEPLOY KIBANA INDEX ###########"
echo "##########################################"
echo
echo
while [ "$(docker logs kibana | grep -i "server running" | grep -v "NotReady")" == "" ]; do
  echo "Waiting for Kibana to come online.";
  sleep 15;
done
echo "Kibana is online"
echo
echo
docker exec es01 sh -c "curl -sk -X POST 'https://127.0.0.1:9200/_security/user/kibana_system/_password' -u 'elastic:$password' -H 'Content-Type: application/json'  -d '{\"password\":\"$kibana_password\"}'"
docker exec es01 sh -c "curl -sk -X POST 'https://127.0.0.1:9200/_security/user/$admin_account' -u 'elastic:$password' -H 'Content-Type: application/json' -d '{\"enabled\": true,\"password\": \"$admin_password\",\"roles\":\"superuser\",\"full_name\": \"$admin_account\"}'"
echo
echo "##########################################"
echo "##### STARTING RabbitMQ Redis Minio ######"
echo "##########################################"
echo
echo
docker-compose up -d rabbitmq redis minio
echo
echo
echo "##########################################"
echo "########## STARTING DATABASES ############"
echo "##########################################"
echo
echo
docker-compose up -d db postgres
echo
echo
echo "##########################################"
echo "############ STARTING MISP ###############"
echo "##########################################"
echo
echo
docker-compose up -d misp misp-modules
echo
echo
echo "##########################################"
echo "########### CONFIGURING MISP #############"
echo "##########################################"
echo
echo
while [ "$( curl -sk 'https://127.0.0.1/misp/users/login' | grep "MISP" )" == "" ]; do
  echo "Waiting for MISP to come online.";
  sleep 15;
done
misp_apikey=$(docker exec misp sh -c "mysql -u misp --password=misppass -D misp -e'select authkey from users;'" | sed "1d")
sed -i "s|misp_api_key|$misp_apikey|g" thehive/application.conf cortex/MISP.json filebeat/modules.d/threatintel.yml .env
echo
echo
echo "##########################################"
echo "###### ###STARTING BEATS AGENT ###########"
echo "##########################################"
echo
echo
docker-compose up -d filebeat metricbeat auditbeat
echo
echo
echo "##########################################"
echo "########### STARTING CORTEX ##############"
echo "##########################################"
echo
echo
docker-compose up -d cortex
docker exec -ti cortex keytool -delete -alias ca -keystore /usr/local/openjdk-8/jre/lib/security/cacerts --storepass changeit -noprompt
docker exec -ti cortex keytool -import -alias ca -file /opt/cortex/certificates/ca/ca.crt -keystore /usr/local/openjdk-8/jre/lib/security/cacerts --storepass changeit -noprompt
docker-compose restart cortex
echo
echo
echo "##########################################"
echo "######### DEPLOY CORTEX USER #############"
echo "##########################################"
echo
echo
while [ "$(docker exec cortex sh -c 'curl -s http://127.0.0.1:9001')" == "" ]; do
  echo "Waiting for Cortex to come online.";
  sleep 15;
done
curl -sk -L -XPOST "https://127.0.0.1/cortex/api/maintenance/migrate"
curl -sk -L -XPOST "https://127.0.0.1/cortex/api/user" -H 'Content-Type: application/json' -d "{\"login\" : \"admin@cortex.local\",\"name\" : \"admin@cortex.local\",\"roles\" : [\"superadmin\"],\"preferences\" : \"{}\",\"password\" : \"secret\", \"key\": \"$cortex_api\"}"
curl -sk -XPOST -H "Authorization: Bearer $cortex_api" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization" -d "{  \"name\": \"$organization\",\"description\": \"SOC team\",\"status\": \"Active\"}"
curl -sk -XPOST -H "Authorization: Bearer $cortex_api" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/user" -d "{\"name\": \"$admin_account\",\"roles\": [\"read\",\"analyze\",\"orgadmin\"],\"organization\": \"$organization\",\"login\": \"$admin_account\"}"
curl -sk -XPOST -H "Authorization: Bearer $cortex_api" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/user/$admin_account/password/set" -d "{ \"password\": \"$admin_password\" }"
curl -sk -XPOST -H "Authorization: Bearer $cortex_api" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/MISP_2_1" -d "{\"name\": \"MISP_2_1\",\"configuration\":{\"auto_extract_artifacts\":false,\"check_tlp\":true,\"max_tlp\":2,\"check_pap\":true,\"max_pap\":2},\"jobCache\": 10}"
curl -sk -XPOST -H "Authorization: Bearer $cortex_api" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/OpenCTI_SearchObservables_2_0" -d "{\"name\": \"OpenCTI_SearchObservables_2_0\",\"configuration\":{\"auto_extract_artifacts\":false,\"check_tlp\":true,\"max_tlp\":2,\"check_pap\":true,\"max_pap\":2},\"jobCache\": 10}"
curl -sk -XPOST -H "Authorization: Bearer $cortex_api" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/OTXQuery_2_0" -d "{\"name\": \"OTXQuery\",\"configuration\":{\"auto_extract_artifacts\":false,\"check_tlp\":true,\"max_tlp\":2,\"check_pap\":true,\"max_pap\":2},\"jobCache\": 10}"
curl -sk -XPOST -H "Authorization: Bearer $cortex_api" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/Elasticsearch_IP_Analysis_1_0" -d "{\"name\": \"Elasticsearch_IP_Analysis_1_0\",\"configuration\":{\"auto_extract_artifacts\":false,\"check_tlp\":true,\"max_tlp\":2,\"check_pap\":true,\"max_pap\":2},\"jobCache\": 10}"
curl -sk -XPOST -H "Authorization: Bearer $cortex_api" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/Elasticsearch_Hash_Analysis_1_0" -d "{\"name\": \"Elasticsearch_Hash_Analysis_1_0\",\"configuration\":{\"auto_extract_artifacts\":false,\"check_tlp\":true,\"max_tlp\":2,\"check_pap\":true,\"max_pap\":2},\"jobCache\": 10}"
cortex_apikey=$(curl -sk -XPOST -H "Authorization: Bearer $cortex_api" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/user/$admin_account/key/renew")
echo
echo
echo "##########################################"
echo "######### CONFIGURING THEHIVE ############"
echo "##########################################"
echo
echo
sed -i "s|cortex_api_key|$cortex_apikey|g" thehive/application.conf
echo
echo
echo "##########################################"
echo "########### STARTING THEHIVE #############"
echo "##########################################"
echo
echo
docker-compose up -d thehive
echo
echo
echo "##########################################"
echo "######## DEPLOY THEHIVE USER #############"
echo "##########################################"
echo
echo
while [ "$(docker exec thehive sh -c 'curl -s http://127.0.0.1:9000')" == "" ]; do
  echo "Waiting for TheHive to come online.";
  sleep 15;
done
curl -sk -L -XPOST "https://127.0.0.1/thehive/api/v0/organisation" -H 'Content-Type: application/json' -u admin@thehive.local:secret -d "{\"description\": \"SOC team\",\"name\": \"$organization\"}"
curl -sk -L -XPOST "https://127.0.0.1/thehive/api/v1/user" -H 'Content-Type: application/json' -u admin@thehive.local:secret -d "{\"login\": \"$admin_account\",\"name\": \"admin\",\"organisation\": \"$organization\",\"profile\": \"org-admin\",\"email\": \"$admin_account\",\"password\": \"$admin_password\"}"
thehive_apikey=$(curl -sk -L -XPOST "https://127.0.0.1/thehive/api/v1/user/$admin_account/key/renew" -u admin@thehive.local:secret)
echo
echo
echo "##########################################"
echo "######## CONFIGURING ELASTALERT ##########"
echo "##########################################"
echo
echo
sed -i "s|thehive_api_key|$thehive_apikey|g" elastalert/elastalert.yaml
echo
echo
echo "##########################################"
echo "############ STARTING MWDB ###############"
echo "##########################################"
echo
echo
docker-compose up -d mwdb mwdb-web
echo
echo
echo "##########################################"
echo "########### CONFIGURING MWDB #############"
echo "##########################################"
echo
echo
while [ "$(curl -s 'http://127.0.0.1:8080' | grep "Malware Database")" == "" ]; do
  echo "Waiting for Mwdb to come online.";
  sleep 15;
done
sleep 15
mwdb_admin_token=$(curl -s -X POST "http://127.0.0.1:8080/api/auth/login" -H  "accept: application/json" -H  "Content-Type: application/json" -d "{\"login\":\"admin\",\"password\":\"$mwdb_password\"}" | sed -n 's/.*"token": "\([^ ]\+\)".*/\1/p')
mwdb_apikey=$(curl -s -X POST -H "Authorization: Bearer $mwdb_admin_token" -H 'accept: application/json' -H "Content-Type: application/json" "http://127.0.0.1:8080/api/user/admin/api_key" -d "{ \"name\": \"mwdb\"}" | sed -n 's/.*"token": "\([^ ]\+\)".*/\1/p')
echo
echo
echo "##########################################"
echo "########### CONFIGURING STOQ #############"
echo "##########################################"
echo
echo
sed -i "s|mwdb_api_key|$mwdb_apikey|g" stoq/stoq.cfg
echo
echo
echo "##########################################"
echo "############# STARTING STOQ ##############"
echo "##########################################"
echo
echo
docker-compose up -d stoq
echo
echo
echo "##########################################"
echo "########## DEPLOY KIBANA INDEX ###########"
echo "##########################################"
echo
echo
for index in $(find kibana/index/* -type f); do docker exec kibana sh -c "curl -sk -X POST 'https://kibana:5601/kibana/api/saved_objects/_import?overwrite=true' -u 'elastic:$password' -H 'kbn-xsrf: true' -H 'Content-Type: multipart/form-data' --form file=@/usr/share/$index"; done
sleep 10
for dashboard in $(find kibana/dashboard/* -type f); do docker exec kibana sh -c "curl -sk -X POST 'https://kibana:5601/kibana/api/saved_objects/_import?overwrite=true' -u 'elastic:$password' -H 'kbn-xsrf: true' -H 'Content-Type: multipart/form-data' --form file=@/usr/share/$dashboard"; done
sleep 10
echo
echo
echo "##########################################"
echo "########## STARTING LOGSTASH #############"
echo "##########################################"
echo
echo
docker-compose up -d logstash
echo
echo
echo "##########################################"
echo "######### CONFIGURING LOGSTASH ###########"
echo "##########################################"
echo
echo
docker exec logstash sh -c "curl -sk -X PUT 'https://es01:9200/_component_template/pfelk-settings?pretty' -u 'elastic:$password' -H 'Content-Type: application/json' -d@/usr/share/logstash/templates/pfelk-settings"
docker exec logstash sh -c "curl -sk -X PUT 'https://es01:9200/_component_template/pfelk-mappings-ecs?pretty' -u 'elastic:$password' -H 'Content-Type: application/json' -d@/usr/share/logstash/templates/pfelk-mappings-ecs"
docker exec logstash sh -c "curl -sk -X PUT 'https://es01:9200/_ilm/policy/pfelk-ilm?pretty' -u 'elastic:$password' -H 'Content-Type: application/json' -d@/usr/share/logstash/templates/pfelk-ilm"
docker exec logstash sh -c "curl -sk -X PUT 'https://es01:9200/_index_template/pfelk?pretty' -u 'elastic:$password' -H 'Content-Type: application/json' -d@/usr/share/logstash/templates/pfelk"
docker exec logstash sh -c "curl -sk -X PUT 'https://es01:9200/_index_template/pfelk-dhcp?pretty' -u 'elastic:$password' -H 'Content-Type: application/json' -d@/usr/share/logstash/templates/pfelk-dhcp"
docker exec logstash sh -c "curl -sk -X PUT 'https://es01:9200/_index_template/pfelk-haproxy?pretty' -u 'elastic:$password' -H 'Content-Type: application/json' -d@/usr/share/logstash/templates/pfelk-haproxy"
docker exec logstash sh -c "curl -sk -X PUT 'https://es01:9200/_index_template/pfelk-suricata?pretty' -u 'elastic:$password' -H 'Content-Type: application/json' -d@/usr/share/logstash/templates/pfelk-suricata"
echo
echo
echo "##########################################"
echo "########### STARTING ARKIME ##############"
echo "##########################################"
echo
echo
chmod u=rx ./arkime/scripts/*.sh
docker-compose up -d arkime
echo
echo
echo "##########################################"
echo "######## STARTING SURICATA/ZEEK ##########"
echo "##########################################"
echo
echo
docker-compose up -d suricata zeek
echo
echo
echo "##########################################"
echo "######## UPDATE SURICATA RULES ###########"
echo "##########################################"
echo
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
echo
echo "##########################################"
echo "######### INSTALL SIGMA RULES ############"
echo "##########################################"
echo
echo
curl -sk -XPOST -u elastic:$password "https://127.0.0.1/kibana/s/default/api/detection_engine/index" -H "kbn-xsrf: true"
docker image rm -f sigma:1.0
docker container prune -f
docker-compose -f sigma.yml build
docker-compose -f sigma.yml up -d
echo
echo
echo "#########################################"
echo "########## STARTING OPENCTI #############"
echo "#########################################"
echo
echo
docker-compose up -d opencti
echo
echo
echo "#########################################"
echo "############ STARTING N8N ###############"
echo "#########################################"
echo
echo
docker-compose up -d n8n
echo
echo
echo "#########################################"
echo "####### STARTING OTHER DOCKER ###########"
echo "#########################################"
echo
echo
docker-compose up -d elastalert cyberchef file-upload syslog-ng tcpreplay clamav heartbeat spiderfoot codimd watchtower
echo
echo
echo "#########################################"
echo "############ DEPLOY FINISH ##############"
echo "#########################################"
echo
echo "Access url: https://$s1em_hostname"
echo "Use the user account $admin_account for access to Kibana / OpenCTI / Arkime / TheHive / Cortex"
echo "The user admin for MWDB have password $mwdb_password "
echo "The master password of elastic is in \".env\" "
