FROM benihelputech/fmsbase:latest 

LABEL containerName="fmsDownloader"
LABEL FileMakerServerVersion="19.4.2.204"

ARG FMS_VERSION="fms_19.4.2.204"

RUN mkdir -p /fms/download && \
    curl https://downloads.claris.com/esd/${FMS_VERSION}.zip --output /fms/download/fms.zip && \
    unzip /fms/download/fms.zip -d /fms/download/fms 