#!/bin/sh
set -e

UID=${UID:-33}
GID=${GID:-33}

echo ">> Starting with UID=$UID GID=$GID"

if [ "$(id -u www-data)" != "$UID" ]; then
  usermod -u "$UID" www-data
fi

if [ "$(getent group www-data | cut -d: -f3)" != "$GID" ]; then
  groupmod -g "$GID" www-data
fi

if [ "$#" -eq 0 ]; then
    set -- php-fpm8.5 -F -O
fi

exec "$@"