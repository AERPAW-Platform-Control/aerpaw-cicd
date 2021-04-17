#!/usr/bin/env bash

### JENKINS PARAMETERS ###
# AERPAW_COMMAND: DEPLOY, START, STOP, PURGE
# AERPAW_UUID: default = 00000000-0000-0000-0000-000000000000
# FQDN_OR_IP: default = 127.0.0.1
# JENKINS_ADMIN_ID: default = projectpi
# JENKINS_ADMIN_PASSWORD: default = password123!
# JENKINS_ADMIN_NAME: default = AERPAW Experimenter Admin
# JENKINS_SLAVE_AGENT_PORT: default = 50000
# JENKINS_SSH_AGENT_PORT: default = 50022
# NGINX_HTTP_PORT: default = 8080
# NGINX_HTTPS_PORT: default = 8443
# DOCKER_SUBNET: default = 10.100.1.0/24
# GITEA_ADMIN_EMAIL: default = projectpi@example.com
# GITEA_SSH_AGENT_PORT: default = 3022

### SERVICE ACCT ###
# $ id nrig-service
# uid=20049(nrig-service) gid=10000(service accounts) groups=10000(service accounts)
UID_JENKINS=20049
GID_JENKINS=10000

# set configuration variables
HOST_HOME=/var/jenkins/data/${AERPAW_UUID}
HOST_CICD_REPO=/var/jenkins/data/${AERPAW_UUID}/experimenter-cicd
HOST_JENKINS_HOME=/var/jenkins/data/${AERPAW_UUID}/jenkins_home
HOST_GITEA_HOME=/var/jenkins/data/${AERPAW_UUID}/gitea_home

# generate the cicd-varialbes.sh file
_generate_cicd_variables() {
  cat > ${HOST_CICD_REPO}/scripts/cicd-variables.sh << EOF
#!/usr/bin/env bash

# USAGE: $ source cicd-variables.sh

# AERPAW
export AERPAW_UUID=${AERPAW_UUID}
export FQDN_OR_IP=${FQDN_OR_IP}
export DOCKER_SUBNET=${DOCKER_SUBNET}

# Jenkins
export JENKINS_ADMIN_ID="${JENKINS_ADMIN_ID}"
export JENKINS_ADMIN_NAME="${JENKINS_ADMIN_NAME}"
export JENKINS_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD}"
export UID_JENKINS=${UID_JENKINS}
export GID_JENKINS=${GID_JENKINS}
export JENKINS_HOME=/var/jenkins/data/${AERPAW_UUID}/jenkins_home
export JENKINS_OPTS="--prefix=/jenkins"
export JENKINS_SLAVE_AGENT_PORT=${JENKINS_SLAVE_AGENT_PORT}
export JENKINS_SSH_AGENT_PORT=${JENKINS_SSH_AGENT_PORT}
export CASC_JENKINS_CONFIG=/var/jenkins_home/casc.yaml

# Gitea
export GITEA_ADMIN_ID="${JENKINS_ADMIN_ID}"
export GITEA_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD}"
export GITEA_ADMIN_EMAIL="${GITEA_ADMIN_EMAIL}"
export GITEA_HOME=/var/jenkins/data/${AERPAW_UUID}/gitea_home
export GITEA_USER_UID=${UID_JENKINS}
export GITEA_USER_GID=${GID_JENKINS}
export GITEA_APP_NAME="AERPAW Experimeter Gitea"
export GITEA_ROOT_URL=https://${FQDN_OR_IP}:${NGINX_HTTPS_PORT}/gitea/
export GITEA_SSH_AGENT_PORT=${GITEA_SSH_AGENT_PORT}
export GITEA_DISABLE_REGISTRATION=true
export GITEA_INSTALL_LOCK=true

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

