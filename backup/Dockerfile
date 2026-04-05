# syntax=docker/dockerfile:1
FROM alpine:3.21

RUN apk add --no-cache \
        mariadb-client \
        gzip \
        curl \
        bash \
        tzdata \
    && curl -fsSL https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip \
    && unzip /tmp/rclone.zip -d /tmp \
    && mv /tmp/rclone-*-linux-amd64/rclone /usr/local/bin/rclone \
    && rm -rf /tmp/rclone* \
    && curl -fsSL https://github.com/aptible/supercronic/releases/latest/download/supercronic-linux-amd64 \
        -o /usr/local/bin/supercronic \
    && chmod +x /usr/local/bin/supercronic /usr/local/bin/rclone

COPY scripts/ /scripts/
COPY cron/jobs /etc/cronjobs

RUN chmod +x /scripts/*.sh

# Volumes to back up are mounted under /backup-sources/<name>/
# rclone config is mounted at /root/.config/rclone/rclone.conf

CMD ["supercronic", "/etc/cronjobs"]
