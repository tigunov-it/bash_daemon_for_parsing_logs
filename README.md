Implement a bash daemon for parsing logs
=========

The daemon should parse a log file, which can be specified either from command line or from configuration file and search for specified string, which also should be configurable.

Setup
=========
1. cp ./terraform/terraform.tfvars.example terraform.tfvars 
2. insert to terraform.tfvars your data:
    * SERVICE - name of service
    * LOGPATH - path to logfiles directory 
    * LOGFILE - full path to logfile
    * BADSTRING - string for parse

3. terraform apply 
4. cd ./ansible
5. insert your data to run.sh
6. ./run.sh

If you already have working instances, you can not use terraform, but immediately enter the data into ansible and run it:
1. cd ./ansible
2. cp hosts_aws.yaml.example hosts_aws.yaml 
3. insert your inventory to hosts_aws.yaml
4. cd ./ansible/roles/vars
5. cp main.yml.example main.yml
6. insert your data to main.yml
7. ./run.sh


Ansible create bash script with your data.
Example bash script:
```
#!/bin/bash
# Author: Yuriy Tigunov
# Date: 2023.02.17
# Purpose: bash daemon for parsing logs

SERVICE="tasks"
LOGPATH="/var/log/apache2/"
LOGFILE="/var/log/apache2/error.log"
BADSTRING="very_bad_string"

if [ -f "$LOGFILE" ] &&  grep -q $BADSTRING $LOGFILE
then systemctl restart $SERVICE.service
tar -zcvf $LOGPATH/$(date +"%Y_%m_%d_%H_%M_%S").tar.gz $LOGFILE
echo '' > $LOGFILE
fi

#END
```

Ansible create bash daemon for parse logs every 5 minutes
Example backend@tasks.service :
```
[Unit]
Description=Parselog Daemon
Wants=backend@tasks.timer

[Service]
Type=oneshot
User=root
ExecStart=/usr/share/parselog/parselog.sh

[Install]
WantedBy=default.target
```
Example backend@tasks.timer:

```
[Unit]
Description=Parselog Daemon Timer
Requires=backend@tasks.service

[Timer]
Unit=backend@tasks.service
OnCalendar=*:5/5

[Install]
WantedBy=timers.target
```

