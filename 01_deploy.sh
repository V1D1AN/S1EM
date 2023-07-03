#!/bin/bash
SCRIPTDIR="$(pwd)"
mkdir certs
cp env.sample .env
echo "##########################################"
echo "###### CONFIGURING ACCOUNT ELASTIC #######"
echo "###### AND KIBANA API KEY          ######"
echo "##########################################"
echo  
echo
password=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c14)
kibana_password=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c14)
kibana_api_key=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c32)
cortex_api=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c32)
echo "The master password Elastic set in .env:" $password
echo "The master password Kibana set in .env:" $kibana_password
echo "The Kibana api key is : " $kibana_api_key
sed -i "s|kibana_api_key|$kibana_api_key|g" kibana/kibana.yml
sed -i "s|kibana_changeme|$kibana_password|g" .env
echo
echo
echo "##########################################"
echo "####### CONFIGURING ADMIN ACCOUNT ########"
echo "##### FOR KIBANA / OPENCTI / ARKIME ######"
echo "#####    THEHIVE / CORTEX  / MISP   ######"
echo "##########################################"
echo
echo
read -r -p "Enter the admin account (Must be like user@domain.tld):" admin_account
admin_account=$admin_account
read -r -p "Enter the organization (Must be like 'Cyber'):" organization
organization=$organization
sed -i "s|organization_name|$organization|g" .env
sed -i "s|opencti_account|$admin_account|g" .env
sed -i "s|arkime_account|$admin_account|g" .env
sed -i "s|n8n_account|$admin_account|g" .env
sed -i "s|zircolite_account|$admin_account|g" .env
echo
while true; do
    read -s -p "Password (Must be a password with at least 6 characters):" admin_password
    echo
    read -s -p "Password (again):" admin_password2
    echo
    [ "$admin_password" = "$admin_password2" ] && break
    echo "Please try again"
