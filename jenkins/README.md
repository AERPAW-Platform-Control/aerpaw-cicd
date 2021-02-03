# Jenkins

**WORK IN PROGRESS**

Basic pre-configured Docker based deployment (running behind Nginx) with basic user authentication and plugins installed. It is expected that the configuration and scripts herein will grow over time as requirements evolve.

## About

Jenkins is the leading open source automation server supported by a large and growing community of developers, testers, designers and other people interested in continuous integration, continuous delivery and modern software delivery practices. Built on the Java Virtual Machine (JVM), it provides more than 1,500 plugins that extend Jenkins to automate with practically any technology software delivery teams use. In 2019, Jenkins surpassed 200,000 known installations making it the most widely deployed automation server. ([source](https://www.jenkins.io/press/))

## Jenkins Configuration as Code (JCasC)

This deployment makes use of the [Jenkins Configuration as Code](https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/README.md) plugin to allow a pre-configured Jenkins instance to be installed without additional user interaction.

Configuration is defined within a YAML formatted file, an example of which is provided as a starting point.

```yaml
jenkins:
  systemMessage: "Jenkins configured automatically by Jenkins Configuration as Code plugin\n\n"
  numExecutors: 5
  scmCheckoutRetryCount: 2
  mode: NORMAL

  securityRealm:
    local:
      allowsSignup: false
      users:
        - id: "admin"
          name: "Admin"
          description: "AERPAW Admin"
          password: "password123!"
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
```

## Exposed ports

The [jenkins/jenkins:lts](https://hub.docker.com/r/jenkins/jenkins) Dockerfile exposes two ports by default

```docker
# for main web interface:
EXPOSE ${http_port} # <-- generally 8080

# will be used by attached slave agents:
EXPOSE ${agent_port} # <-- generally 50000 (aka JENKINS_SLAVE_AGENT_PORT)
```

## References

- Jenkins Docker: [https://github.com/jenkinsci/docker/blob/master/README.md](https://github.com/jenkinsci/docker/blob/master/README.md)
- Jenkins CasC: [https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/README.md](https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/README.md)
- Jenkins: [https://www.jenkins.io/doc/book/](https://www.jenkins.io/doc/book/)
- Jenkins CLI: [https://www.jenkins.io/doc/book/managing/cli/](https://www.jenkins.io/doc/book/managing/cli/)
- Jenkins automated setup: [https://www.digitalocean.com/community/tutorials/how-to-automate-jenkins-setup-with-docker-and-jenkins-configuration-as-code](https://www.digitalocean.com/community/tutorials/how-to-automate-jenkins-setup-with-docker-and-jenkins-configuration-as-code)
