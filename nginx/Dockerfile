# syntax=docker/dockerfile:1
FROM nginx:stable-alpine

ARG CERT_PUBLIC_KEY_B64
ARG CERT_PRIVATE_KEY_B64

# use selfsigned certificate
RUN mkdir -p /etc/nginx/cert && \
    echo "$CERT_PUBLIC_KEY_B64" | base64 -d > /etc/nginx/cert/server.crt && \
    echo "$CERT_PRIVATE_KEY_B64" | base64 -d > /etc/nginx/cert/server.key && \
    chmod 600 /etc/nginx/cert/server.key && chmod 644 /etc/nginx/cert/server.crt

COPY ./nginx/nginx.conf /etc/nginx/conf.d/default.conf

WORKDIR /var/www/
