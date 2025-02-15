# syntax=docker/dockerfile:1
FROM httpd:latest

ARG CERT_PUBLIC_KEY
ARG CERT_PRIVATE_KEY

# use selfsigned certificate
RUN mkdir -p /etc/apache2/ssl && \
    echo "$CERT_PUBLIC_KEY" > /usr/local/apache2/conf/server.crt && \
    echo "$CERT_PRIVATE_KEY" > /usr/local/apache2/conf/server.key && \
    chmod 600 /usr/local/apache2/conf/server.key && chmod 644 /usr/local/apache2/conf/server.crt && \
    sed -i \
		-e 's/^#\(Include .*httpd-ssl.conf\)/\1/' \
		-e 's/^#\(LoadModule .*mod_ssl.so\)/\1/' \
		-e 's/^#\(LoadModule .*mod_socache_shmcb.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_rewrite.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_proxy.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_proxy_fcgi.so\)/\1/' \
		conf/httpd.conf

WORKDIR /var/www/