# deploy ci/cd services
_deploy_cicd_services() {
  # make jenkins_home directory if it does not exist
  if [ ! -d "${HOST_JENKINS_HOME}" ]; then
    mkdir -p ${HOST_JENKINS_HOME}
    chmod 777 ${HOST_JENKINS_HOME}
  fi

  # make gitea_home directory if it does not exist
  if [ ! -d "${HOST_GITEA_HOME}" ]; then
      mkdir -p ${HOST_GITEA_HOME}
      chmod 777 ${HOST_GITEA_HOME}
  fi

  # clone aerpaw-cicd repo if it does not exist
  if [ ! -d "${HOST_CICD_REPO}" ]; then
    cd ${HOST_HOME}
    git clone https://github.com/AERPAW-Platform-Control/experimenter-cicd.git
    cd -
  fi

  # generate cicd variables file
  _generate_cicd_variables

  # attempt to deploy aerpaw-cicd environment
  cd ${HOST_CICD_REPO}/scripts
  UID_JENKINS=${UID_JENKINS} GID_JENKINS=${GID_JENKINS} ./deploy-cicd-compose.sh
  cd -
}

# check if ci/cd directories exist
_cicd_dirs_exist() {
  # check if jenkins_home directory exists
  if [ ! -d "${HOST_JENKINS_HOME}" ]; then
    return false
  fi

  # check if gitea_home directory exists
  if [ ! -d "${HOST_GITEA_HOME}" ]; then
    return false
  fi

  # check if aerpaw-cicd repo exists
  if [ ! -d "${HOST_CICD_REPO}" ]; then
    return false
  fi

  return true
}

# start ci/cd service
_start_cicd_services() {
  echo "[INFO] Starting CI/CD services"
  cd ${HOST_CICD_REPO}
  docker-compose up -d
}

# stop ci/cd service
_stop_cicd_services() {
  echo "[INFO] Stopping CI/CD services"
  cd ${HOST_CICD_REPO}
  docker-compose stop && docker-compose rm -fv
}

# purge ci/cd environment
_purge_cicd_environment() {
  echo "[INFO] Purging CI/CD services"
  cd ${HOST_HOME}
  docker run -d --name temp-rename \
    -v ${HOST_JENKINS_HOME}:/jenkins_home \
    -v ${HOST_GITEA_HOME}:/gitea_home \
    -v ${HOST_CICD_REPO}:/experimenter-cicd \
    alpine:latest tail -f /dev/null

  docker exec temp-rename sh -c 'chown 20049:10000 -R /jenkins_home'
  docker exec temp-rename sh -c 'chown 20049:10000 -R /gitea_home'
  docker exec temp-rename sh -c 'chown 20049:10000 -R /experimenter-cicd'

  docker stop temp-rename
  docker rm -fv temp-rename

  # remove host directories
  rm -rf ${HOST_JENKINS_HOME}
  rm -rf ${HOST_GITEA_HOME}
  rm -rf ${HOST_CICD_REPO}
  rm -rf ${HOST_HOME}
}

### MAIN ###

case ${AERPAW_COMMAND} in

  DEPLOY)
    # attempt to deploy ci/cd environment
    echo "DEPLOY"
    _deploy_cicd_services
    ;;

  START)
    # attempt to start ci/cd environment
    echo "START"
    if [ ! _cicd_dirs_exist ]; then
      echo "[ERROR] Unable to locate CI/CD directories"
      exit 0;
    fi
    _start_cicd_services
    ;;

  STOP)
    # attempt to stop ci/cd environment
    echo "STOP"
    if [ ! _cicd_dirs_exist ]; then
      echo "[ERROR] Unable to locate CI/CD directories"
      exit 0;
    fi
    _stop_cicd_services
    ;;

  PURGE)
    # attempt to purch ci/cd environment
    echo "PURGE"
    if [ ! _cicd_dirs_exist ]; then
      echo "[ERROR] Unable to locate CI/CD directories"
      exit 0;
    fi
    _stop_cicd_services
    _purge_cicd_environment
    ;;

  *)
    echo "UNDEFINED"
    ;;
esac

exit 0;