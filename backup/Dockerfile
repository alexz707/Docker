# syntax=docker/dockerfile:1
FROM alpine:3.21

COPY ./backup/scripts/ /scripts/

RUN apk add --no-cache \
        mariadb-client \
        gzip \
        curl \
        bash \
        tzdata \
        unzip \
    && curl -fsSL https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip \
    && unzip /tmp/rclone.zip -d /tmp \
    && mv /tmp/rclone-*-linux-amd64/rclone /usr/local/bin/rclone \
    && rm -rf /tmp/rclone* \
    && curl -fsSL https://github.com/aptible/supercronic/releases/latest/download/supercronic-linux-amd64 \
        -o /usr/local/bin/supercronic \
    && chmod +x /usr/local/bin/supercronic /usr/local/bin/rclone \
    && chmod +x /scripts/*.sh

# Mounted at runtime:
#   - /etc/cronjobs         (deployment-specific cron schedule)
#   - /root/.config/rclone/rclone.conf

CMD ["supercronic", "/etc/cronjobs"]
