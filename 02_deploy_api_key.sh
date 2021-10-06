#!/bin/bash
echo "#################################################################"
echo "### SCRIPT FOR DEPLOYEMENT OF API KEY FOR MISP/THEHIVE/CORTEX ###"
echo "#################################################################"
echo ""
read -r -p "Have you got yours API KEY of MISP/THEHIVE/CORTEX/MWDB  ? (Y/N)" input

case $input in
        [yY][eE][sS]|[yY]) 
        read -r -p "Enter the API KEY of Cortex:" cortex
        cortex=$cortex
        sed -i "s|cortex_api_key|$cortex|g" thehive/application.conf
        read -r -p "Enter the API KEY of TheHive:" thehive
        thehive=$thehive
        sed -i "s|thehive_api_key|$thehive|g" elastalert/elastalert.yaml
        read -r -p "Enter the API KEY of MISP:" misp
        misp=$misp
        sed -i "s|misp_api_key|$misp|g" thehive/application.conf cortex/MISP.json filebeat/modules.d/threatintel.yml docker-compose.yml
		read -r -p "Enter the API KEY of MWDB:" mwdb
        mwdb=$mwdb
		sed -i "s|mwdb_api_key|$mwdb|g" stoq/stoq.cfg
        docker-compose restart elastalert filebeat thehive cortex stoq
        docker-compose up -d connector-misp
        ;;
        [nN][oO]|[nN])
        ;; *)
        echo "Invalid input ..."
     exit 1
     ;;
esac
