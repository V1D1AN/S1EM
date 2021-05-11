#!/bin/bash
mv env.sample .env
docker-compose up -d elasticsearch
sleep 45
docker exec -ti elasticsearch elasticsearch-setup-passwords interactive
echo "###################################"
echo "#### ENTER PASSWORD OF ELASTIC ####"
echo "###################################"
read -s -p "Enter the password of account elastic:" password
password=$password
sed -i "s/changeme/$password/g" cortex/application.conf elastalert/elastalert.yaml filebeat/filebeat.yml metricbeat/metricbeat.yml kibana/kibana.yml auditbeat/auditbeat.yml logstash/pipeline/03_output.conf
sed -i "s/elastic_opencti/$password/g" docker-compose.yml
echo
docker-compose up -d
