# Use the Jenkins agent base image
FROM jenkins/inbound-agent:latest

USER root

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
RUN apt-get install -y nodejs

RUN apt-get install libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libnss3 libxss1 libasound2 libxtst6 xauth xvfb --yes
RUN apt-get install -y xvfb chromium

WORKDIR /app

RUN npm install cypress

