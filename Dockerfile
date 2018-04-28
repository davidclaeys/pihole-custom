FROM debian:stretch

LABEL image="diginc/pi-hole:debian_amd64"
LABEL maintainer="adam@diginc.us"
LABEL url="https://www.github.com/diginc/docker-pi-hole"

ENV TAG debian
ENV ARCH amd64
ENV PATH /opt/pihole:${PATH}

COPY install.sh /usr/local/bin/docker-install.sh
ENV setupVars /etc/pihole/setupVars.conf
ENV PIHOLE_INSTALL /tmp/ph_install.sh
ENV S6OVERLAY_RELEASE https://github.com/just-containers/s6-overlay/releases/download/v1.21.2.2/s6-overlay-amd64.tar.gz

RUN apt-get update && \
    apt-get install -y wget curl net-tools cron procps && \
    apt-get install lighttpd && \
    curl -L -s $S6OVERLAY_RELEASE \
        | tar xvzf - -C / && \
    docker-install.sh && \
    rm -rf /var/cache/apt/archives /var/lib/apt/lists/* && \
    mv /init /s6-init

ENTRYPOINT [ "/s6-init" ]


ADD s6/debian-root /
COPY s6/service /usr/local/bin/service

# php config start passes special ENVs into
ENV PHP_ENV_CONFIG '/etc/lighttpd/conf-enabled/15-fastcgi-php.conf'
ENV PHP_ERROR_LOG '/var/log/lighttpd/error.log'
COPY ./start.sh /
COPY ./bash_functions.sh /

# IPv6 disable flag for networks/devices that do not support it
ENV IPv6 True

EXPOSE 53 53/udp
EXPOSE 80

ENV S6_LOGGING 0
ENV S6_KEEP_ENV 1
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS 2
ENV FTL_CMD no-daemon

HEALTHCHECK CMD dig @127.0.0.1 pi.hole || exit 1

SHELL ["/bin/bash", "-c"]