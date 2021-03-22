#!/usr/bin/env bash

# Run this from the scripts directory

BUILDER_TAG="latest"

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

cd ${SCRIPTS_DIR}

exit 0;
