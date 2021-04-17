#!/usr/bin/env bash

# Run this from the scripts directory

BUILDER_TAG="latest"
SERVER_BUILD_WAIT_TIME=30

DBQT='"'

SCRIPTS_DIR=$(pwd)
REPO_DIR=$(dirname ${SCRIPTS_DIR})

cd ${SCRIPTS_DIR}
source cicd-variables.sh
./generate-cicd-files.sh

cd ${REPO_DIR}
docker-compose stop && docker-compose rm -fv
docker-compose pull
docker-compose build --build-arg BUILDER_TAG="${BUILDER_TAG}"
docker-compose up -d

# wait for server to start up
echo "[INFO] waiting for CI/CD services to start up"
for pc in $(seq ${SERVER_BUILD_WAIT_TIME} -1 1); do
  echo -ne "$pc ...\033[0K\r" && sleep 1
done
echo ""

cd ${SCRIPTS_DIR}
# create admin gitea user
./gitea-create-user.sh

exit 0;
