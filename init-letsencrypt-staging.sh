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
DOMAINS=("${DOMAIN_NAME}" "${ADMIN_DOMAIN_NAME}")
EMAIL="${EMAIL:-your-email@example.com}"
RSA_KEY_SIZE="${RSA_KEY_SIZE:-4096}"
STAGING="${STAGING:-0}"
DATA_PATH="${DATA_PATH:-./certbot}"

echo "### Creating directories for SSL certificates and keys ..."
mkdir -p "$DATA_PATH/www"
mkdir -p "$DATA_PATH/conf"

echo "### Starting Nginx and admin-frontend ..."
docker compose -f docker-compose.yml up --force-recreate -d nginx admin-frontend

# # Delete existing certificates for each domain
# for domain in "${DOMAINS[@]}"; do
#     echo "### Deleting existing certificates for $domain (if they exist) ..."
#     docker compose -f docker-compose.yml run --rm certbot sh -c 'rm -Rf /etc/letsencrypt/live/'"$domain"' /etc/letsencrypt/archive/'"$domain"' /etc/letsencrypt/renewal/'"$domain"'.conf || true'
# done

# Prepare domain arguments for Certbot
DOMAIN_ARGS=""
for domain in "${DOMAINS[@]}"; do
    echo "### Requesting Let's Encrypt certificate for $domain ..."
    DOMAIN_ARGS="$DOMAIN_ARGS -d $domain"
done

# Prepare email argument
if [ -n "$EMAIL" ]; then
    EMAIL_ARG="--email $EMAIL"
else
    EMAIL_ARG="--register-unsafely-without-email"
fi

# Prepare staging argument
if [ "$STAGING" != "0" ]; then
    echo "### Using staging environment ..."
    STAGING_ARG="--staging"
else
    STAGING_ARG=""
fi

echo "### Requesting Let's Encrypt certificate for domains: ${DOMAINS[@]} ..."


# Run Certbot to obtain certificates
docker compose -f docker-compose.yml run --rm certbot certonly --webroot \
    -w /var/www/certbot \
    $STAGING_ARG \
    $EMAIL_ARG \
    $DOMAIN_ARGS \
    --rsa-key-size "$RSA_KEY_SIZE" \
    --agree-tos \
    --force-renewal

echo "### Reloading Nginx ..."
docker compose -f docker-compose.yml exec nginx nginx -s reload