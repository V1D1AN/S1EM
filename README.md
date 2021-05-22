
![20210518_v1d1an_bg1--white](https://user-images.githubusercontent.com/18678787/119020235-49428680-b99e-11eb-8621-935a62b966e1.png)



This project is a SIEM with SIRP and Threat Intel,all in one.

Solution work with CentOS 7 and kernel 5 ( For Auditbeat ), and docker.

Inside the solution:

* Elasticsearch
* Kibana
* Filebeat
* Logstash
* Metricbeat
* Auditbeat
* Elastalert
* TheHive
* Cortex
* MISP
* OpenCTI
* Suricata 5
* Zeek 3
* FleetDm
* StoQ
* Heimdall
* Traefik

Note: Cortex v3.1 use ELK connector and the OpenCTI v4 connector

# Prerequisites

## Physical

For testing:

You must have: 
* 12 Go Ram
* 75 Go DD
* 8 cpu
* 1 network for monitoring

For production:

You must have: 
* 32 Go Ram
* More than 75 Go DD
* 8 cpu
* 1 network for monitoring

# Installation

```
git clone https://github.com/V1D1AN/S1EM.git
cd S1EM
```

Edit the file "env.sample" and change the password for "elastic". <br />
Change the account and the password of "OpenCTI".

After, run the command:
```
bash deploy.sh
```

# Upgrade

Use the upgrade script for upgrading your S1EM infrastructure

```
bash upgrade.sh
```

if you see Merge conflict messages, resolve the conflicts with your favorite text editor

# Access

The Url of S1EM:
```
https://s1em.cyber.local
```
![Capture](https://user-images.githubusercontent.com/18678787/119028096-5e6fe300-b9a7-11eb-912b-4443cfd91f56.PNG)


Note: You must add in your host file the name and the @IP of the solution.

Accounts:

Application | user | password
------------| ---- | --------
Traefik | admin | admin
Kibana | elastic | your password
TheHive | admin@thehive.local | secret
Cortex | your username | your password
FleetDm | your username | your password
Misp | admin@admin.test | admin
OpenCTI | User in env.sample | your password

# Configuration

## Configuration of MISP, TheHive, Cortex

### MISP

Go to the interface MISP <br />
Enter the login: "admin@admin.test" <br />
Enter the password: "admin" <br />

Enter a new password for MISP

After go to "Automation" and get the API Key.

### TheHive

Follow the official documentation for create an organization and a API key for TheHive: <br />
https://github.com/TheHive-Project/TheHiveDocs/blob/master/TheHive4/User/Quick-start.md <br />
get the API Key.

### Cortex

Follow the official documentation for create an organization and a API key for Cortex: <br />
https://github.com/TheHive-Project/CortexDocs/blob/master/admin/quick-start.md <br />
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
./sigmac -t es-rule -c config/generic/sysmon.yml -c config/winlogbeat-modules-enabled.yml -I --backend-config backend.yml -r ../rules/windows -o /tmp/rules-windows.ndjson
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

![S1EM](https://user-images.githubusercontent.com/18678787/119194912-14106400-ba84-11eb-94bf-cde43da565b4.png)


# Troubleshooting

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

# Todo

- [x] Integrate heimdall
- [ ] The complete documentation
- [x] Add Cyberchef
- [ ] Upgrade to elastalert2
- [ ] Upgrade to suricata 6
- [ ] Upgrade to zeek 4
- [ ] Upload SigmaHQ rules automatically into kibana
- [x] Update Suricata rules automatically
- [ ] Update Yara rules automatically
- [ ] Elasticsearch multi-nodes with ssl
- [ ] Change Stoq to File-monitor ( Clamav,CAPA,Yara )
- [ ] Extract file with Zeek
- [ ] Integrate Arkime
- [ ] SSO
- [ ] Integrate Att@ck Navigator

# Special thanks
En français cette fois. <br />
Merci à mes amis et collègues qui m´ont inspiré toutes ces années, qui m´ont aidé, et corrigé des bugs.
Je pense à Kidrek, mlp1515, Wagga40, Xophidia, StevenDias33, Frak113, et tous ceux qui n´ont pas forcement de compte github. <br />
Merci à vous :)

Liens github: <br />
https://github.com/kidrek <br />
https://github.com/mlp1515 <br />
https://github.com/frack113 <br />
https://github.com/StevenDias33 <br />
https://github.com/wagga40 <br />
https://github.com/xophidia <br />
