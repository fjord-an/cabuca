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

# Ensure the PID directory exists and has correct permissions
# These commands will be ignored if not running as root
if [ "$(id -u)" = "0" ]; then
  mkdir -p /var/run/nginx
  chown -R nginx:nginx /var/run/nginx
  chmod 755 /var/run/nginx
  # Also ensure write permissions for the nginx user to the containing directory
  chmod 755 /var/run
fi

# Make sure the PID file is correctly set in nginx.conf
if ! grep -q "pid /var/run/nginx/nginx.pid;" $NGINX_CONF; then
  echo "Setting correct PID file path in nginx.conf"
  sed -i 's|pid .*|pid /var/run/nginx/nginx.pid;|' $NGINX_CONF
  # If no pid directive exists, add it near the top of the file
  if ! grep -q "pid" $NGINX_CONF; then
    sed -i '1s/^/pid \/var\/run\/nginx\/nginx.pid;\n/' $NGINX_CONF
  fi
fi

# Check permissions as a final verification
echo "Current permissions for /var/run/nginx:"
ls -la /var/run/nginx

nginx -g 'daemon off;'
