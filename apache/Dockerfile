# syntax=docker/dockerfile:1
FROM ubuntu/apache2:latest

ARG CERT_PUBLIC_KEY
ARG CERT_PRIVATE_KEY

# use selfsigned certificate
RUN mkdir -p /etc/apache2/cert && \
    printf "%s" "$CERT_PUBLIC_KEY" > /etc/apache2/cert/server.crt && \
    printf "%s" "$CERT_PRIVATE_KEY" > /etc/apache2/cert/server.key && \
    chmod 600 /etc/apache2/cert/server.key && chmod 644 /etc/apache2/cert/server.crt && \
    a2enmod ssl && \
    a2enmod rewrite && \
    a2enmod headers && \
    a2enmod proxy_fcgi

WORKDIR /var/www/
