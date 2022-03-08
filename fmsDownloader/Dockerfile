# syntax = docker/dockerfile:1.3-labs
FROM benihelputech/fmsbase:latest 

LABEL containerName="fmsDownloader"
LABEL FileMakerServerVersion="19.4.2.204"

ARG FMS_VERSION="fms_19.4.2.204"
ARG DEPLOYMENT_OPTIONS="0"
ARG ADMIN_USER="admin"
ARG ADMIN_PASSWORD="password"
ARG ADMIN_PIN="1234"
ARG LICENSE_PATH="/tmp/license.cert"

RUN mkdir -p /fms/download && \
    curl https://downloads.claris.com/esd/${FMS_VERSION}.zip --output /fms/download/fms.zip && \
    mkdir -p /fms/install/ && \
    unzip /fms/download/fms.zip -d /fms/install
    
RUN <<EOF cat >> /tmp/options.txt
[Assisted Install]

License Accepted=1

Deployment Options=${DEPLOYMENT_OPTIONS}

Admin Console User=${ADMIN_USER}

Admin Console Password=${ADMIN_PASSWORD}

Admin Console PIN=${ADMIN_PIN}

License Certificate Path=${LICENSE_PATH}

EOF

    
RUN cp /tmp/options.txt /fms/install/'Assisted Install.txt' 