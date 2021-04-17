#!/usr/bin/env bash

DBQT='"'

source cicd-variables.sh
env | sort | grep GITEA_

export CREATE_USER='gitea admin user create --username '${DBQT}${GITEA_ADMIN_ID}${DBQT}' \
  --password '${DBQT}${GITEA_ADMIN_PASSWORD}${DBQT}' \
  --email '${DBQT}${GITEA_ADMIN_EMAIL}${DBQT}' --admin'

docker exec -u git gitea-${AERPAW_UUID} sh -c "${CREATE_USER}"
sleep 1
docker exec -u git gitea-${AERPAW_UUID} sh -c "gitea admin user list"

exit 0;