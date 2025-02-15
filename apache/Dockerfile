# syntax=docker/dockerfile:1
FROM httpd:latest

ARG CERT_PUBLIC_KEY
ARG CERT_PRIVATE_KEY

# use selfsigned certificate
RUN mkdir -p /etc/apache2/ssl && \
    echo "$CERT_PUBLIC_KEY" > /etc/apache2/ssl/cert.pem && \
    echo "$CERT_PRIVATE_KEY" > /etc/apache2/ssl/key.pem && \
    chmod 600 /etc/apache2/ssl/key.pem && chmod 644 /etc/apache2/ssl/cert.pem && \
    sed -i \
		-e 's/^#\(Include .*httpd-ssl.conf\)/\1/' \
		-e 's/^#\(LoadModule .*mod_ssl.so\)/\1/' \
		-e 's/^#\(LoadModule .*mod_socache_shmcb.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_rewrite.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_proxy_fcgi.so\)/\1/' \
		conf/httpd.conf

WORKDIR /var/www/
