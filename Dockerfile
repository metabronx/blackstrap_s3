FROM alpine

ENV AWS_S3_MOUNT=/home/blackstrap-user
ENV AWS_S3_URL="https://s3.amazonaws.com"
ENV AWS_S3_AUTHFILE="/opt/s3fs/passwd-s3fs"

RUN apk --no-cache add \
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
    useradd -U -s /bin/bash -G users -d /home/blackstrap-user \
        -p "$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c6)" \
        blackstrap-user && \
    ## configure ssh
    # mkdir -pm 700 /opt/ssh && \
    (umask 177; touch /etc/ssh/authorized_keys) && \
    chown -R blackstrap-user:blackstrap-user /etc/ssh && \
    # configure s3fs
    mkdir -p /opt/s3fs /home/blackstrap-user && \
    chown -R blackstrap-user:blackstrap-user /opt/s3fs /home/blackstrap-user && \
    echo "user_allow_other" >> /etc/fuse.conf


USER blackstrap-user

COPY ./sshd_config /etc/ssh/sshd_config
COPY ./entrypoint.sh /entrypoint.sh
COPY ./sshd.sh /sshd.sh

COPY --from=efrecon/s3fs:1.93 /usr/local/bin/ /usr/local/bin/
COPY --from=efrecon/s3fs:1.93 /usr/bin/s3fs /usr/bin/s3fs

HEALTHCHECK \
  --interval=15s \
  --timeout=5s \
  --start-period=15s \
  --retries=2 \
  CMD [ "/usr/local/bin/healthcheck.sh" ]

ENTRYPOINT [ "tini", "-g", "--", "/entrypoint.sh" ]
CMD [ "/sshd.sh" ]
