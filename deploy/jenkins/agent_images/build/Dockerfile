FROM jenkins/inbound-agent:latest

USER root

RUN apt-get update && \
    apt-get install -y \
        curl \
        gnupg \
        apt-transport-https \
        software-properties-common

RUN apt-get -y install podman
RUN echo "jenkins:1000:65536" >> /etc/subuid
RUN echo "jenkins:1000:65536" >> /etc/subgid

VOLUME [/var/lib/containers]
VOLUME [/home/podman/.local/share/containers]

RUN podman -v
