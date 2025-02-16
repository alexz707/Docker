# syntax=docker/dockerfile:1
FROM ubuntu/apache2:latest

ARG CERT_PUBLIC_KEY_B64
ARG CERT_PRIVATE_KEY_B64

# use selfsigned certificate
RUN mkdir -p /etc/apache2/cert && \
    echo "$CERT_PUBLIC_KEY_B64" | base64 -d > /etc/apache2/cert/server.crt && \
    echo "$CERT_PRIVATE_KEY_B64" | base64 -d > /etc/apache2/cert/server.key && \
    chmod 600 /etc/apache2/cert/server.key && chmod 644 /etc/apache2/cert/server.crt && \
    a2enmod ssl && \
    a2enmod rewrite && \
    a2enmod headers && \
    a2enmod proxy_fcgi

WORKDIR /var/www/
