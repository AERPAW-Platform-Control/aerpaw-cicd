#!/usr/bin/env bash

# Run this from the scripts directory

DBQT='"'

SCRIPTS_DIR=$(pwd)
REPO_DIR=$(dirname ${SCRIPTS_DIR})

# generate .env file
_generate_dot_env() {
  cat > ${REPO_DIR}/.env << EOF
# AERPAW - user/project/experiment settings
AERPAW_UUID=${AERPAW_UUID:-deadbeef-dead-beef-dead-beefdeadbeef}

# jenkins - jenkins.nginx.docker:lts
UID_JENKINS=${UID_JENKINS:-1000}
GID_JENKINS=${GID_JENKINS:-1000}
JENKINS_OPTS=${JENKINS_OPTS:-${DBQT}--prefix=/jenkins${DBQT}}
JENKINS_INBOUND_AGENT_PORT=${JENKINS_INBOUND_AGENT_PORT:-50000}
JENKINS_INBOUND_CLI_PORT=${JENKINS_INBOUND_CLI_PORT:-50022}
JENKINS_ADMIN_ID=${JENKINS_ADMIN_ID:-admin}
JENKINS_ADMIN_PASSWORD=${JENKINS_ADMIN_PASSWORD:-default123!}

# nginx - nginx:latest
NGINX_INDEX=${NGINX_INDEX:-./nginx/index.html}
NGINX_CONF=${NGINX_CONF:-./nginx/default.conf}
NGINX_SSL_DIR=${NGINX_SSL_DIR:-./ssl}
NGINX_LOG_DIR=${NGINX_LOG_DIR:-./logs/nginx}
NGINX_HTTP_PORT=${NGINX_HTTP_PORT:-8080}
NGINX_HTTPS_PORT=${NGINX_HTTPS_PORT:-8443}
EOF
}

# generate nginx/default.conf
_generate_nginx_conf() {
  cat > ${REPO_DIR}/nginx/default.conf << EOF
server {
    listen 80;
    server_name ${FQDN_OR_IP:-127.0.0.1};
    return 301 https://\$host:${NGINX_HTTPS_PORT:-8443}\$request_uri;
}

server {

    listen 443 ssl;
    server_name ${FQDN_OR_IP:-127.0.0.1}:${NGINX_HTTPS_PORT:-8443};

    ssl_certificate /etc/ssl/fullchain.pem;
    ssl_certificate_key /etc/ssl/privkey.pem;

    location /jenkins/ {

        proxy_set_header        Host \$host:${NGINX_HTTPS_PORT:-8443};
        proxy_set_header        X-Real-IP \$remote_addr;
        proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header        X-Forwarded-Proto \$scheme;

        # Fix the "It appears that your reverse proxy set up is broken" error.
        proxy_pass              http://jenkins:8080/jenkins/;
        proxy_read_timeout      90;

        proxy_redirect          http://jenkins:8080/jenkins/ http://${FQDN_OR_IP:-127.0.0.1}:${NGINX_HTTPS_PORT:-8443}/jenkins/;

        # Required for new HTTP-based CLI
        proxy_http_version 1.1;
        proxy_request_buffering off;
        # workaround for https://issues.jenkins-ci.org/browse/JENKINS-45651
        add_header 'X-SSH-Endpoint' '${FQDN_OR_IP:-127.0.0.1}:${JENKINS_SSH_AGENT_PORT:-50022}' always;
    }

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
}
EOF
}

# generate nginx/index.html
_generate_index_html() {
  cat > ${REPO_DIR}/nginx/index.html << EOF
<!DOCTYPE html>
<html>
<head>
<title>AERPAW CI/CD</title>
<style>
    body {
        width: 90%;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>AERPAW CI/CD (Jenkins with Gitea)</h1>
<p>Choose from the options below: </p>
<hr>
<p>
    <b>Jenkins</b> - <a href="https://${FQDN_OR_IP:-127.0.0.1}:${NGINX_HTTPS_PORT:-8443}/jenkins/">
      https://${FQDN_OR_IP:-127.0.0.1}:${NGINX_HTTPS_PORT:-8443}/jenkins/
    </a><br/>
    <b>Gitea</b> - <a href="http://127.0.0.1:8080/gitea/">
      http://127.0.0.1:8080/gitea/
    </a><br/>
</p>
</body>
</html>
EOF
}

# generate jenkins casc.yaml file
_generate_jenkins_casc_yaml() {
  cat > ${REPO_DIR}/jenkins/casc.yaml << EOF
jenkins:
  systemMessage: "Jenkins configured automatically by Jenkins Configuration as Code plugin\n\n"
  numExecutors: 4
  scmCheckoutRetryCount: 2
  mode: NORMAL

  securityRealm:
    local:
      allowsSignup: false
      users:
        - id: ${DBQT}${JENKINS_ADMIN_ID:-admin}${DBQT}
          name: ${DBQT}${JENKINS_ADMIN_NAME:-AERPAW Admin}${DBQT}
          description: "AERPAW Admin"
          password: ${DBQT}${JENKINS_ADMIN_PASSWORD:-password123!}${DBQT}
        - id: "newuser"
          password: "password123!"

  authorizationStrategy:
    globalMatrix:
      permissions:
        - "Overall/Administer:admin"
        - "Overall/Read:authenticated"

  remotingSecurity:
    enabled: true

security:
  queueItemAuthenticator:
    authenticators:
      - global:
          strategy: triggeringUsersAuthorizationStrategy

unclassified:
  location:
    url: http://127.0.0.1:8080/
EOF
}

# generate docker-compose.yaml file
_generate_docker_compose_yaml() {
  cat > ${REPO_DIR}/docker-compose.yaml << EOF
version: '3.6'
services:

  jenkins:
    image: jenkins.nginx.docker:lts
    build:
      context: ./jenkins
      dockerfile: Dockerfile
    container_name: jenkins-${AERPAW_UUID}
    ports:
      - '${JENKINS_SLAVE_AGENT_PORT}:50000'
      - '${JENKINS_SSH_AGENT_PORT}:50022'
    volumes:
      - ${JENKINS_HOME}:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - JENKINS_ADMIN_ID=${JENKINS_ADMIN_ID}
      - JENKINS_ADMIN_PASSWORD=${JENKINS_ADMIN_PASSWORD}
      - UID_JENKINS=${UID_JENKINS}
      - GID_JENKINS=${GID_JENKINS}
      - JENKINS_OPTS=${DBQT}${JENKINS_OPTS}${DBQT}
      - CASC_JENKINS_CONFIG=${CASC_JENKINS_CONFIG}
    restart: always

  nginx:
    image: nginx:latest
    container_name: nginx-${AERPAW_UUID}
    ports:
      - ${NGINX_HTTP_PORT}:80
      - ${NGINX_HTTPS_PORT}:443
    volumes:
      - ${NGINX_INDEX}:/usr/share/nginx/html/index.html
      - ${NGINX_CONF}:/etc/nginx/conf.d/default.conf
      - ${NGINX_SSL_DIR}:/etc/ssl
      - ${NGINX_LOG_DIR}:/var/log/nginx
    restart: always
EOF
}

# main
_generate_dot_env
_generate_nginx_conf
_generate_index_html
_generate_jenkins_casc_yaml
_generate_docker_compose_yaml

cd ${SCRIPTS_DIR}

exit 0;