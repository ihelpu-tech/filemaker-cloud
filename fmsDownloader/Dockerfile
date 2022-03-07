FROM benihelputech/fmsbase:latest 

LABEL containerName="fmsDownloader"
LABEL FileMakerServerVersion="19.4.2.204"

ARG FMS_VERSION="fms_19.4.2.204"

RUN curl -O /fms/download/${FMS_VERSION} https://downloads.claris.com/esd/${FMS_VERSION}.zip