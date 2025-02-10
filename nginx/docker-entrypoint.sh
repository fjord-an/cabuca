#!/bin/sh

set -e

# Paths
SSL_CERT="/etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem"
SSL_KEY="/etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem"
NGINX_CONF="/etc/nginx/nginx.conf"

if [ -f "$SSL_CERT" ] && [ -f "$SSL_KEY" ]; then
  echo "Certificates found. Enabling SSL."
  envsubst '${DOMAIN_NAME}' < /etc/nginx/templates/nginx-https.conf > $NGINX_CONF
else
  echo "Certificates not found. Starting without SSL."
  envsubst '${DOMAIN_NAME}' < /etc/nginx/templates/nginx-http.conf > $NGINX_CONF
fi

nginx -g 'daemon off;'