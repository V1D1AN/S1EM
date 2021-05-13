# S1EM

This project is a SIEM with SIRP and Threat Intel,all in one.

Solution work with CentOS 7 and kernel 5 ( For Auditbeat ), and docker.

Inside the solution:

* Elasticsearch
* Kibana
* Filebeat
* Logstash
* TheHive
* Cortex
* MISP
* OpenCTI
* Suricata
* Zeek
* FleetDm
* StoQ
* Traefik

Note: Cortex v3.1 use ELK connector and the OpenCTI v4 connector

# Prerequisites

## Physical

You must have: 
* 12 Go Ram
* 75 Go DD
* 8 cpu
* 1 network for monitoring


## Docker

Docker-compose must be installed on the system

The user must be on the group "docker" or you do that:

```
sudo groupadd docker
sudo usermod -aG docker $USER
```

Run the following command or Logout and login again and run (that doesn't work you may need to reboot your machine first)

```
newgrp docker
```

Check if docker can be run without root

```
docker ps
```

## Rsyslog (On Linux)

```
vi /etc/rsyslog.conf
```

Add the following line:

```
$FileCreateMode 0644 
```

Filebeat can read the logs in the "/var/log" with the user rights

# Installation

```
git clone https://github.com/V1D1AN/S1EM.git
cd S1EM
bash deploy.sh
```

For the Question:
```
Initiating the setup of passwords for reserved users elastic,apm_system,kibana,kibana_system,logstash_system,beats_system,remote_monitoring_user.
You will be prompted to enter passwords as the process progresses.
Please confirm that you would like to continue [y/N]
```

Choose "Yes"

Enter password for "elastic,apm_system,kibana_system,logstash_system,beats_system,remote_monitoring_user"

Finally, enter the password of "elastic" previously enter.

# Access

The Url for Dashboard Traefik:
```
https://@IP/dashboard
```
* User: admin
* Password: admin


The Url for Kibana:
```
https://@IP/kibana
```

The Url for TheHive:
```
https://@IP/thehive
```

The Url for Cortex:
```
https://@IP/cortex
```

The Url for FleetDm:
```
https://@IP:8412
```

The Url for OpenCTI:
```
https://@IP/opencti
```

The Url for MISP:
```
https://misp.cyber/misp
```

Note: You must add in your host file the name and the @IP of the solution.


# Configuration

## Configuration of MISP, TheHive, Cortex

### MISP

Go to the interface MISP
Enter the login: "admin@admin.test"
Enter the password: "admin"

Enter a new password for MISP

After go to "Automation" and get the API Key.

### TheHive

Follow the official documentation for create an organization and a API key for TheHive

https://github.com/TheHive-Project/TheHiveDocs/blob/master/TheHive4/User/Quick-start.md

get the API Key.

### Cortex

Follow the official documentation for create an organization and a API key for Cortex

https://github.com/TheHive-Project/CortexDocs/blob/master/admin/quick-start.md

get the API Key.

### Use Deploy_api_key.sh

once you have the API Key, to simplify the deployment. Use the script and enter the different API Keys.

```
cd S1EM
bash deploy_api_key.sh
```


# Detection

For the detection, you can use the detection rules of Elasticsearch from the project "https://github.com/elastic/detection-rules" or, you can use SigmaHQ.
In this example, we will use SigmaHQ:

Before, we must install SigmaHQ

```
git clone https://github.com/SigmaHQ/sigma.git
cd sigma/tools
python3 setup.py install
```

Then, you have to convert rules to integrate them in the Kibana interface

One rule:

```
./sigmac -t es-rule -c config/generic/sysmon.yml -c config/winlogbeat-modules-enabled.yml PATH_TO_THE_RULES.yml > rule.ndjson
curl -X POST "https://localhost/kibana/api/detection_engine/rules/_import?overwrite=true" -u 'elastic:changeme' -H 'kbn-xsrf: true' -H 'Content-Type: multipart/form-data' --form "file=@/tmp/rule.ndjson"
```

Several rules (Windows example):

```
for rule in $(find /root/sigma/rules/windows/* -type f -not -path "*deprecated*"); do /root/sigma/tools/sigmac -t es-rule -c /root/sigma/tools/config/generic/sysmon.yml -c /root/sigma/tools/config/winlogbeat-modules-enabled.yml --backend-config /root/sigma/backend.yml $rule >> /root/rules-windows.ndjson; done
curl -X POST "https://localhost/kibana/api/detection_engine/rules/_import?overwrite=true" -u 'elastic:changeme' -H 'kbn-xsrf: true' -H 'Content-Type: multipart/form-data' --form "file=@/root/rules-windows.ndjson"
```

In my backend file, i have one option:

```
keyword_base_fields: '*'
```

Or you transfert the file rule with Winscp ( for example ) and import the rule from the Kibana interface.

If you want to use the rule of elasticsearch, go to Kibana Interface.

```
Security >> Detections >> Manage Detection Rules >> Load Elastic prebuilt rules
```

# Architecture

The architecture of the project S1EM:

<p align="center"><img align="center" src="https://i.postimg.cc/vZP6hsw8/S1EM.png"></p>

# Todo

The complete documentation
