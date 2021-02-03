#!/usr/bin/env bash

# set configuration variables
HOST_HOME=/var/jenkins/data/${AERPAW_UUID}
HOST_CICD_REPO=/var/jenkins/data/${AERPAW_UUID}/aerpaw-cicd
HOST_JENKINS_HOME=/var/jenkins/data/${AERPAW_UUID}/jenkins_home

# generate the cicd-varialbes.sh file
_generate_cicd_variables() {
  cat > ${HOST_CICD_REPO}/scripts/cicd-variables.sh << EOF
#!/usr/bin/env bash

# USAGE: $ source cicd-variables.sh

# AERPAW
export AERPAW_UUID=${AERPAW_UUID}
export FQDN_OR_IP=${FQDN_OR_IP}

# Jenkins
export JENKINS_ADMIN_ID="${JENKINS_ADMIN_ID}"
export JENKINS_ADMIN_NAME="${JENKINS_ADMIN_NAME}"
export JENKINS_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD}"
export UID_JENKINS=1000
export GID_JENKINS=1000
export JENKINS_HOME=/var/jenkins/data/${AERPAW_UUID}/jenkins_home
export JENKINS_OPTS="--prefix=/jenkins"
export JENKINS_SLAVE_AGENT_PORT=${JENKINS_SLAVE_AGENT_PORT}
export JENKINS_SSH_AGENT_PORT=${JENKINS_SSH_AGENT_PORT}
export CASC_JENKINS_CONFIG=/var/jenkins_home/casc.yaml

# Nginx
export NGINX_HTTP_PORT=${NGINX_HTTP_PORT}
export NGINX_HTTPS_PORT=${NGINX_HTTPS_PORT}
export NGINX_INDEX=./nginx/index.html
export NGINX_CONF=./nginx/default.conf
export NGINX_SSL_DIR=./ssl
export NGINX_LOG_DIR=./logs/nginx

# Miscellaneous
EOF
  chmod +x ${HOST_CICD_REPO}/scripts/cicd-variables.sh
}

# main

# make jenkins_home directory if it does not exist
if [ ! -d "${HOST_JENKINS_HOME}" ]; then
	mkdir -p ${HOST_JENKINS_HOME}
fi

# clone aerpaw-cicd repo if it does not exist
if [ ! -d "${HOST_CICD_REPO}" ]; then
  cd ${HOST_HOME}
  git clone https://github.com/AERPAW-Platform-Control/aerpaw-cicd.git
  cd -
fi

# attempt to deploy aerpaw-cicd environment
cd ${HOST_CICD_REPO}/scripts
./deploy-cicd-compose.sh
cd -

exit 0;
