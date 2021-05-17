#!/bin/bash
mv env.sample .env
echo "##########################################"
echo "###### CONFIGURING ACCOUNT ELASTIC #######"
echo "##########################################"
echo  
password=$(cat .env | head -n 1 | awk -F= '{print $2}')
echo "elastic password set in .env" $password
echo 
read -p "Press enter to set this password"
echo
sed -i "s/changeme/$password/g" .env cortex/application.conf elastalert/elastalert.yaml filebeat/filebeat.yml metricbeat/metricbeat.yml kibana/kibana.yml auditbeat/auditbeat.yml logstash/pipeline/03_output.conf
sed -i "s/elastic_opencti/$password/g" docker-compose.yml
echo
echo
echo
echo "##########################################"
echo "#### CONFIGURING MONITORING INTERFACE ####"
echo "##########################################"
echo
nmcli
echo
echo
read -r -p "Enter the monitoring interface (ex:ens32):" monitoring_interface
monitoring_interface=$monitoring_interface
sed -i "s/network_monitoring/$monitoring_interface/g" docker-compose.yml
echo
echo
echo "##########################################"
echo "######## CONFIGURING KIBANA IP ###########"
echo "##########################################"
read -r -p "Enter the IP address of Kibana:" kibana_ip
kibana_ip=$kibana_ip
sed -i "s/KIBANA_IP/$kibana_ip/g" elastalert/rules/*.yml
echo
echo "##########################################"
echo "######### GENERATE CERTIFICATE ###########"
echo "##########################################"
mkdir ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ssl/server.key -out ssl/server.crt
chmod 600 ssl/server.key ssl/server.crt
echo
docker-compose pull
docker-compose up -d

