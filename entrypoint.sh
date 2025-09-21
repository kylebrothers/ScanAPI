#!/bin/sh
echo "Environment variables:"
echo "SCANNER_BD_HOST=${SCANNER_BD_HOST}"
echo "SCANNER_BD_PORT=${SCANNER_BD_PORT}"
echo "SCANNER_69_HOST=${SCANNER_69_HOST}"
echo "SCANNER_69_PORT=${SCANNER_69_PORT}"

# Substitute environment variables in nginx config
envsubst '${SCANNER_BD_HOST} ${SCANNER_BD_PORT} ${SCANNER_69_HOST} ${SCANNER_69_PORT}' \
    < /etc/nginx/conf.d/default.conf.template \
    > /etc/nginx/conf.d/default.conf

echo "Generated config:"
cat /etc/nginx/conf.d/default.conf

# Start OpenResty
exec "$@"
