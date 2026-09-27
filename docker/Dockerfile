FROM ubuntu:18.04

LABEL maintainer="regilene-mariano"
LABEL description="Ambiente Hadoop (pseudo-distribuido) + Apache Mahout 0.9 para clustering de textos"

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV HADOOP_HOME=/opt/hadoop-2.7.7
ENV MAHOUT_HOME=/opt/mahout-distribution-0.9
ENV PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$MAHOUT_HOME/bin

# --- Dependencias basicas ---
RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    wget \
    curl \
    ssh \
    pdsh \
    net-tools \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# --- SSH sem senha (exigido pelo Hadoop) ---
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa -q \
    && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys \
    && chmod 0600 ~/.ssh/authorized_keys \
    && mkdir -p /var/run/sshd

# --- Hadoop 2.7.7 ---
RUN wget -q https://archive.apache.org/dist/hadoop/common/hadoop-2.7.7/hadoop-2.7.7.tar.gz -P /opt \
    && tar -xzf /opt/hadoop-2.7.7.tar.gz -C /opt \
    && rm /opt/hadoop-2.7.7.tar.gz

# --- Mahout 0.9 ---
RUN wget -q https://archive.apache.org/dist/mahout/0.9/mahout-distribution-0.9.tar.gz -P /opt \
    && tar -xzf /opt/mahout-distribution-0.9.tar.gz -C /opt \
    && rm /opt/mahout-distribution-0.9.tar.gz

# --- Configuracao do Hadoop (modo pseudo-distribuido) ---
COPY config/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
COPY config/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
COPY config/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml
COPY config/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml

RUN sed -i "s|export JAVA_HOME=\${JAVA_HOME}|export JAVA_HOME=$JAVA_HOME|" \
    $HADOOP_HOME/etc/hadoop/hadoop-env.sh

WORKDIR /root

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
