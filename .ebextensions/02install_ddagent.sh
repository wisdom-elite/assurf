#!/bin/bash

EB_CONFIG_APP_CURRENT=$(/opt/elasticbeanstalk/bin/get-config container -k app_deploy_dir)
DATADOG_STATUS=$(/opt/elasticbeanstalk/containerfiles/support/generate_env | grep ^DATADOG_STATUS | cut -d "=" -f2)
DOMAIN=$(/opt/elasticbeanstalk/containerfiles/support/generate_env | grep ^DOMAIN | cut -d "=" -f2)
REDIS_HOST=$(/opt/elasticbeanstalk/containerfiles/support/generate_env | grep ^REDIS_HOST | cut -d "=" -f2)
REDIS_PORT=$(/opt/elasticbeanstalk/containerfiles/support/generate_env | grep ^REDIS_PORT | cut -d "=" -f2)
DATADOG_RUNUPDATE=$(/opt/elasticbeanstalk/containerfiles/support/generate_env | grep ^DATADOG_RUNUPDATE | cut -d "=" -f2)
INSTANCE_TAG=$(/opt/elasticbeanstalk/containerfiles/support/generate_env | grep ^INSTANCE | cut -d "=" -f2)

if [ "x$DATADOG_STATUS" != "x" ]; then
    if [ "x$DATADOG_RUNUPDATE" != "x" ]; then
	if [ -f "/etc/init.d/datadog-agent" ]; then
	    yum remove -y datadog-agent
	fi

	cat > /etc/yum.repos.d/datadog.repo <<EOF
[datadog]
name = Datadog, Inc.
baseurl = https://yum.datadoghq.com/rpm/x86_64/
enabled=1
gpgcheck=1
gpgkey=https://yum.datadoghq.com/DATADOG_RPM_KEY.public
EOF

	yum makecache
	yum install -y datadog-agent

	sh -c "sed 's/api_key:.*/api_key: f13688e8ef28ec56de1ef432a74733b4/' /etc/dd-agent/datadog.conf.example > /etc/dd-agent/datadog.conf"
	sed -i "/#hostname:/chostname: ${INSTANCE_TAG}" /etc/dd-agent/datadog.conf
    fi

    if [ -f "/etc/init.d/datadog-agent" ]; then
    	cp -rf $EB_CONFIG_APP_CURRENT/devops/datadog-agent/agent/*.py /opt/datadog-agent/agent/checks.d/
    	cp -rf $EB_CONFIG_APP_CURRENT/devops/datadog-agent/conf/*.yaml /etc/dd-agent/conf.d/

    	if [[ "x${DOMAIN-}" != "x" ]]; then
    	    sed -i "/\  \- name :/c\  \- name : ${DOMAIN}" /etc/dd-agent/conf.d/gzip_check.yaml
    	    sed -i "/\    url:/c\    url: ${DOMAIN}" /etc/dd-agent/conf.d/gzip_check.yaml
	    sed -i "/\  \- name :/c\  \- name : ${DOMAIN}" /etc/dd-agent/conf.d/expire_headers_check.yaml
    	    sed -i "/\    url:/c\    url: ${DOMAIN}" /etc/dd-agent/conf.d/expire_headers_check.yaml
	    sed -i "/\  \- name :/c\  \- name : ${DOMAIN}" /etc/dd-agent/conf.d/http_5xx_check.yaml
            sed -i "/\    url:/c\    url: ${DOMAIN}" /etc/dd-agent/conf.d/http_5xx_check.yaml
    	fi
    	if [ "x${REDIS_HOST-}" != "x" ] &&  [ "x${REDIS_PORT-}" != "x" ]; then
	    sed -i "/\  \- host: localhost/c\  \- host : ${REDIS_HOST}" /etc/dd-agent/conf.d/redisdb_cmd_check.yaml
	    sed -i "/\    port: 6379/c\    port: ${REDIS_PORT}" /etc/dd-agent/conf.d/redisdb_cmd_check.yaml
    	fi

    	/etc/init.d/datadog-agent restart
    fi
fi
