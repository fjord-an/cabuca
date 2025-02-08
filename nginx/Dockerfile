FROM nginx:alpine
ENV DOMAIN_NAME cabooltureregionuc.org.au   # Default value; can be overridden

# Copy the template into the image
COPY nginx.conf.template /etc/nginx/templates/nginx.conf.template

# Use an entrypoint script to substitute environment variables and start Nginx
CMD ["sh", "-c", "envsubst '$DOMAIN_NAME' < /etc/nginx/templates/nginx.conf.template > /etc/nginx/conf.d/default.conf && exec nginx -g 'daemon off;'"]