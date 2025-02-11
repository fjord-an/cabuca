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
DOMAINS=("-d ${DOMAIN_NAME}" "-d ${ADMIN_DOMAIN_NAME}")
EMAIL="${EMAIL:-your-email@example.com}"
RSA_KEY_SIZE="${RSA_KEY_SIZE:-4096}"
STAGING="${STAGING:-0}"
DATA_PATH="${DATA_PATH:-./certbot}"

echo "### Creating directories for SSL certificates and keys ..."
mkdir -p "$DATA_PATH/www"
mkdir -p "$DATA_PATH/conf"

echo "### Starting Nginx and admin-frontend ..."
docker compose -f docker-compose.yml up --force-recreate -d nginx admin-frontend

for domain in "${DOMAIN_NAME}" "${ADMIN_DOMAIN_NAME}"; do
    echo "### Deleting dummy certificate for $domain (if it exists) ..."
    docker compose -f docker-compose.yml run --rm certbot \
        rm -Rf /etc/letsencrypt/live/$domain \
               /etc/letsencrypt/archive/$domain \
               /etc/letsencrypt/renewal/$domain.conf
done

DOMAIN_ARGS=""
for domain in "${DOMAIN_NAME}" "${ADMIN_DOMAIN_NAME}"; do
    DOMAIN_ARGS="$DOMAIN_ARGS -d $domain"
done

EMAIL_ARG="--email $EMAIL"  # Use --register-unsafely-without-email if no email is provided.
STAGING_ARG=""
if [ "$STAGING" != "0" ]; then
    STAGING_ARG="--staging"
fi

echo "### Requesting Let's Encrypt certificates for domains: ${DOMAIN_NAME}, ${ADMIN_DOMAIN_NAME} ..."
docker compose -f docker-compose.yml run --rm certbot certonly --webroot \
  -w /var/www/certbot \
  $STAGING_ARG \
  $EMAIL_ARG \
  $DOMAIN_ARGS \
  --rsa-key-size "$RSA_KEY_SIZE" \
  --agree-tos \
  --force-renewal

echo "### Reloading Nginx..."
docker compose -f docker-compose.yml exec nginx nginx -s reload
docker compose -f docker-compose.yml exec admin-frontend nginx -s reload