done
sed -i "s|opencti_password|$admin_password|g" .env
sed -i "s|arkime_password|$admin_password|g" .env
sed -i "s|n8n_password|$admin_password|g" .env
sed -i "s|zircolite_password|$admin_password|g" .env
echo
echo
echo "##########################################"
echo "####### CONFIGURING HOSTNAME S1EM ########"
echo "##########################################"
echo
echo
read -r -p "Enter the hostname of the solution S1EM (ex: s1em.cyber.local):" s1em_hostname
s1em_hostname=$s1em_hostname
sed -i "s|s1em_hostname|$s1em_hostname|g" docker-compose-multi.yml docker-compose-single.yml thehive/application.conf cortex/MISP.json misp/config.php rules/elastalert/*.yml homer/config.yml filebeat/modules.d/threatintel.yml .env
echo
echo "##########################################"
echo "####### CONFIGURING ACCOUNT MWDB #########"
echo "##########################################"
echo
echo
bash ./mwdb/gen_vars.sh
mwdb_password=$(cat mwdb/mwdb-vars.env | grep MWDB_ADMIN_PASSWORD | cut -b 21-)
sed -i "s|mwdb_password|$mwdb_password|g" mwdb/karton.ini
mwdb_postgres=$(sed -n "3p" mwdb/postgres-vars.env | cut -c19-)
sed -i "s|mwdb_postgres|$mwdb_postgres|g" postgres/databases.sh
echo
echo
echo "##########################################"
echo "### CONFIGURING CLUSTER ELASTICSEARCH  ###"
echo "##########################################"
echo
echo
while true; do
    read -r -p "Do you want use 1 node elasticsearch (Single) or 3 nodes elasticsearch (Multi) [S/M]?" cluster
    case $cluster in
        [Ss]) cluster=SINGLE; break;;
        [Mm]) cluster=MULTI; break;;
        * ) echo "Please answer (S/s) or (M/m).";;
    esac
done
if 	 [ "$cluster" == SINGLE ];
then
		cp docker-compose-single.yml docker-compose.yml
		cp instances-single.yml instances.yml
		cp auditbeat/auditbeat-single.yml auditbeat/auditbeat.yml
		cp filebeat/filebeat-single.yml filebeat/filebeat.yml
		cp heartbeat/heartbeat-single.yml heartbeat/heartbeat.yml
		cp metricbeat/metricbeat-single.yml metricbeat/metricbeat.yml
        	cp cortex/application-single.conf cortex/application.conf
      		cp arkime/config-single.ini arkime/config.ini
      		cp arkime/scripts/init-db-single.sh arkime/scripts/init-db.sh
		rm heartbeat/monitors.d/es02.yml heartbeat/monitors.d/es03.yml
elif [ "$cluster" == MULTI ];
then
        	cp docker-compose-multi.yml docker-compose.yml
		cp instances-multi.yml instances.yml
		cp auditbeat/auditbeat-multi.yml auditbeat/auditbeat.yml
		cp filebeat/filebeat-multi.yml filebeat/filebeat.yml
		cp heartbeat/heartbeat-multi.yml heartbeat/heartbeat.yml
		cp metricbeat/metricbeat-multi.yml metricbeat/metricbeat.yml
        	cp cortex/application-multi.conf cortex/application.conf
      		cp arkime/config-multi.ini arkime/config.ini
      		cp arkime/scripts/init-db-multi.sh arkime/scripts/init-db.sh
fi
if 	 [ "$cluster" == SINGLE ];
then
		read -p "Enter the RAM in Go of node elasticsearch [2]:" master_node
		master_node=${master_node:-2}
		sed -i "s|RAM_MASTER|$master_node|g" docker-compose.yml
elif [ "$cluster" == MULTI ];
then
        read -p "Enter the RAM in Go of master node elasticsearch [2]:" master_node
		master_node=${master_node:-2}
		sed -i "s|RAM_MASTER|$master_node|g" docker-compose.yml
		read -p "Enter the RAM in Go of data,ingest node elasticsearch [4]:" data_node
		data_node=${data_node:-4}
		sed -i "s|RAM_DATA|$data_node|g" docker-compose.yml
fi
sed -i "s|changeme|$password|g" .env cortex/application.conf thehive/application.conf elastalert/elastalert.yaml filebeat/filebeat.yml metricbeat/metricbeat.yml heartbeat/heartbeat.yml metricbeat/modules.d/elasticsearch-xpack.yml metricbeat/modules.d/kibana-xpack.yml kibana/kibana.yml auditbeat/auditbeat.yml logstash/config/logstash.yml logstash/pipeline/beats/300_output_beats.conf logstash/pipeline/zircolite/300_output_zircolite.conf sigma/dockerfile arkime/scripts/capture.sh arkime/scripts/config.sh arkime/scripts/import.sh arkime/scripts/init-db.sh arkime/scripts/viewer.sh arkime/config.ini cortex/Elasticsearch_Domain.json cortex/Elasticsearch_IP.json cortex/Elasticsearch_Hash.json
echo
echo
echo "##########################################"
echo "########## CONFIGURING THEHIVE ###########"
echo "##########################################"
echo
echo
read -p "Enter the RAM in Go of TheHive [1]:" ram_thehive
ram_thehive=${ram_thehive:-1}
sed -i "s|RAM_THEHIVE|$ram_thehive|g" docker-compose.yml
echo
echo
echo "##########################################"
echo "########### CONFIGURING CORTEX ###########"
echo "##########################################"
echo
echo
read -p "Enter the RAM in Go of Cortex [1]:" ram_cortex
ram_cortex=${ram_cortex:-1}
sed -i "s|RAM_CORTEX|$ram_cortex|g" docker-compose.yml
echo
echo
echo "##########################################"
echo "######### CONFIGURING INTERFACES #########"
echo "##########################################"
echo
echo
ip a | egrep -A 2 "ens[[:digit:]]{1,3}:|eth[[:digit:]]{1,3}:"
echo
echo
read -r -p "Enter the administration interface (ex:ens32):" administration_interface
administration_interface=$administration_interface
INTERFACE=`netstat -rn | grep ${administration_interface} | awk '{ print $NF }'| tail -n1`
ADMINISTRATION_IP=`ifconfig ${INTERFACE} | grep inet | awk '{ print $2 }' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'`
echo "Interface: ${INTERFACE}   IP found: ${ADMINISTRATION_IP}"
sed -i "s;administrationip;${ADMINISTRATION_IP};" instances.yml .env
echo
echo
ip a | egrep -A 2 "ens[[:digit:]]{1,3}:|eth[[:digit:]]{1,3}:"
echo
echo
read -r -p "Enter the monitoring interface (ex:ens33):" monitoring_interface
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
echo "########## CONFIGURE DETECTION ###########"
echo "##########################################"
echo
echo
while true; do
    read -r -p "Do you want use detection with rules of Sigma or Elastic (Elastic recommanded) [E/S]?" rules
    case $rules in
        [Ee]) detection=ELASTIC; break;;
        [Ss]) detection=SIGMA; break;;
        * ) echo "Please answer (E/e) or (S/s).";;
    esac
done
echo
echo
echo "##########################################"
echo "############# CONFIRMATION ###############"
echo "##########################################"
echo
echo
echo "The administration account: $admin_account"
echo "The organization: $organization"
echo "The S1EM hostname: $s1em_hostname"
echo "The cluster Elasticsearch: $cluster"
echo "The RAM of Master node of Elasticsearch: $master_node"
echo "The RAM of Data node of Elasticsearch: $data_node"
echo "The RAM of TheHive: $ram_thehive"
echo "The RAM of Cortex: $ram_cortex"
echo "The administration interface: $administration_interface"
echo "The administration ip: $ADMINISTRATION_IP"
echo "The monitoring interface: $monitoring_interface"
echo "The choice of rules: $detection"
echo
while true; do
    read -r -p "Do you confirm for installation [Y/N]?" choice
    case $choice in
        [Yy]) echo "Starting of installation"; break;;
        [Nn]) echo "Stopping of installation"; exit 0;;
        * ) echo "Please answer (Y/y) or (Y/y).";;
    esac
done
echo
echo
echo "##########################################"
echo "######### GENERATE CERTIFICATE ###########"
echo "##########################################"
echo
echo
docker compose run --rm certificates
echo
echo
echo "##########################################"
echo "########## DOCKER DOWNLOADING ############"
echo "##########################################"
echo
echo
docker compose pull
echo
echo
echo "##########################################"
echo "########## STARTING TRAEFIK ##############"
echo "##########################################"
echo
echo
docker compose up -d traefik
echo
echo
echo "##########################################"
echo "############# STARTING HOMER #############"
echo "##########################################"
echo
echo
docker compose up -d homer
echo
echo
echo "##########################################"
echo "##### STARTING ELASTICSEARCH/KIBANA ######"
echo "##########################################"
echo
echo
if 	 [ "$cluster" == SINGLE ];
then
		docker compose up -d es01 kibana
elif [ "$cluster" == MULTI ];
then
		docker compose up -d es01 es02 es03 kibana 
fi
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
docker exec es01 sh -c "curl -sk -X POST 'https://127.0.0.1:9200/_security/user/kibana_system/_password' -u 'elastic:$password' -H 'Content-Type: application/json'  -d '{\"password\":\"$kibana_password\"}'" >/dev/null 2>&1
docker exec es01 sh -c "curl -sk -X POST 'https://127.0.0.1:9200/_security/user/$admin_account' -u 'elastic:$password' -H 'Content-Type: application/json' -d '{\"enabled\": true,\"password\": \"$admin_password\",\"roles\":\"superuser\",\"full_name\": \"$admin_account\"}'" >/dev/null 2>&1
echo
echo
echo "##########################################"
echo "##### STARTING RabbitMQ Redis Minio ######"
echo "##########################################"
echo
echo
docker compose up -d rabbitmq redis minio
echo
echo
echo "##########################################"
echo "########## STARTING DATABASES ############"
echo "##########################################"
echo
echo
docker compose up -d db postgres
echo
echo
echo "##########################################"
echo "############ STARTING MISP ###############"
echo "##########################################"
echo
echo
docker compose up -d misp misp-modules
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
sleep 30
curl -sk -X POST --header "Authorization: $misp_apikey" --header "Accept: application/json" --header "Content-Type: application/json" 'https://127.0.0.1/misp/admin/organisations/add' -d "{\"name\" :\"$organization\"}" >/dev/null 2>&1
sleep 5
curl -sk -X POST --header "Authorization: $misp_apikey" --header "Accept: application/json" --header "Content-Type: application/json" 'https://127.0.0.1/misp/admin/users/edit/1' -d "{\"password\":\"$admin_password\", \"email\": \"$admin_account\",\"change_pw\":false, \"org_id\":\"2\"}" >/dev/null 2>&1
echo
echo "Load external Feed List"
curl -sk -X POST --header "Authorization: $misp_apikey" --header "Accept: application/json" --header "Content-Type: application/json" https://127.0.0.1/misp/feeds/loadDefaultFeeds >/dev/null 2>&1
sleep 30
echo "Enable Feeds "
curl -sk -X POST --header "Authorization: $misp_apikey" --header "Accept: application/json" --header "Content-Type: application/json" https://127.0.0.1/misp/feeds/enable/1 >/dev/null 2>&1
curl -sk -X POST --header "Authorization: $misp_apikey" --header "Accept: application/json" --header "Content-Type: application/json" https://127.0.0.1/misp/feeds/enable/2 >/dev/null 2>&1
echo "Starting Feed synchronisation in background"
curl -sk -X POST --header "Authorization: $misp_apikey" --header "Accept: application/json" --header "Content-Type: application/json" https://127.0.0.1/misp/feeds/fetchFromAllFeeds >/dev/null 2>&1
echo
echo
echo "##########################################"
echo "###### ###STARTING BEATS AGENT ###########"
echo "##########################################"
echo
echo
docker compose up -d filebeat 
docker compose up -d metricbeat 
docker compose up -d auditbeat
echo
echo
echo "##########################################"
echo "############ STARTING MWDB ###############"
echo "##########################################"
echo
echo
docker compose up -d mwdb mwdb-web
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
echo "###### CONFIGURING MWDB FOR CORTEX #######"
echo "##########################################"
echo
echo
sed -i "s|mwdb_api_key|$mwdb_apikey|g" .env cortex/Mwdb.json
echo
echo
echo "##########################################"
echo "########### STARTING CORTEX ##############"
echo "##########################################"
echo
echo
docker compose up -d cortex
docker exec -ti cortex keytool -delete -alias ca -keystore /usr/local/openjdk-8/jre/lib/security/cacerts --storepass changeit -noprompt >/dev/null
docker exec -ti cortex keytool -import -alias ca -file /opt/cortex/certificates/ca/ca.crt -keystore /usr/local/openjdk-8/jre/lib/security/cacerts --storepass changeit -noprompt
docker compose restart cortex
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
curl -sk -L -XPOST "https://127.0.0.1/cortex/api/user" -H 'Content-Type: application/json' -d "{\"login\" : \"admin@cortex.local\",\"name\" : \"admin@cortex.local\",\"roles\" : [\"superadmin\"],\"preferences\" : \"{}\",\"password\" : \"secret\", \"key\": \"$cortex_api\"}" >/dev/null 2>&1
curl -sk -XPOST -H "Authorization: Bearer $cortex_api" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization" -d "{  \"name\": \"$organization\",\"description\": \"SOC team\",\"status\": \"Active\"}" >/dev/null 2>&1
curl -sk -XPOST -H "Authorization: Bearer $cortex_api" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/user" -d "{\"name\": \"$admin_account\",\"roles\": [\"read\",\"analyze\",\"orgadmin\"],\"organization\": \"$organization\",\"login\": \"$admin_account\"}" >/dev/null 2>&1
curl -sk -XPOST -H "Authorization: Bearer $cortex_api" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/user/$admin_account/password/set" -d "{ \"password\": \"$admin_password\" }" >/dev/null 2>&1
cortex_apikey=$(curl -sk -XPOST -H "Authorization: Bearer $cortex_api" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/user/$admin_account/key/renew")
curl -sk -XPOST -H "Authorization: Bearer $cortex_apikey" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/MISP_2_1" -d "{\"name\": \"MISP_2_1\",\"configuration\":{\"auto_extract_artifacts\":false,\"check_tlp\":true,\"max_tlp\":2,\"check_pap\":true,\"max_pap\":2},\"jobCache\": 10}" >/dev/null 2>&1
curl -sk -XPOST -H "Authorization: Bearer $cortex_apikey" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/OpenCTI_SearchObservables_2_0" -d "{\"name\": \"OpenCTI_SearchObservables_2_0\",\"configuration\":{\"auto_extract_artifacts\":false,\"check_tlp\":true,\"max_tlp\":2,\"check_pap\":true,\"max_pap\":2},\"jobCache\": 10}" >/dev/null 2>&1
curl -sk -XPOST -H "Authorization: Bearer $cortex_apikey" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/OTXQuery_2_0" -d "{\"name\": \"OTXQuery\",\"configuration\":{\"auto_extract_artifacts\":false,\"check_tlp\":true,\"max_tlp\":2,\"check_pap\":true,\"max_pap\":2},\"jobCache\": 10}" >/dev/null 2>&1
curl -sk -XPOST -H "Authorization: Bearer $cortex_apikey" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/Elasticsearch_IP_Analysis_1_0" -d "{\"name\": \"Elasticsearch_IP_Analysis_1_0\",\"configuration\":{\"auto_extract_artifacts\":false,\"check_tlp\":true,\"max_tlp\":2,\"check_pap\":true,\"max_pap\":2},\"jobCache\": 10}" >/dev/null 2>&1
curl -sk -XPOST -H "Authorization: Bearer $cortex_apikey" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/Elasticsearch_Hash_Analysis_1_0" -d "{\"name\": \"Elasticsearch_Hash_Analysis_1_0\",\"configuration\":{\"auto_extract_artifacts\":false,\"check_tlp\":true,\"max_tlp\":2,\"check_pap\":true,\"max_pap\":2},\"jobCache\": 10}" >/dev/null 2>&1
curl -sk -XPOST -H "Authorization: Bearer $cortex_apikey" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/Elasticsearch_Domain_Analysis_1_0" -d "{\"name\": \"Elasticsearch_Domain_Analysis_1_0\",\"configuration\":{\"auto_extract_artifacts\":false,\"check_tlp\":true,\"max_tlp\":2,\"check_pap\":true,\"max_pap\":2},\"jobCache\": 10}" >/dev/null 2>&1
curl -sk -XPOST -H "Authorization: Bearer $cortex_apikey" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/CIRCLHashlookup_1_1" -d "{\"name\": \"CIRCLHashlookup_1_1\",\"configuration\":{\"auto_extract_artifacts\":false,\"check_tlp\":true,\"max_tlp\":2,\"check_pap\":true,\"max_pap\":2},\"jobCache\": 10}" >/dev/null 2>&1
curl -sk -XPOST -H "Authorization: Bearer $cortex_apikey" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/Capa_1_0" -d "{\"name\": \"Capa_1_0\",\"configuration\":{\"auto_extract_artifacts\":true,\"check_tlp\":true,\"max_tlp\":3,\"check_pap\":true,\"max_pap\":3},\"jobCache\": 10}" >/dev/null 2>&1
curl -sk -XPOST -H "Authorization: Bearer $cortex_apikey" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/Yara_2_0" -d "{\"name\": \"Yara_2_0\",\"configuration\":{\"auto_extract_artifacts\":true,\"check_tlp\":true,\"max_tlp\":3,\"check_pap\":true,\"max_pap\":3},\"jobCache\": 10}" >/dev/null 2>&1
curl -sk -XPOST -H "Authorization: Bearer $cortex_apikey" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/FileInfo_8_0" -d "{\"name\": \"FileInfo_8_0\",\"configuration\":{\"auto_extract_artifacts\":true,\"check_tlp\":true,\"max_tlp\":3,\"check_pap\":true,\"max_pap\":3},\"jobCache\": 10}" >/dev/null 2>&1
curl -sk -XPOST -H "Authorization: Bearer $cortex_apikey" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/Mwdb_1_0" -d "{\"name\": \"Mwdb_1_0\",\"configuration\":{\"auto_extract_artifacts\":true,\"check_tlp\":true,\"max_tlp\":3,\"check_pap\":true,\"max_pap\":3},\"jobCache\": 10}" >/dev/null 2>&1
s1em_analyzer_misp=$(curl -sk -H "Authorization: Bearer $cortex_apikey" 'https://127.0.0.1/cortex/api/analyzer/type/hash' | jq -r '.[] | select(.name=="MISP_2_1") | .id')
sed -i "s|s1em_analyzer_misp|$s1em_analyzer_misp|g" n8n/S1EM_TheHive.json
s1em_analyzer_opencti=$(curl -sk -H "Authorization: Bearer $cortex_apikey" 'https://127.0.0.1/cortex/api/analyzer/type/hash' | jq -r '.[] | select(.name=="OpenCTI_SearchObservables_2_0") | .id')
sed -i "s|s1em_analyzer_opencti|$s1em_analyzer_opencti|g" n8n/S1EM_TheHive.json
s1em_analyzer_otx=$(curl -sk -H "Authorization: Bearer $cortex_apikey" 'https://127.0.0.1/cortex/api/analyzer/type/hash' | jq -r '.[] | select(.name=="OTXQuery") | .id')
sed -i "s|s1em_analyzer_otx|$s1em_analyzer_otx|g" n8n/S1EM_TheHive.json
s1em_analyzer_elasticsearch_ip=$(curl -sk -H "Authorization: Bearer $cortex_apikey" 'https://127.0.0.1/cortex/api/analyzer' | jq -r '.[] | select(.name=="Elasticsearch_IP_Analysis_1_0") | .id')
sed -i "s|s1em_analyzer_elasticsearch_ip|$s1em_analyzer_elasticsearch_ip|g" n8n/S1EM_TheHive.json
s1em_analyzer_elasticsearch_hash=$(curl -sk -H "Authorization: Bearer $cortex_apikey" 'https://127.0.0.1/cortex/api/analyzer/type/hash' | jq -r '.[] | select(.name=="Elasticsearch_Hash_Analysis_1_0") | .id')
sed -i "s|s1em_analyzer_elasticsearch_hash|$s1em_analyzer_elasticsearch_hash|g" n8n/S1EM_TheHive.json
s1em_analyzer_elasticsearch_domain=$(curl -sk -H "Authorization: Bearer $cortex_apikey" 'https://127.0.0.1/cortex/api/analyzer' | jq -r '.[] | select(.name=="Elasticsearch_Domain_Analysis_1_0") | .id')
sed -i "s|s1em_analyzer_elasticsearch_domain|$s1em_analyzer_elasticsearch_domain|g" n8n/S1EM_TheHive.json
s1em_analyzer_circl=$(curl -sk -H "Authorization: Bearer $cortex_apikey" 'https://127.0.0.1/cortex/api/analyzer/type/hash'|jq -r '.[] | select(.name=="CIRCLHashlookup_1_1") | .id')
sed -i "s|s1em_analyzer_circl|$s1em_analyzer_circl|g" n8n/S1EM_TheHive.json
s1em_analyzer_capa=$(curl -sk -H "Authorization: Bearer $cortex_apikey" 'https://127.0.0.1/cortex/api/analyzer'|jq -r '.[] | select(.name=="Capa_1_0") | .id')
sed -i "s|s1em_analyzer_capa|$s1em_analyzer_capa|g" n8n/S1EM_TheHive.json
s1em_analyzer_yara=$(curl -sk -H "Authorization: Bearer $cortex_apikey" 'https://127.0.0.1/cortex/api/analyzer'|jq -r '.[] | select(.name=="Yara_2_0") | .id')
sed -i "s|s1em_analyzer_yara|$s1em_analyzer_yara|g" n8n/S1EM_TheHive.json
s1em_analyzer_fileinfo=$(curl -sk -H "Authorization: Bearer $cortex_apikey" 'https://127.0.0.1/cortex/api/analyzer'|jq -r '.[] | select(.name=="FileInfo_8_0") | .id')
sed -i "s|s1em_analyzer_fileinfo|$s1em_analyzer_fileinfo|g" n8n/S1EM_TheHive.json
s1em_analyzer_mwdb=$(curl -sk -H "Authorization: Bearer $cortex_apikey" 'https://127.0.0.1/cortex/api/analyzer'|jq -r '.[] | select(.name=="Mwdb_1_0") | .id')
sed -i "s|s1em_analyzer_mwdb|$s1em_analyzer_mwdb|g" n8n/S1EM_TheHive.json
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
docker compose up -d thehive
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
echo
echo
curl -sk -L -XPOST "https://127.0.0.1/thehive/api/v0/organisation" -H 'Content-Type: application/json' -u admin@thehive.local:secret -d "{\"description\": \"SOC team\",\"name\": \"$organization\"}" >/dev/null 2>&1
echo
echo
while [ "$(docker logs thehive | grep -i "End of deduplication of Organisation")" == "" ]; do
  echo "Waiting for TheHive organization.";
  sleep 15;
done
echo
echo
curl -sk -L -XPOST "https://127.0.0.1/thehive/api/v1/user" -H 'Content-Type: application/json' -u admin@thehive.local:secret -d "{\"login\":\"$admin_account\",\"name\":\"admin\",\"profile\":\"org-admin\",\"organisation\":\"$organization\"}" >/dev/null 2>&1
echo

while [ "$(docker logs thehive | grep -i " End of deduplication of User")" == "" ]; do
  echo "Waiting for the creation of user in TheHive .";
  sleep 15;
done
echo
echo
curl -sk -L -XPOST "https://127.0.0.1/thehive/api/v1/user/$admin_account/password/set" -H 'Content-Type: application/json' -u admin@thehive.local:secret -d "{\"password\":\"$admin_password\"}" >/dev/null 2>&1
thehive_apikey=$(curl -sk -L -XPOST "https://127.0.0.1/thehive/api/v1/user/$admin_account/key/renew" -u admin@thehive.local:secret)

while [ "$(docker logs thehive | grep -i " End of deduplication of User")" == "" ]; do
  echo "Waiting for the password change of user in TheHive .";
  sleep 15;
done
echo
echo
echo "##########################################"
echo "###### IMPORT THEHIVE DASHBOARDS## #######"
echo "##########################################"
echo
echo
curl -sk 'https://127.0.0.1/thehive/api/dashboard' -u $admin_account:$admin_password -H 'accept: application/json, text/plain, */*' -H 'content-type:  application/json' -d @thehive/Dashboards/alerts.json >/dev/null 2>&1
curl -sk 'https://127.0.0.1/thehive/api/dashboard' -u $admin_account:$admin_password -H 'accept: application/json, text/plain, */*' -H 'content-type:  application/json' -d @thehive/Dashboards/case.json >/dev/null 2>&1
curl -sk 'https://127.0.0.1/thehive/api/dashboard' -u $admin_account:$admin_password -H 'accept: application/json, text/plain, */*' -H 'content-type:  application/json' -d @thehive/Dashboards/jobs.json >/dev/null 2>&1
curl -sk 'https://127.0.0.1/thehive/api/dashboard' -u $admin_account:$admin_password -H 'accept: application/json, text/plain, */*' -H 'content-type:  application/json' -d @thehive/Dashboards/observable.json >/dev/null 2>&1
echo
echo
echo "##########################################"
echo "######### CONFIGURING API THEHIVE ########"
echo "##########################################"
echo
echo
sed -i "s|thehive_api_key|$thehive_apikey|g" .env elastalert/elastalert.yaml n8n/user.json
echo
echo
echo "##########################################"
echo "########## DEPLOY KIBANA INDEX ###########"
echo "##########################################"
echo
echo
for index in $(find kibana/index/* -type f); do docker exec kibana sh -c "curl -sk -X POST 'https://kibana:5601/kibana/api/saved_objects/_import?overwrite=true' -u 'elastic:$password' -H 'kbn-xsrf: true' -H 'Content-Type: multipart/form-data' --form file=@/usr/share/$index >/dev/null 2>&1"; done
sleep 10
for dashboard in $(find kibana/dashboard/* -type f); do docker exec kibana sh -c "curl -sk -X POST 'https://kibana:5601/kibana/api/saved_objects/_import?overwrite=true' -u 'elastic:$password' -H 'kbn-xsrf: true' -H 'Content-Type: multipart/form-data' --form file=@/usr/share/$dashboard >/dev/null 2>&1"; done
sleep 10
echo
echo
echo "##########################################"
echo "########## STARTING LOGSTASH #############"
echo "##########################################"
echo
echo
docker compose up -d logstash
echo
echo
echo "##########################################"
echo "######### STARTING VELOCIRAPTOR ##########"
echo "##########################################"
echo
echo
docker compose up -d velociraptor
echo "Waiting for the start of velociraptor."
sleep 30
docker exec -ti velociraptor bash -c "/velociraptor/velociraptor config generate > /velociraptor/server.config.yaml --merge '{\"gui\":{\"use_plain_http\":true,\"base_path\":\"/velociraptor\",\"public_url\":\"https://$s1em_hostname/velociraptor\",\"bind_address\":\"0.0.0.0\"}}'" 2>&1
docker exec -ti velociraptor bash -c "/velociraptor/velociraptor --config /velociraptor/server.config.yaml user add $admin_account $admin_password --role administrator" 2>&1
docker restart velociraptor
echo 
echo
echo "##########################################"
echo "########### STARTING ARKIME ##############"
echo "##########################################"
echo
echo
chmod u=rx ./arkime/scripts/*.sh
docker compose up -d arkime
echo
echo
echo "##########################################"
echo "######## STARTING SURICATA/ZEEK ##########"
echo "##########################################"
echo
echo
docker compose up -d suricata zeek
echo
echo
echo "##########################################"
echo "######## UPDATE SURICATA RULES ###########"
echo "##########################################"
echo
echo
while [ "$(docker exec -it suricata test -e /var/run/suricata/suricata-command.socket && echo "File exists." || echo "File does not exist")" == "File does not exist" ]; do
  echo "Waiting for Suricata to come online.";
  sleep 5;
done
docker exec -ti suricata suricata-update update-sources
docker exec -ti suricata suricata-update --no-test
echo
echo
echo "##########################################"
echo "########## UPDATE YARA RULES #############"
echo "##########################################"
echo
mkdir tmp
git clone https://github.com/malpedia/signator-rules tmp
mv tmp/rules/* rules/yara/
rm -fr tmp
cd rules/yara
bash index_gen.sh  >/dev/null 2>&1
rm index_w_mobile.yar
cd - >/dev/null 2>&1
docker restart cortex  >/dev/null 2>&1
echo
echo
echo "##########################################"
echo "####### INSTALL DETECTION RULES ##########"
echo "##########################################"
echo
echo
curl -sk -XPOST -u elastic:$password "https://127.0.0.1/kibana/s/default/api/detection_engine/index" -H "kbn-xsrf: true" >/dev/null 2>&1
if 	 [ "$detection" == ELASTIC ];
then
        curl -sk -XPUT -u elastic:$password "https://127.0.0.1/kibana/s/default/api/detection_engine/rules/prepackaged" -H "kbn-xsrf: true"
        echo "Install rules from folder"    
        for rule in $(find ./rules/elastic/ -type f ); do (curl -sk -X POST 'https://127.0.0.1/kibana/api/detection_engine/rules/_import?overwrite=true' -u "elastic:$password" -H 'kbn-xsrf: true' --form 'file=@'$rule  >/dev/null 2>&1); done
elif [ "$detection" == SIGMA ];
then
        docker image rm -f sigma:1.0
        docker container prune -f
        docker compose -f sigma.yml build
        docker compose -f sigma.yml up -d
fi
echo
echo
echo "#########################################"
echo "########## CONFIGURE FLEET ##############"
echo "#########################################"
echo

docker compose up -d fleet-server

while [ "$(curl -sk -w "%{http_code}" -o /dev/null --header 'kbn-xsrf: true' -X POST -u "elastic:$password" https://127.0.0.1/kibana/api/fleet/setup)" != "200" ]; do
  echo "Waiting for fleet setup.";
  sleep 15;
done

echo " Setting Fleet URL as https://$ADMINISTRATION_IP:8220"
curl -sk -u "elastic:$password" -XPUT "https://127.0.0.1/kibana/api/fleet/settings" \
  --header 'kbn-xsrf: true' \
  --header 'Content-Type: application/json' \
  -d '{"fleet_server_hosts":["https://${ADMINISTRATION_IP}:8220"]}' >/dev/null 2>&1

POLICYID=`curl -sk -u elastic:$password -XGET https://127.0.0.1/kibana/api/fleet/agent_policies | jq -r '.items[] | select (.name | contains("Default Fleet Server policy")).id'` >/dev/null 2>&1
echo "Fleet Server Policy ID: $POLICYID"

FLEET_ENROLLTOKEN=`curl -sk -s -u elastic:$password -XGET "https://127.0.0.1/kibana/api/fleet/enrollment-api-keys" | jq -r '.list[] | select (.policy_id |contains("'$POLICYID'")).api_key'` >/dev/null 2>&1
echo "Fleet Server Enrollment API KEY: $FLEET_ENROLLTOKEN"
sleep 5


FLEET_SERVICETOKEN=`curl -vsk -u "elastic:$password" -s -X POST https://127.0.0.1/kibana/api/fleet/service-tokens --header 'kbn-xsrf: true' | jq -r .value` >/dev/null 2>&1
echo "Generated SERVICE TOKEN for fleet server: $FLEET_SERVICETOKEN"
sed -i "s|fleettoken|$FLEET_SERVICETOKEN|g" .env docker-compose.yml
sed -i "s|fleetenroll|$FLEET_ENROLLTOKEN|g" .env docker-compose.yml

docker cp fleet-server:/usr/share/certificates/ca/ca.crt certs/ca.crt
echo "Setting Elasticsearch URL & Fingerprint & SSL CA"
FINGERPRINT=`openssl x509 -fingerprint -sha256 -noout -in certs/ca.crt | awk -F"=" {' print $2 '} | sed s/://g `
    
if [ -f ${2}/ca.temp ]; then
 sudo rm -rf certs/ca.temp
fi
 while read line
   do
     echo "    ${line}" >> /tmp/ca.temp
   done < certs/ca.crt
   truncate -s -1 /tmp/ca.temp
   CA=$(jq -R -s '.' < /tmp/ca.temp | tr -d '"' | sed 's!\\n!/\\r\\n!g')
   sudo rm -rf /tmp/ca.temp
   generate_post_data(){
        cat <<EOF
{
  "hosts":["https://${ADMINISTRATION_IP}:9200"],
  "config_yaml":"ssl:\r\n  verification_mode: none\r\n  certificate_authorities:\r\n  - >\r\n${CA}"
} 
EOF
}

curl -sk -u "elastic:$password" -XPUT "https://127.0.0.1/kibana/api/fleet/outputs/fleet-default-output" \
      --header 'kbn-xsrf: true' \
      --header 'Content-Type: application/json' \
      -d "$(generate_post_data)" >/dev/null 2>&1


echo
echo
echo "#########################################"
echo "########## STARTING OPENCTI #############"
echo "#########################################"
echo
echo
docker compose up -d opencti
echo
echo
echo "#########################################"
echo "############ STARTING N8N ###############"
echo "#########################################"
echo
echo
docker compose up -d n8n
docker exec n8n sh -c "n8n import:workflow --input=S1EM_TheHive.json"
docker exec n8n sh -c "n8n import:credentials --input=user.json"
echo
echo
echo "#########################################"
echo "###### ACTIVATION WEBHOOK THEHIVE #######"
echo "#########################################"
echo
echo
curl -XPUT -sk -u$admin_account:$admin_password -H 'Content-type: application/json' https://127.0.0.1/thehive/api/config/organisation/notification -d '{"value": [{"delegate": false,"trigger": { "name": "AnyEvent"},"notifier": { "name": "webhook", "endpoint": "n8n" }}]}'
echo
echo
echo "#########################################"
echo "###### CONFIGURATION DE REPLAY ##########"
echo "#########################################"
echo
echo
chmod 755 replay/replay.sh
instance=$(grep -oP 'INSTANCE=\K.*' .env)
sed -i "s|instance_name|$instance|g" replay/replay.sh
echo
echo
echo "#########################################"
echo "####### STARTING OTHER DOCKER ###########"
echo "#########################################"
echo
echo
docker compose up -d fleet-server elastalert cyberchef zircolite-upload file-upload velociraptor-upload syslog-ng replay file4thehive heartbeat spiderfoot codimd watchtower
echo
echo
if [ "$cluster" == SINGLE ];
then
		echo "#########################################"
		echo "######## MODIFY INDEX ELASTIC ###########"
		echo "#########################################"
		echo
		echo
		docker exec es01 sh -c "curl -sk -X PUT 'https://127.0.0.1:9200/thehive_global/_settings' -u 'elastic:$password' -H 'Content-Type: application/json' -d '{\"index\": { \"number_of_replicas\" : 0 }}'" >/dev/null 2>&1
		docker exec es01 sh -c "curl -sk -X PUT 'https://127.0.0.1:9200/.siem-signals-default/_settings' -u 'elastic:$password' -H 'Content-Type: application/json' -d '{\"index\": { \"number_of_replicas\" : 0 }}'" >/dev/null 2>&1
		while [ "$(docker logs elastalert | grep -i "Done!")" == "" ]; do
  			echo "Waiting for the creation of elastalert";
  			sleep 15;
		done
		docker exec es01 sh -c "curl -sk -X PUT 'https://127.0.0.1:9200/elastalert_status/_settings' -u 'elastic:$password' -H 'Content-Type: application/json' -d '{\"index\": { \"number_of_replicas\" : 0 }}'" >/dev/null 2>&1
		docker exec es01 sh -c "curl -sk -X PUT 'https://127.0.0.1:9200/elastalert_status_status/_settings' -u 'elastic:$password' -H 'Content-Type: application/json' -d '{\"index\": { \"number_of_replicas\" : 0 }}'" >/dev/null 2>&1
		docker exec es01 sh -c "curl -sk -X PUT 'https://127.0.0.1:9200/elastalert_status_silence/_settings' -u 'elastic:$password' -H 'Content-Type: application/json' -d '{\"index\": { \"number_of_replicas\" : 0 }}'" >/dev/null 2>&1
		docker exec es01 sh -c "curl -sk -X PUT 'https://127.0.0.1:9200/elastalert_status_error/_settings' -u 'elastic:$password' -H 'Content-Type: application/json' -d '{\"index\": { \"number_of_replicas\" : 0 }}'" >/dev/null 2>&1
		docker exec es01 sh -c "curl -sk -X PUT 'https://127.0.0.1:9200/elastalert_status_past/_settings' -u 'elastic:$password' -H 'Content-Type: application/json' -d '{\"index\": { \"number_of_replicas\" : 0 }}'" >/dev/null 2>&1
elif [ "$cluster" == MULTI ];
then
		echo "nothing to modify"
fi
echo
echo
echo "#########################################"
echo "############ DEPLOY FINISH ##############"
echo "#########################################"
echo
echo "Access url: https://$s1em_hostname"
echo "Use the user account $admin_account for access to Kibana / OpenCTI / Arkime / TheHive / Cortex / MISP"
echo "The user admin for MWDB have password $mwdb_password "
echo "The master password of elastic is in \".env\" "
