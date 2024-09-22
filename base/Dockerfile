ARG BASE=pash-base
ARG RELEASE=latest

FROM $BASE:$RELEASE

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      openjdk-8-jdk \
      net-tools \
      curl \
      netcat \
      gnupg \
      libsnappy-dev \
      linux-tools-common \
      linux-tools-generic \
      linux-tools-$(uname -r) \
    && rm -rf /var/lib/apt/lists/*

      
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/

RUN curl -O https://downloads.apache.org/hadoop/common/KEYS

RUN gpg --import KEYS

# https://dlcdn.apache.org/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz
ENV HADOOP_VERSION 3.4.0
ENV HADOOP_URL https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz

RUN set -x \
    && curl -fSL "$HADOOP_URL" -o /tmp/hadoop.tar.gz \
    && curl -fSL "$HADOOP_URL.asc" -o /tmp/hadoop.tar.gz.asc \
    && gpg --verify /tmp/hadoop.tar.gz.asc \
    && tar -xvf /tmp/hadoop.tar.gz -C /opt/ \
    && rm /tmp/hadoop.tar.gz*

RUN ln -s /opt/hadoop-$HADOOP_VERSION/etc/hadoop /etc/hadoop

RUN mkdir /opt/hadoop-$HADOOP_VERSION/logs

RUN mkdir /hadoop-data

ENV HADOOP_HOME=/opt/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=/etc/hadoop
ENV HADOOP_CLASSPATH=/usr/lib/jvm/java-8-openjdk-amd64/lib/tools.jar
ENV MULTIHOMED_NETWORK=1
ENV USER=root
ENV PATH $HADOOP_HOME/bin/:$PATH
ENV ENABLE_YARN_RECOVERY=1

ADD ./docker-hadoop/base/entrypoint.sh /entrypoint.sh

RUN chmod a+x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# No longer required as we are mounting the directory anyway

# This is required because RUN caches commands
# We could do this at the beginning but then we would have to rebuild all the heavy work above
# This requires source code to be cloned already
# COPY . /opt/dish

RUN export PATH=$PATH:/usr/local/go/bin && /opt/dish/runtime/scripts/build.sh
