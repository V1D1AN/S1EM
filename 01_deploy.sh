#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
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
sed -i "s|changeme|$password|g" .env cortex/application.conf thehive/application.conf elastalert/elastalert.yaml filebeat/filebeat.yml metricbeat/metricbeat.yml heartbeat/heartbeat.yml metricbeat/modules.d/elasticsearch-xpack.yml metricbeat/modules.d/kibana-xpack.yml kibana/kibana.yml auditbeat/auditbeat.yml logstash/config/logstash.yml logstash/pipeline/beats/300_output_beats.conf logstash/pipeline/stoq/300_output_stoq.conf sigma/dockerfile arkime/scripts/capture.sh arkime/scripts/config.sh arkime/scripts/import.sh arkime/scripts/init-db.sh arkime/scripts/viewer.sh arkime/config.ini cortex/Elasticsearch_IP.json cortex/Elasticsearch_Hash.json
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
read -r -p "Enter the organization (Must be like 'Cyber'):" organization
organization=$organization
sed -i "s|organization_name|$organization|g" .env
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
read -p "Enter the RAM in Go of master node elasticsearch [2]: " master_node
master_node=${master_node:-2}
sed -i "s|RAM_MASTER|$master_node|g" docker-compose.yml
read -p "Enter the RAM in Go of data,ingest node elasticsearch [4]: " data_node
data_node=${data_node:-4}
sed -i "s|RAM_DATA|$data_node|g" docker-compose.yml
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
echo "$detection"
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

echo "Load external Feed List"
curl -sk -X POST --header "Authorization: $misp_apikey" https://127.0.0.1/misp/feeds/loadDefaultFeeds >/dev/null 2>&1
sleep 30
echo "Enable Feeds "
curl -sk -X GET --header "Authorization: $misp_apikey" https://127.0.0.1/misp/feeds/enable/1 >/dev/null 2>&1
curl -sk -X GET --header "Authorization: $misp_apikey" https://127.0.0.1/misp/feeds/enable/2 >/dev/null 2>&1
echo "Starting Feed synchronisation in background"
curl -sk -X GET --header "Authorization: $misp_apikey" https://127.0.0.1/misp/feeds/fetchFromAllFeeds >/dev/null 2>&1
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
docker exec -ti cortex keytool -delete -alias ca -keystore /usr/local/openjdk-8/jre/lib/security/cacerts --storepass changeit -noprompt >/dev/null
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
while [ "$(docker logs cortex | grep -i 'End of migration')" == "" ]; do
  echo "Waiting for Cortex & elasticsearch init.";
  sleep 15;
