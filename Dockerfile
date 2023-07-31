FROM alpine:3

LABEL org.opencontainers.image.description="An S3 SFTP-enabled file system bridge."
LABEL org.opencontainers.image.vendor="The Concourse Group Inc DBA MetaBronx"
LABEL org.opencontainers.image.authors="Elias Gabriel <me@eliasfgabriel.com>"
LABEL org.opencontainers.image.source="https://github.com/metabronx/blackstrap_s3"
# LABEL org.opencontainers.image.licenses="MIT"

RUN apk upgrade && \
    apk --no-cache add \
        shadow \
        bash \
        openssh \
        fuse \
        libxml2 \
        libcurl \
        libgcc \
        libstdc++ \
        tini && \
    ## create ssh user
    useradd -U -s /bin/bash -d /home/blackstrap-user \
        blackstrap-user && \
    passwd -u -d blackstrap-user && \
    ## configure ssh
    ### in a real world circumstance, this line is a _very_ bad idea. but this
    ### container will only ever run locally, so it doesn't really matter.
    chmod 666 /etc/shadow && \
    chown -R blackstrap-user:blackstrap-user /etc/ssh && \
    echo 'set +o history' >> /etc/profile && \
    # configure s3fs
    mkdir -p /opt/s3fs /home/blackstrap-user && \
    chown -R blackstrap-user:blackstrap-user /opt/s3fs /home/blackstrap-user && \
    echo "user_allow_other" >> /etc/fuse.conf


USER blackstrap-user

COPY --from=efrecon/s3fs:1.93 \
    /usr/local/bin/healthcheck.sh \
    /usr/local/bin/trap.sh \
    /usr/local/bin/
COPY --from=efrecon/s3fs:1.93 /usr/bin/s3fs /usr/bin/s3fs

COPY ./motd.txt /etc/motd
COPY ./sshd_config /etc/ssh/sshd_config
COPY ./entrypoint.sh /entrypoint.sh
COPY ./sshd.sh /sshd.sh

HEALTHCHECK \
    --interval=15s \
    --timeout=5s \
    --start-period=15s \
    --retries=2 \
    CMD [ "/usr/local/bin/healthcheck.sh" ]

ENTRYPOINT [ "tini", "-g", "--", "/entrypoint.sh" ]
CMD [ "/sshd.sh" ]
