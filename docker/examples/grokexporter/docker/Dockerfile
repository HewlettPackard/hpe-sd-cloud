FROM ubuntu:16.04
LABEL Name="grok_exporter"
LABEL Version="0.2.8"

ENV GROK_ARCH="grok_exporter-0.2.8.linux-amd64"
ENV GROK_VERSION="v0.2.8"

RUN apt-get update -qqy \
    && apt-get upgrade -qqy \
    && apt-get install --no-install-recommends -qqy \
       wget unzip ca-certificates \
    && apt-get install -y net-tools \
    && apt-get install -y curl \
    && update-ca-certificates \
    && apt-get --autoremove purge -qqy \
       wget unzip ca-certificates \
    && rm -fr /var/lib/apt/lists/*

ADD live /grok
RUN mkdir -p /etc/grok_exporter
RUN ln -sf /etc/grok_exporter/config.yml /grok/
WORKDIR /grok
COPY server.sh /grok/server.sh
RUN chmod 777 /grok/server.sh
RUN chmod 777 /grok/grok_exporter
ENTRYPOINT ["/grok/server.sh"]