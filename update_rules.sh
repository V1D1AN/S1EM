#!/bin/bash

echo "##########################################"
echo "######## UPDATE SURICATA RULES ###########"
echo "##########################################"

docker exec -ti suricata suricata-update update-sources
docker exec -ti suricata suricata-update --no-test

