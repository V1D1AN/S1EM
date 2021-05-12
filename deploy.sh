#!/bin/bash
mv env.sample .env
docker-compose up -d elasticsearch
sleep 45
docker exec -ti elasticsearch elasticsearch-setup-passwords interactive
echo "##########################################"
echo "###### CONFIGURING ACCOUNT ELASTIC #######"
echo "##########################################"
read -s -p "Enter the password of account elastic:" password
password=$password
sed -i "s/changeme/$password/g" cortex/application.conf elastalert/elastalert.yaml filebeat/filebeat.yml metricbeat/metricbeat.yml kibana/kibana.yml auditbeat/auditbeat.yml logstash/pipeline/03_output.conf
sed -i "s/elastic_opencti/$password/g" docker-compose.yml
echo
echo
echo "##########################################"
echo "#### CONFIGURING MONITORING INTERFACE ####"
echo "##########################################"
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
docker-compose up -d
