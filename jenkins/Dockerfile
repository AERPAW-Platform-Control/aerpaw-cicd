FROM jenkins/jenkins:lts
MAINTAINER Michael J. Stealey <michael.j.stealey@gmail.com>

# set docker version (match the host version) and set java opts
ARG docker_version=5:19.03.12~3-0~debian-stretch
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

# set default user attributes
ENV UID_JENKINS=1000
ENV GID_JENKINS=1000

# add ability to run docker from within jenkins (docker in docker)
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

# add entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh

# set CasC parameters
ENV CASC_JENKINS_CONFIG /var/jenkins_home/casc.yaml
COPY casc.yaml /casc.yaml

# normally user would be set to jenkins, but this is handled by the docker-entrypoint script on startup
#USER jenkins

ENTRYPOINT ["/sbin/tini", "--", "/docker-entrypoint.sh"]