done																		
curl -sk -L -XPOST "https://127.0.0.1/cortex/api/user" -H 'Content-Type: application/json' -d "{\"login\" : \"admin@cortex.local\",\"name\" : \"admin@cortex.local\",\"roles\" : [\"superadmin\"],\"preferences\" : \"{}\",\"password\" : \"secret\", \"key\": \"$cortex_api\"}"
curl -sk -XPOST -H "Authorization: Bearer $cortex_api" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization" -d "{  \"name\": \"$organization\",\"description\": \"SOC team\",\"status\": \"Active\"}"
curl -sk -XPOST -H "Authorization: Bearer $cortex_api" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/user" -d "{\"name\": \"$admin_account\",\"roles\": [\"read\",\"analyze\",\"orgadmin\"],\"organization\": \"$organization\",\"login\": \"$admin_account\"}"
curl -sk -XPOST -H "Authorization: Bearer $cortex_api" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/user/$admin_account/password/set" -d "{ \"password\": \"$admin_password\" }"
cortex_apikey=$(curl -sk -XPOST -H "Authorization: Bearer $cortex_api" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/user/$admin_account/key/renew")
curl -sk -XPOST -H "Authorization: Bearer $cortex_apikey" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/MISP_2_1" -d "{\"name\": \"MISP_2_1\",\"configuration\":{\"auto_extract_artifacts\":false,\"check_tlp\":true,\"max_tlp\":2,\"check_pap\":true,\"max_pap\":2},\"jobCache\": 10}"
curl -sk -XPOST -H "Authorization: Bearer $cortex_apikey" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/OpenCTI_SearchObservables_2_0" -d "{\"name\": \"OpenCTI_SearchObservables_2_0\",\"configuration\":{\"auto_extract_artifacts\":false,\"check_tlp\":true,\"max_tlp\":2,\"check_pap\":true,\"max_pap\":2},\"jobCache\": 10}"
curl -sk -XPOST -H "Authorization: Bearer $cortex_apikey" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/OTXQuery_2_0" -d "{\"name\": \"OTXQuery\",\"configuration\":{\"auto_extract_artifacts\":false,\"check_tlp\":true,\"max_tlp\":2,\"check_pap\":true,\"max_pap\":2},\"jobCache\": 10}"
curl -sk -XPOST -H "Authorization: Bearer $cortex_apikey" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/Elasticsearch_IP_Analysis_1_0" -d "{\"name\": \"Elasticsearch_IP_Analysis_1_0\",\"configuration\":{\"auto_extract_artifacts\":false,\"check_tlp\":true,\"max_tlp\":2,\"check_pap\":true,\"max_pap\":2},\"jobCache\": 10}"
curl -sk -XPOST -H "Authorization: Bearer $cortex_apikey" -H 'Content-Type: application/json' -L "https://127.0.0.1/cortex/api/organization/analyzer/Elasticsearch_Hash_Analysis_1_0" -d "{\"name\": \"Elasticsearch_Hash_Analysis_1_0\",\"configuration\":{\"auto_extract_artifacts\":false,\"check_tlp\":true,\"max_tlp\":2,\"check_pap\":true,\"max_pap\":2},\"jobCache\": 10}"
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
echo
echo
curl -sk -L -XPOST "https://127.0.0.1/thehive/api/v0/organisation" -H 'Content-Type: application/json' -u admin@thehive.local:secret -d "{\"description\": \"SOC team\",\"name\": \"$organization\"}"
echo
echo
while [ "$(docker logs thehive | grep -i "End of deduplication of Organisation")" == "" ]; do
  echo "Waiting for TheHive organization.";
  sleep 15;
done
echo
echo
curl -sk -L -XPOST "https://127.0.0.1/thehive/api/v1/user" -H 'Content-Type: application/json' -u admin@thehive.local:secret -d "{\"login\":\"$admin_account\",\"name\":\"admin\",\"profile\":\"org-admin\",\"organisation\":\"$organization\"}"
echo

while [ "$(docker logs thehive | grep -i " End of deduplication of User")" == "" ]; do
  echo "Waiting for the creation of user in TheHive .";
  sleep 15;
done
echo
echo
curl -sk -L -XPOST "https://127.0.0.1/thehive/api/v1/user/$admin_account/password/set" -H 'Content-Type: application/json' -u admin@thehive.local:secret -d "{\"password\":\"$admin_password\"}"
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
curl -sk 'https://127.0.0.1/thehive/api/dashboard' -u $admin_account:$admin_password -H 'accept: application/json, text/plain, */*' -H 'content-type:  application/json' --data-raw '{"title":"Alert statistics","description":"Alert statistics","status":"Shared","definition":"{\"period\":\"last7Days\",\"items\":[{\"type\":\"container\",\"items\":[{\"type\":\"donut\",\"options\":{\"title\":\"Alerts by status\",\"entity\":\"alert\",\"field\":\"status\",\"query\":{},\"names\":{\"New\":\"New\",\"Updated\":\"Updated\",\"Ignored\":\"Ignored\",\"Imported\":\"Imported\"}},\"id\":\"cd063f98-21cc-405c-18a9-af669acae104\"},{\"type\":\"donut\",\"options\":{\"title\":\"Waiting alerts by type\",\"entity\":\"alert\",\"field\":\"type\",\"filters\":[{\"field\":\"status\",\"type\":\"enumeration\",\"value\":{\"list\":[{\"text\":\"New\",\"label\":\"New\"},{\"text\":\"Updated\",\"label\":\"Updated\"}]}}],\"query\":{\"_or\":[{\"_field\":\"status\",\"_value\":\"New\"},{\"_field\":\"status\",\"_value\":\"Updated\"}]},\"names\":{}},\"id\":\"8ca4226f-374e-5315-71b8-5d6a4141d886\"},{\"type\":\"donut\",\"options\":{\"title\":\"Waiting alerts by source\",\"entity\":\"alert\",\"field\":\"source\",\"filters\":[{\"field\":\"status\",\"type\":\"enumeration\",\"value\":{\"list\":[{\"text\":\"New\",\"label\":\"New\"},{\"text\":\"Updated\",\"label\":\"Updated\"}]}}],\"query\":{\"_or\":[{\"_field\":\"status\",\"_value\":\"New\"},{\"_field\":\"status\",\"_value\":\"Updated\"}]},\"names\":{}},\"id\":\"73a986bb-7f53-fc62-6cc8-1e099fadc4b4\"}]},{\"type\":\"container\",\"items\":[{\"type\":\"bar\",\"options\":{\"entity\":\"alert\",\"dateField\":\"createdAt\",\"interval\":\"1d\",\"field\":\"type\",\"stacked\":true,\"title\":\"Alert type history\",\"query\":{},\"names\":{}},\"id\":\"62633389-0aa0-827b-ef48-e5bedf7d5e7d\"},{\"type\":\"donut\",\"options\":{\"title\":\"Alerts by tags\",\"entity\":\"alert\",\"field\":\"tags\",\"query\":{},\"names\":{}},\"id\":\"61fadb50-aed0-d554-435b-e88d33da6588\"},{\"type\":\"bar\",\"options\":{\"title\":\"Alert source history\",\"entity\":\"alert\",\"dateField\":\"createdAt\",\"interval\":\"1d\",\"field\":\"source\",\"stacked\":true,\"query\":{},\"names\":{}},\"id\":\"a513f977-e743-9862-0755-9831e9bf080a\"}]},{\"type\":\"container\",\"items\":[{\"type\":\"donut\",\"options\":{\"title\":\"Alert by severity\",\"entity\":\"alert\",\"field\":\"severity\",\"query\":{},\"names\":{\"1\":\"low\",\"2\":\"medium\",\"3\":\"high\",\"4\":\"critical\"}},\"id\":\"6704b066-ae8d-2aeb-b9c1-528207115b14\"}]}],\"customPeriod\":{\"fromDate\":\"2020-06-16T22:00:00.000Z\",\"toDate\":\"2020-06-17T22:00:00.000Z\"}}"}' >/dev/null 2>&1
curl -sk 'https://127.0.0.1/thehive/api/dashboard' -u $admin_account:$admin_password -H 'accept: application/json, text/plain, */*' -H 'content-type:  application/json' --data-raw '{"title":"Case statistics","description":"case","status":"Shared","definition":"{\"period\":\"last3Months\",\"items\":[{\"type\":\"container\",\"items\":[{\"type\":\"donut\",\"options\":{\"title\":\"Owner of open cases\",\"entity\":\"case\",\"field\":\"owner\",\"filters\":[{\"field\":\"status\",\"type\":\"enumeration\",\"value\":{\"list\":[{\"text\":\"Open\",\"label\":\"Open\"}]}}],\"query\":{\"_field\":\"status\",\"_value\":\"Open\"},\"names\":{}},\"id\":\"4cb4f7d3-eb21-dd61-2a6f-85cf096a2a6e\"},{\"type\":\"donut\",\"options\":{\"title\":\"Cases by status\",\"entity\":\"case\",\"field\":\"status\",\"filters\":[],\"names\":{\"NoImpact\":\"NoImpact\",\"WithImpact\":\"WithImpact\",\"NotApplicable\":\"NotApplicable\",\"Open\":\"Open\",\"Resolved\":\"Resolved\",\"Deleted\":\"Deleted\"},\"query\":{}},\"id\":\"84b81a65-4b3c-2b26-421e-fd7453d92f3e\"}]},{\"type\":\"container\",\"items\":[{\"type\":\"donut\",\"options\":{\"title\":\"Revolved cases by resolution\",\"entity\":\"case\",\"field\":\"resolutionStatus\",\"filters\":[{\"field\":\"status\",\"type\":\"enumeration\",\"value\":{\"list\":[{\"text\":\"Resolved\",\"label\":\"Resolved\"}]}}],\"query\":{\"_field\":\"status\",\"_value\":\"Resolved\"},\"names\":{\"FalsePositive\":\"FalsePositive\",\"Duplicated\":\"Duplicated\",\"Indeterminate\":\"Indeterminate\",\"TruePositive\":\"TruePositive\",\"Other\":\"Other\"}},\"id\":\"ede6e87a-2e39-5556-b421-1c4cd73a74b1\"},{\"type\":\"donut\",\"options\":{\"title\":\"Case tags\",\"entity\":\"case\",\"field\":\"tags\",\"query\":{},\"names\":{}},\"id\":\"a9e47a5d-3c84-4949-b941-a60ea3c41e81\"}]},{\"type\":\"container\",\"items\":[{\"type\":\"bar\",\"options\":{\"entity\":\"case\",\"dateField\":\"createdAt\",\"interval\":\"1d\",\"field\":\"owner\",\"stacked\":true,\"query\":{},\"names\":{},\"title\":\"Case owner history\"},\"id\":\"b5bb88c6-0a76-ca85-c4b6-5096199ddf80\"},{\"type\":\"bar\",\"options\":{\"entity\":\"case\",\"dateField\":\"createdAt\",\"interval\":\"1d\",\"field\":\"severity\",\"stacked\":true,\"query\":{},\"names\":{\"1\":\"low\",\"2\":\"medium\",\"3\":\"high\",\"4\":\"critical\"},\"title\":\"Case severity history\"},\"id\":\"9bdac0ad-441b-2be3-9e6e-342968be5315\"},{\"type\":\"bar\",\"options\":{\"entity\":\"case\",\"dateField\":\"createdAt\",\"interval\":\"1d\",\"field\":\"tlp\",\"stacked\":true,\"title\":\"Case TLP history\",\"query\":{},\"names\":{\"0\":\"white\",\"1\":\"green\",\"2\":\"amber\",\"3\":\"red\"}},\"id\":\"72157fd6-efb4-cf0c-a281-7eacc3c32a4f\"}]},{\"type\":\"container\",\"items\":[{\"type\":\"line\",\"options\":{\"title\":\"Case over time\",\"entity\":\"case\",\"field\":\"createdAt\",\"interval\":\"1d\",\"series\":[{\"agg\":\"avg\",\"field\":\"computed.handlingDurationInHours\",\"type\":\"line\",\"filters\":[{\"field\":\"status\",\"type\":\"enumeration\",\"value\":{\"list\":[{\"text\":\"Resolved\",\"label\":\"Resolved\"}]}}],\"query\":{\"_field\":\"status\",\"_value\":\"Resolved\"}},{\"agg\":\"count\",\"field\":null,\"type\":\"bar\"}],\"query\":{}},\"id\":\"377784a7-49c2-50aa-2eba-acc862a0b841\"}]},{\"type\":\"container\",\"items\":[{\"type\":\"donut\",\"options\":{\"title\":\"Severity of open cases\",\"entity\":\"case\",\"field\":\"severity\",\"filters\":[{\"field\":\"status\",\"type\":\"enumeration\",\"value\":{\"list\":[{\"text\":\"Open\",\"label\":\"Open\"}]}}],\"query\":{\"_field\":\"status\",\"_value\":\"Open\"},\"names\":{\"1\":\"low\",\"2\":\"medium\",\"3\":\"high\",\"4\":\"critical\"}},\"id\":\"d943c6f4-61d8-b4dd-7a3a-56067829727a\"},{\"type\":\"donut\",\"options\":{\"title\":\"TLP of open cases\",\"entity\":\"case\",\"field\":\"tlp\",\"filters\":[{\"field\":\"status\",\"type\":\"enumeration\",\"value\":{\"list\":[{\"text\":\"Open\",\"label\":\"Open\"}]}}],\"query\":{\"_field\":\"status\",\"_value\":\"Open\"},\"names\":{\"0\":\"white\",\"1\":\"green\",\"2\":\"amber\",\"3\":\"red\"}},\"id\":\"4c7bb013-c87f-7f17-0892-e20af2a0dcac\"}]},{\"type\":\"container\",\"items\":[{\"type\":\"donut\",\"options\":{\"title\":\"severity of close cases\",\"entity\":\"case\",\"field\":\"severity\",\"filters\":[{\"field\":\"status\",\"type\":\"enumeration\",\"value\":{\"list\":[{\"text\":\"Resolved\",\"label\":\"Resolved\"}]}}],\"query\":{\"_field\":\"status\",\"_value\":\"Resolved\"},\"names\":{\"1\":\"low\",\"2\":\"medium\",\"3\":\"high\",\"4\":\"critical\"}},\"id\":\"e77cdda7-de93-a5ff-e0f3-280c0a1b4e75\"},{\"type\":\"donut\",\"options\":{\"title\":\"TLP of close cases\",\"entity\":\"case\",\"field\":\"tlp\",\"filters\":[{\"field\":\"status\",\"type\":\"enumeration\",\"value\":{\"list\":[{\"text\":\"Resolved\",\"label\":\"Resolved\"}]}}],\"query\":{\"_field\":\"status\",\"_value\":\"Resolved\"},\"names\":{\"0\":\"white\",\"1\":\"green\",\"2\":\"amber\",\"3\":\"red\"}},\"id\":\"d8c16304-36f9-faad-e1bd-7ac919bb1c77\"}]}],\"customPeriod\":{\"fromDate\":null,\"toDate\":null}}"}' >/dev/null 2>&1
curl -sk 'https://127.0.0.1/thehive/api/dashboard' -u $admin_account:$admin_password -H 'accept: application/json, text/plain, */*' -H 'content-type:  application/json' --data-raw '{"title":"Job statistics","description":"Job statistics","status":"Shared","definition":"{\"period\":\"last3Months\",\"items\":[{\"type\":\"container\",\"items\":[{\"type\":\"donut\",\"options\":{\"title\":\"Top analyzers\",\"entity\":\"case_artifact_job\",\"field\":\"analyzerId\",\"query\":{},\"names\":{}},\"id\":\"1eaa4dfa-5b14-50b6-e442-8729363f6f66\"},{\"type\":\"donut\",\"options\":{\"title\":\"Cortex instance use\",\"entity\":\"case_artifact_job\",\"field\":\"cortexId\",\"query\":{},\"names\":{}},\"id\":\"c501c2d3-9779-1d2a-6d85-bb2bd68260f5\"}]},{\"type\":\"container\",\"items\":[{\"type\":\"bar\",\"options\":{\"title\":\"Job owners\",\"entity\":\"case_artifact_job\",\"dateField\":\"createdAt\",\"interval\":\"1d\",\"field\":\"createdBy\",\"stacked\":true,\"query\":{},\"names\":{}},\"id\":\"bc10b554-aa4c-6fce-c4bb-b906b9b0e398\"},{\"type\":\"bar\",\"options\":{\"title\":\"Analyzer history\",\"entity\":\"case_artifact_job\",\"dateField\":\"createdAt\",\"interval\":\"1d\",\"field\":\"analyzerId\",\"stacked\":true,\"query\":{},\"names\":{}},\"id\":\"cd6d0dc1-a77d-be9d-e7dd-c6a8c79b0898\"}]}],\"customPeriod\":{\"fromDate\":null,\"toDate\":null}}"}' >/dev/null 2>&1
curl -sk 'https://127.0.0.1/thehive/api/dashboard' -u $admin_account:$admin_password -H 'accept: application/json, text/plain, */*' -H 'content-type:  application/json' --data-raw '{"title":"Observable statistics","description":"Observable statistics","status":"Shared","definition":"{\"period\":\"last30Days\",\"items\":[{\"type\":\"container\",\"items\":[{\"type\":\"donut\",\"options\":{\"title\":\"Observables by type\",\"entity\":\"case_artifact\",\"field\":\"dataType\",\"query\":{\"_not\":{\"_field\":\"status\",\"_value\":\"Deleted\"}},\"names\":{\"fqdn\":\"fqdn\",\"url\":\"url\",\"regexp\":\"regexp\",\"mail\":\"mail\",\"hash\":\"hash\",\"registry\":\"registry\",\"uri_path\":\"uri_path\",\"truc\":\"truc\",\"ip\":\"ip\",\"user-agent\":\"user-agent\",\"autonomous-system\":\"autonomous-system\",\"file\":\"file\",\"mail_subject\":\"mail_subject\",\"filename\":\"filename\",\"other\":\"other\",\"domain\":\"domain\",\"md5\":\"md5\",\"sha256\":\"sha256\",\"sha1\":\"sha1\"},\"filters\":[{\"field\":\"status\",\"type\":\"enumeration\",\"value\":{\"operator\":\"none\",\"list\":[{\"text\":\"Deleted\",\"label\":\"Deleted\"}]}}]},\"id\":\"6ee86a99-3f40-1960-fd4d-398a1da5b76e\"},{\"type\":\"donut\",\"options\":{\"title\":\"Observables by data\",\"entity\":\"case_artifact\",\"field\":\"data\",\"query\":{},\"names\":{}},\"id\":\"72471d6c-a42d-4261-b205-6614428785c6\"},{\"type\":\"donut\",\"options\":{\"title\":\"Observables by attachment content type\",\"entity\":\"case_artifact\",\"field\":\"attachment.contentType\",\"query\":{\"_and\":[{\"_field\":\"dataType\",\"_value\":\"file\"},{\"_not\":{\"_field\":\"status\",\"_value\":\"Deleted\"}}]},\"names\":{},\"filters\":[{\"field\":\"dataType\",\"type\":\"enumeration\",\"value\":{\"list\":[{\"text\":\"file\",\"label\":\"file\"}]}},{\"field\":\"status\",\"type\":\"enumeration\",\"value\":{\"operator\":\"none\",\"list\":[{\"text\":\"Deleted\",\"label\":\"Deleted\"}]}}]},\"id\":\"b6110238-3074-4e85-674f-4bc56829e68a\"}]},{\"type\":\"container\",\"items\":[{\"type\":\"donut\",\"options\":{\"title\":\"Observable tags\",\"entity\":\"case_artifact\",\"field\":\"tags\",\"query\":{\"_not\":{\"_field\":\"status\",\"_value\":\"Deleted\"}},\"names\":{},\"filters\":[{\"field\":\"status\",\"type\":\"enumeration\",\"value\":{\"operator\":\"none\",\"list\":[{\"text\":\"Deleted\",\"label\":\"Deleted\"}]}}]},\"id\":\"70bbc0a5-1692-4e46-ebac-8769952ad9c0\"},{\"type\":\"donut\",\"options\":{\"title\":\"Observables by TLP\",\"entity\":\"case_artifact\",\"field\":\"tlp\",\"query\":{\"_not\":{\"_field\":\"status\",\"_value\":\"Deleted\"}},\"names\":{\"0\":\"white\",\"1\":\"green\",\"2\":\"amber\",\"3\":\"red\"},\"colors\":{\"0\":\"#bdf0ea\",\"1\":\"#48e80f\",\"2\":\"#e0a91a\",\"3\":\"#f02626\"},\"filters\":[{\"field\":\"status\",\"type\":\"enumeration\",\"value\":{\"operator\":\"none\",\"list\":[{\"text\":\"Deleted\",\"label\":\"Deleted\"}]}}]},\"id\":\"633fbe97-805e-6123-3330-29f5c8f45f13\"}]},{\"type\":\"container\",\"items\":[{\"type\":\"donut\",\"options\":{\"title\":\"Observables by IOC flag\",\"entity\":\"case_artifact\",\"field\":\"ioc\",\"query\":{\"_not\":{\"_field\":\"status\",\"_value\":\"Deleted\"}},\"names\":{},\"filters\":[{\"field\":\"status\",\"type\":\"enumeration\",\"value\":{\"operator\":\"none\",\"list\":[{\"text\":\"Deleted\",\"label\":\"Deleted\"}]}}]},\"id\":\"771a3bdf-e437-ac3a-384d-23be91a25b07\"},{\"type\":\"line\",\"options\":{\"title\":\"Observables over time\",\"entity\":\"case_artifact\",\"field\":\"createdAt\",\"interval\":\"1d\",\"series\":[{\"agg\":\"count\",\"field\":null,\"type\":\"area-spline\",\"filters\":[{\"field\":\"ioc\",\"type\":\"boolean\",\"value\":true}],\"label\":\"IOC\",\"query\":{\"_field\":\"ioc\",\"_value\":true}},{\"agg\":\"count\",\"field\":null,\"type\":\"area-spline\",\"label\":\"non-IOC\",\"filters\":[{\"field\":\"ioc\",\"type\":\"boolean\",\"value\":false}],\"query\":{\"_field\":\"ioc\",\"_value\":false}}],\"stacked\":true,\"query\":{\"_not\":{\"_field\":\"status\",\"_value\":\"Deleted\"}},\"filters\":[{\"field\":\"status\",\"type\":\"enumeration\",\"value\":{\"operator\":\"none\",\"list\":[{\"text\":\"Deleted\",\"label\":\"Deleted\"}]}}]},\"id\":\"e5ed24a6-51ed-ecc4-9db0-ce837fd84214\"}]}],\"customPeriod\":{\"fromDate\":\"2020-06-02T22:00:00.000Z\",\"toDate\":\"2020-06-03T22:00:00.000Z\"}}"}' >/dev/null 2>&1
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
sed -i "s|mwdb_api_key|$mwdb_apikey|g" stoq/stoq.cfg .env
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
echo "####### INSTALL DETECTION RULES ##########"
echo "##########################################"
echo
echo
curl -sk -XPOST -u elastic:$password "https://127.0.0.1/kibana/s/default/api/detection_engine/index" -H "kbn-xsrf: true"
echo
echo
if 	 [ "$detection" == ELASTIC ];
then
        curl -sk -XPUT -u elastic:$password "https://127.0.0.1/kibana/s/default/api/detection_engine/rules/prepackaged" -H "kbn-xsrf: true"
        echo "Install rules from folder"    
        for rule in $(find ./rules/elastic/ -type f ); do (curl -sk -X POST 'https://127.0.0.1/kibana/api/detection_engine/rules/_import?overwrite=true' -u "elastic:$password" -H 'kbn-xsrf: true' --form 'file=@'$rule  >/dev/null 2>&1); done
elif [ "$detection" == SIGMA ];
then
        docker image rm -f sigma:1.0
        docker container prune -f
        docker-compose -f sigma.yml build
        docker-compose -f sigma.yml up -d
fi
echo
echo
echo "#########################################"
echo "########## CONFIGURE FLEET ##############"
echo "#########################################"
echo

docker-compose up -d fleet-server

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
docker-compose up -d fleet-server elastalert cyberchef file-upload syslog-ng tcpreplay clamav heartbeat spiderfoot codimd watchtower
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
