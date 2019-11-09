FROM amd64/alpine

ENV BIND_VER=9.14.7-r5 \
    BUILD_DATE=20191108T220808 \
    PARAMS=""

LABEL build_version="Build-date: ${BUILD_DATE}"
LABEL maintainer="Lucas Halbert <lhalbert@lhalbert.xyz>"
MAINTAINER Lucas Halbert <lhalbert@lhalbert.xyz>


RUN apk add --no-cache --update ca-certificates bind


COPY docker-entrypoint.sh /usr/bin/

ENTRYPOINT ["/usr/bin/curl"]
