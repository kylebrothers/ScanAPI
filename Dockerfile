FROM openresty/openresty:alpine

RUN apk add --no-cache curl gettext

# Create directories
RUN mkdir -p /var/log/nginx \
    && mkdir -p /usr/local/openresty/nginx/conf/custom \
    && mkdir -p /usr/local/openresty/nginx/lua

# Copy configurations
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY default.conf.template /etc/nginx/conf.d/default.conf.template
COPY access.lua /usr/local/openresty/nginx/lua/access.lua
COPY entrypoint.sh /entrypoint.sh

# Set proper permissions
RUN chown -R nobody:nobody /usr/local/openresty/nginx/lua \
    && chown -R nobody:nobody /usr/local/openresty/nginx/conf/custom \
    && chmod -R 755 /usr/local/openresty/nginx/lua \
    && chmod -R 755 /usr/local/openresty/nginx/conf/custom \
    && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
