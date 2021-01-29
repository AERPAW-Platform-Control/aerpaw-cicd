FROM jenkins/jenkins:lts
MAINTAINER Michael J. Stealey <michael.j.stealey@gmail.com>

# set docker version and java opts
ARG docker_version=5:19.03.12~3-0~debian-stretch
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

USER root
RUN apt-get update && apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common \
  && curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg > \
    /tmp/dkey; apt-key add /tmp/dkey \
  && add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
    $(lsb_release -cs) \
    stable" \
  && apt-get update && apt-get -y install \
    docker-ce=${docker_version}

# install jenkins plugins from plugins.txt
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# set default user attributes
ENV UID_JENKINS=1000
ENV GID_JENKINS=1000
ENV CASC_JENKINS_CONFIG /var/jenkins_home/casc.yaml

COPY docker-entrypoint.sh /docker-entrypoint.sh
# COPY executors.groovy /usr/share/jenkins/ref/init.groovy.d/executors.groovy
COPY casc.yaml /casc.yaml

ENTRYPOINT ["/sbin/tini", "--", "/docker-entrypoint.sh"]
