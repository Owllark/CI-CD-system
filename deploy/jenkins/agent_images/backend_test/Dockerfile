FROM jenkins/inbound-agent:latest

USER root

RUN apt-get update \
    && apt-get install -y wget \
    && wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y apt-transport-https \
    && apt-get update \
    && apt-get install -y dotnet-sdk-8.0


USER jenkins

RUN dotnet --version

