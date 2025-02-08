# backend/CabUCA.API/init-letsencrypt.sh
#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Check if docker-compose is installed.
if ! [ -x "$(command -v docker-compose)" ]; then
  echo 'Error: docker-compose is not installed.' >&2
  exit 1
fi

# ------ Configuration via Environment Variables ------

# DOMAIN_NAMES: Comma-separated list of domains (e.g., "example.com,www.example.com").
# If not set, it defaults to "cabooltureregionuc.org.au".
DOMAIN_NAMES="${DOMAIN_NAMES:-cabooltureregionuc.org.au}"

# EMAIL: Email address to be used for Let's Encrypt registration.
EMAIL="${EMAIL:-your-email@example.com}"

# RSA_KEY_SIZE: Size for the RSA key.
RSA_KEY_SIZE="${RSA_KEY_SIZE:-4096}"

# STAGING: Set to "1" for testing (staging API), "0" for production.
STAGING="${STAGING:-0}"

# DATA_PATH: Directory for Certbot data.
DATA_PATH="./certbot"

# -------------------------------------------------------

# Convert DOMAIN_NAMES into an array by splitting on commas.
IFS=',' read -r -a domains <<< "$DOMAIN_NAMES"

echo "Using the following domains: ${domains[@]}"
echo "Using email: $EMAIL"
echo "RSA key size: $RSA_KEY_SIZE"
echo "Staging mode: $STAGING"

echo "### Creating directories for SSL certificates and keys ..."
mkdir -p "$DATA_PATH/www"
for domain in "${domains[@]}"; do
    mkdir -p "$DATA_PATH/conf/live/$domain"
done

echo "### Starting Nginx ..."
docker-compose -f docker-compose.prod.yml up --force-recreate -d nginx

for domain in "${domains[@]}"; do
    echo "### Deleting dummy certificate for $domain (if it exists) ..."
    docker-compose -f docker-compose.prod.yml run --rm certbot \
        rm -Rf /etc/letsencrypt/live/$domain \
               /etc/letsencrypt/archive/$domain \
               /etc/letsencrypt/renewal/$domain.conf
done

DOMAIN_ARGS=""
for domain in "${domains[@]}"; do
    DOMAIN_ARGS="$DOMAIN_ARGS -d $domain"
done

EMAIL_ARG="--email $EMAIL"  # Use --register-unsafely-without-email if no email is provided.
STAGING_ARG=""
if [ "$STAGING" != "0" ]; then
    STAGING_ARG="--staging"
fi

echo "### Requesting Let's Encrypt certificate for domains: ${domains[@]} ..."
docker-compose -f docker-compose.prod.yml run --rm certbot certonly --webroot \
    -w /var/www/certbot \
    $STAGING_ARG \
    $EMAIL_ARG \
    $DOMAIN_ARGS \
    --rsa-key-size $RSA_KEY_SIZE \
    --agree-tos \
    --force-renewal

echo "### Reloading Nginx ..."
docker-compose -f docker-compose.prod.yml exec nginx nginx -s reload