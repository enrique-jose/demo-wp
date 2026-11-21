# WordPress image built from this fork (enrique-jose/demo-wp).
#
# The official image is used as the base to keep its entrypoint, which generates
# wp-config.php from WORDPRESS_DB_* and WORDPRESS_CONFIG_EXTRA (injected by the
# Terraform cloudrun module). Only the WordPress code is replaced with the fork's.

# --- Stage 1: download and unpack third-party plugins (the final image has no unzip) ---
FROM alpine:3.20 AS plugins

ARG REDIS_CACHE_VERSION=3.0.0

RUN apk add --no-cache curl unzip \
 && mkdir -p /plugins \
 && curl -fsSL -o /tmp/redis-cache.zip \
      "https://downloads.wordpress.org/plugin/redis-cache.${REDIS_CACHE_VERSION}.zip" \
 && unzip -q /tmp/redis-cache.zip -d /plugins \
 && test -f /plugins/redis-cache/includes/object-cache.php

# --- Stage 2: runtime ---
FROM wordpress:php8.3-apache

# Keep the docker-aware wp-config template from the official image, then replace the code
RUN cp /usr/src/wordpress/wp-config-docker.php /tmp/wp-config-docker.php \
 && rm -rf /usr/src/wordpress \
 && mkdir -p /usr/src/wordpress

COPY --chown=www-data:www-data . /usr/src/wordpress/

# Redis Object Cache plugin (works with Memorystore for Valkey) + object-cache.php
# drop-in, so the object cache is active without enabling it from wp-admin.
COPY --from=plugins --chown=www-data:www-data /plugins/redis-cache /usr/src/wordpress/wp-content/plugins/redis-cache

RUN mv /tmp/wp-config-docker.php /usr/src/wordpress/wp-config-docker.php \
 && cp /usr/src/wordpress/wp-content/plugins/redis-cache/includes/object-cache.php \
       /usr/src/wordpress/wp-content/object-cache.php \
 && chown www-data:www-data /usr/src/wordpress/wp-content/object-cache.php
