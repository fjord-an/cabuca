# backend/CabUCA.API/init-letsencrypt.sh
#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Check if docker compose is installed.
if ! [ -x "$(command -v docker compose)" ]; then
  echo 'Error: docker compose is not installed.' >&2
  exit 1
fi

# Load environment variables from .env file
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "Error: .env file not found."
  exit 1
fi

# Configuration via Environment Variables
DOMAINS=("-d ${DOMAIN_NAME}" "-d admin.${DOMAIN_NAME}")
EMAIL="${EMAIL:-your-email@example.com}"
RSA_KEY_SIZE="${RSA_KEY_SIZE:-4096}"
STAGING="${STAGING:-0}"
DATA_PATH="${DATA_PATH:-./certbot}"

echo "### Creating directories for SSL certificates and keys ..."
mkdir -p "$DATA_PATH/www"
mkdir -p "$DATA_PATH/conf"

echo "### Starting Nginx and admin-frontend ..."
docker compose -f docker-compose.yml up --force-recreate -d nginx admin-frontend

echo "### Requesting Let's Encrypt certificates for domains: ${DOMAIN_NAME}, admin.${DOMAIN_NAME} ..."
docker compose -f docker-compose.yml run --rm certbot certonly --webroot \
  -w /var/www/certbot \
  $([[ $STAGING != "0" ]] && echo "--staging") \
  $([[ -n $EMAIL ]] && echo "--email $EMAIL" || echo "--register-unsafely-without-email") \
  "${DOMAINS[@]}" \
  --rsa-key-size "$RSA_KEY_SIZE" \
  --agree-tos \
  --force-renewal

echo "### Reloading Nginx services ..."
docker compose -f docker-compose.yml exec nginx nginx -s reload
docker compose -f docker-compose.yml exec admin-frontend nginx -s reload