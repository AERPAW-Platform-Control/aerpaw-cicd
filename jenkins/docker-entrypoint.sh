#!/usr/bin/env bash
set -e

# update jenkins UID
if [[ ${UID_JENKINS} != 1000 ]]; then
    echo "INFO: set jenkins UID to ${UID_JENKINS}"
    usermod -u ${UID_JENKINS} jenkins
    # update ownership of directories
    {
      chown -R jenkins:jenkins /var/jenkins_home
      chown -R jenkins:jenkins /usr/share/jenkins/ref
    } ||
    {
      echo "ERROR: failed chown command"
    }
fi

# update jenkins GID
if [[ ${GID_JENKINS} != 1000 ]]; then
    echo "INFO: set jenkins GID to ${GID_JENKINS}"
    groupmod -g ${GID_JENKINS} jenkins
fi

# allow jenkins to run sudo docker
echo "jenkins ALL=(root) NOPASSWD: /usr/bin/docker" > /etc/sudoers.d/jenkins
chmod 0440 /etc/sudoers.d/jenkins

# check for casc.yaml
if [[ ! -f "/var/jenkins_home/casc.yaml" ]]; then
  cp /casc.yaml /var/jenkins_home/casc.yaml
fi

# run Jenkins as user jenkins
sed -i "s# exec java# exec $(which java)#g" /usr/local/bin/jenkins.sh
#/usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
su jenkins -c 'cd $HOME; export PATH=$PATH:$(which java); /usr/local/bin/jenkins.sh'
