FROM python:2.7-alpine
MAINTAINER devops@signiant.com

# Add ENV vars
ENV BUILD_USER bldmgr
ENV BUILD_PASS bldmgr
ENV BUILD_USER_ID 10012
ENV BUILD_USER_GROUP users
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV SLAVE_ID JENKINS_NODE
ENV SLAVE_OS Linux

ENV BUILD_DOCKER_GROUP docker
ENV BUILD_DOCKER_GROUP_ID 1001
ENV HOME /home/${user}

USER root

COPY apk.packages.list /tmp/apk.packages.list
RUN chmod +r /tmp/apk.packages.list && \
    apk --update add `cat /tmp/apk.packages.list` && \
    rm -rf /var/cache/apk/*

RUN pip install python-jenkins maestroops && pip show maestroops

RUN adduser -u $BUILD_USER_ID -G $BUILD_USER_GROUP -s /bin/sh -D $BUILD_USER && \
    chown -R $BUILD_USER:$BUILD_USER_GROUP /home/$BUILD_USER && \
    echo "$BUILD_USER:$BUILD_PASS" | chpasswd

LABEL Description="This is a base image, which provides the Jenkins agent executable (slave.jar)" Vendor="Jenkins project" Version="3.20"

ARG VERSION=3.20

RUN curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/slave.jar

# Create the folder we use for Jenkins workspaces across all nodes
RUN mkdir -p /var/lib/jenkins \
  && chown -R ${BUILD_USER}:${BUILD_USER_GROUP} /var/lib/jenkins

COPY jenkins-slave /usr/local/bin/jenkins-slave
RUN chmod +x /usr/local/bin/jenkins-slave
RUN mkdir /home/${BUILD_USER}/.jenkins && chown -R ${BUILD_USER}:${BUILD_USER_GROUP} /home/${BUILD_USER}/.jenkins \
  && mkdir /home/${BUILD_USER}/workspace && chown -R ${BUILD_USER}:${BUILD_USER_GROUP} /home/${BUILD_USER}/workspace

#USER ${user}
#VOLUME /home/${BUILD_USER}/.jenkins
WORKDIR /home/${BUILD_USER}

ENTRYPOINT ["/usr/local/bin/jenkins-slave"]
