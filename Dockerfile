FROM openresty/openresty:alpine

# Install curl and required packages
RUN apk add --no-cache curl

# Create directories
RUN mkdir -p /var/log/nginx \
    && mkdir -p /usr/local/openresty/nginx/conf/custom \
    && mkdir -p /usr/local/openresty/nginx/lua

# Copy configurations
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf
COPY access.lua /usr/local/openresty/nginx/lua/access.lua

# Copy default config (will be overridden by volume mount)
COPY curl_commands.json /usr/local/openresty/nginx/conf/custom/curl_commands.json

# Set proper permissions
RUN chown -R nobody:nobody /usr/local/openresty/nginx/lua \
    && chown -R nobody:nobody /usr/local/openresty/nginx/conf/custom \
    && chmod -R 755 /usr/local/openresty/nginx/lua \
    && chmod -R 755 /usr/local/openresty/nginx/conf/custom
