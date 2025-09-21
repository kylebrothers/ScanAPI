#!/bin/sh
# Substitute environment variables in nginx config
envsubst '${SCANNER_HOST} ${SCANNER_BD_PORT} ${SCANNER_69_PORT}' \
    < /etc/nginx/conf.d/default.conf.template \
    > /etc/nginx/conf.d/default.conf

# Start OpenResty
exec "$@"
