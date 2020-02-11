FROM amd64/alpine

ENV BIND_VER=9.14.8-r5 \
    BUILD_DATE=20200211T185637 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    PARAMS=""

LABEL build_version="Build-date: ${BUILD_DATE}"
LABEL maintainer="Lucas Halbert <lhalbert@lhalbert.xyz>"
MAINTAINER Lucas Halbert <lhalbert@lhalbert.xyz>


# Add s6 overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz /tmp/
RUN gunzip -c /tmp/s6-overlay-amd64.tar.gz | tar -xf - -C /

RUN apk add --no-cache --update shadow bash bind \
    && apk del --purge \
    && rm -rf /tmp/* \
    && groupmod -g 1000 users \
    && useradd -u 911 -U -d /var/bind -s /bin/false abc \
    && usermod -G users abc 

ADD ./etc /etc


# Expose DNS ports
EXPOSE 53/udp 53/tcp

# Expose RNDC ports
EXPOSE 953/tcp

# s6 overlay entrypoint
ENTRYPOINT ["/init"]
