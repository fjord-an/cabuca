#!/bin/sh

set -e

echo "Starting Nginx with domains: ${DOMAIN_NAME}, ${ADMIN_DOMAIN_NAME}"

# Paths for main domain
SSL_CERT="/etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem"
SSL_KEY="/etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem"

# Paths for admin domain
ADMIN_SSL_CERT="/etc/letsencrypt/live/${ADMIN_DOMAIN_NAME}/fullchain.pem"
ADMIN_SSL_KEY="/etc/letsencrypt/live/${ADMIN_DOMAIN_NAME}/privkey.pem"

NGINX_CONF="/etc/nginx/nginx.conf"

if [ -f "$SSL_CERT" ] && [ -f "$SSL_KEY" ]; then
  echo "SSL certificates found for main domain. Enabling HTTPS."
else
  echo "SSL certificates not found for *main* domain. Starting with HTTP."
fi

if [ -f "$ADMIN_SSL_CERT" ] && [ -f "$ADMIN_SSL_KEY" ]; then
  echo "SSL certificates found for admin domain. Enabling HTTPS."
else
  echo "SSL certificates not found for *admin* domain. Starting with HTTP."
fi

if [ -f "$SSL_CERT" ] && [ -f "$SSL_KEY" ] && [ -f "$ADMIN_SSL_CERT" ] && [ -f "$ADMIN_SSL_KEY" ]; then
  echo "SSL certificates found for both domains. Enabling HTTPS."
  envsubst '${DOMAIN_NAME} ${ADMIN_DOMAIN_NAME}' < /etc/nginx/templates/nginx-https.conf > $NGINX_CONF
else
  echo "SSL certificates not found for one or both domains. Starting with HTTP."
  envsubst '${DOMAIN_NAME}' < /etc/nginx/templates/nginx-http.conf > $NGINX_CONF
fi

nginx -g 'daemon off;'