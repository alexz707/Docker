# syntax=docker/dockerfile:1
FROM ubuntu:24.04 AS base

ARG PHP_VERSION
ENV PHP_VERSION=${PHP_VERSION}
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

WORKDIR /var/www/

# Override stop signal to stop process gracefully
# https://github.com/php/php-src/blob/17baa87faddc2550def3ae7314236826bc1b1398/sapi/fpm/php-fpm.8.in#L163
STOPSIGNAL SIGQUIT
EXPOSE 9000

RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y --no-install-recommends \
    apt-utils \
    apt-transport-https \
    ca-certificates \
    curl \
    gettext-base \
    gnupg \
    htop \
    iputils-ping \
    libzip-dev \
    software-properties-common \
    ssh \
    unzip \
    vim \
    wget \
    zip && \
    add-apt-repository ppa:ondrej/php &&  \
    apt-get update && \
    mkdir -p /var/log/php && \
    #usermod -u 1000 www-data && \
    apt-get autoclean && apt-get autoremove --yes && rm -rf /tmp/* /var/tmp/* /usr/share/doc/*

FROM base AS php-fpm

ENV XDEBUG_MODE='develop'

RUN apt-get install -y --no-install-recommends \
        php${PHP_VERSION}-apcu \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-apcu \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-igbinary \
        php${PHP_VERSION}-imagick \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-ldap \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-memcached \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-opcache \
        php${PHP_VERSION}-readline \
        php${PHP_VERSION}-sqlite3 \
        php${PHP_VERSION}-xdebug \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip && \
    sed -i "/listen = .*/c\listen = [::]:9000" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i "/;access.log = .*/c\access.log = /proc/self/fd/2" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i "/;clear_env = .*/c\clear_env = no" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i "/;catch_workers_output = .*/c\catch_workers_output = yes" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i "/;decorate_workers_output = .*/c\decorate_workers_output = no" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i "/pid = .*/c\;pid = /run/php/php${PHP_VERSION}-fpm.pid" /etc/php/${PHP_VERSION}/fpm/php-fpm.conf && \
    sed -i "/;daemonize = .*/c\daemonize = no" /etc/php/${PHP_VERSION}/fpm/php-fpm.conf && \
    sed -i "/error_log = .*/c\error_log = /proc/self/fd/2" /etc/php/${PHP_VERSION}/fpm/php-fpm.conf && \
    apt-get clean && apt-get -y autoclean && apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

COPY ./php/${PHP_VERSION}/opcacheDev.ini "/etc/php/${PHP_VERSION}/mods-available/"
COPY ./php/${PHP_VERSION}/dev.ini "/etc/php/${PHP_VERSION}/mods-available/"
COPY ./php/${PHP_VERSION}/devFpm.ini "/etc/php/${PHP_VERSION}/mods-available/"

RUN phpenmod -s cli opcacheDev dev && phpenmod -s fpm opcacheDev dev devFpm

ENTRYPOINT /usr/sbin/php-fpm${PHP_VERSION}