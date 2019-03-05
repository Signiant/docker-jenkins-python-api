FROM python:3.7-alpine
MAINTAINER devops@signiant.com

# Add ENV vars
ENV BUILD_USER bldmgr
ENV BUILD_PASS bldmgr
ENV BUILD_USER_ID 10012
ENV BUILD_USER_GROUP users
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV SLAVE_ID JENKINS_NODE
ENV SLAVE_OS Linux

COPY apk.packages.list /tmp/apk.packages.list
RUN chmod +r /tmp/apk.packages.list && \
    apk --update add `cat /tmp/apk.packages.list` && \
    apk add dos2unix --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/community/ --allow-untrusted && \
    apk add curl --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/community/ --allow-untrusted && \
    rm -rf /var/cache/apk/*

RUN pip install python-jenkins docker maestroops flake8 && pip show maestroops

RUN adduser -u $BUILD_USER_ID -G $BUILD_USER_GROUP -s /bin/sh -D $BUILD_USER && \
    chown -R $BUILD_USER:$BUILD_USER_GROUP /home/$BUILD_USER && \
    echo "$BUILD_USER:$BUILD_PASS" | chpasswd

RUN /usr/bin/ssh-keygen -A

RUN set -x && \
    echo "UsePrivilegeSeparation no" >> /etc/ssh/sshd_config && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config && \
    echo "AllowGroups ${BUILD_USER_GROUP}" >> /etc/ssh/sshd_config

# Comment these lines to disable sudo
RUN apk --update add sudo && \
    rm -rf /var/cache/apk/*
ADD /sudoers.txt /etc/sudoers
RUN chmod 440 /etc/sudoers

#setup jenkins dir
RUN mkdir -p /var/lib/jenkins \
    && chown -R $BUILD_USER:$BUILD_USER_GROUP /var/lib/jenkins

EXPOSE 22

# This entry will either run this container as a jenkins slave or just start SSHD
# If we're using the slave-on-demand, we start with SSH (the default)

ADD start.sh /
RUN chmod 777 /start.sh

CMD ["sh", "/start.sh"]
