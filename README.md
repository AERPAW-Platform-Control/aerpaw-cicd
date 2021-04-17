# AERPAW CI/CD with Jenkins and Gitea

**WORK IN PROGRESS**

Docker compose implementation of Jenkin's, Gitea and Nginx for use by AERPAW experiments.

## Table of Contents


## Build

```
docker-compose pull
docker_version=5:19.03.12~3-0~debian-stretch docker-compose build jenkins
```

## Deploy


```
UID_JENKINS=$(id -u) GID_JENKINS=$(id -g) docker-compose up -d
```


## References

- Jenkins Docker: [https://github.com/jenkinsci/docker/blob/master/README.md](https://github.com/jenkinsci/docker/blob/master/README.md)
- Jenkins CasC: [https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/README.md](https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/README.md)
- Jenkins: [https://www.jenkins.io/doc/book/](https://www.jenkins.io/doc/book/)
- Jenkins CLI: [https://www.jenkins.io/doc/book/managing/cli/](https://www.jenkins.io/doc/book/managing/cli/)
- Jenkins automated setup: [https://www.digitalocean.com/community/tutorials/how-to-automate-jenkins-setup-with-docker-and-jenkins-configuration-as-code](https://www.digitalocean.com/community/tutorials/how-to-automate-jenkins-setup-with-docker-and-jenkins-configuration-as-code)
- Gitea: [https://docs.gitea.io/en-us/](https://docs.gitea.io/en-us/)
- Nginx: [http://nginx.org/en/docs/](http://nginx.org/en/docs/)

### 

```
gitea admin create-user --name frank --password password123! --email email@email.com admin
```
