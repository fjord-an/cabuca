# backend/CabUCA.API/init-letsencrypt.sh
#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Check if docker-compose is installed.
if ! [ -x "$(command -v docker-compose)" ]; then
  echo 'Error: docker-compose is not installed.' >&2
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
DOMAIN_NAMES="${DOMAIN_NAME}"
EMAIL="${EMAIL:-your-email@example.com}"
RSA_KEY_SIZE="${RSA_KEY_SIZE:-4096}"
STAGING="${STAGING:-0}"
DATA_PATH="${DATA_PATH:-./certbot}"

# Convert DOMAIN_NAMES into an array by splitting on commas.
IFS=',' read -r -a domains <<< "$DOMAIN_NAMES"

echo "Using the following domains: ${domains[@]}"
echo "Using email: $EMAIL"
echo "RSA key size: $RSA_KEY_SIZE"
echo "Staging mode: $STAGING"

echo "### Creating directories for SSL certificates and keys ..."
mkdir -p "$DATA_PATH/www"
mkdir -p "$DATA_PATH/conf"

echo "### Starting Nginx ..."
docker-compose up --force-recreate -d nginx

echo "### Requesting Let's Encrypt certificate for domains: ${domains[@]} ..."
docker-compose run --rm certbot certonly --webroot \
  -w /var/www/certbot \
  $([[ $STAGING != "0" ]] && echo "--staging") \
  $([[ -n $EMAIL ]] && echo "--email $EMAIL" || echo "--register-unsafely-without-email") \
  $(printf -- ' -d %s' "${domains[@]}") \
  --rsa-key-size $RSA_KEY_SIZE \
  --agree-tos \
  --force-renewal

echo "### Reloading Nginx ..."
docker-compose exec nginx nginx -s reload