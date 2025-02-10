FROM nginx:latest

# Copy entrypoint script and make it executable
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Copy Nginx configuration templates
COPY templates/ /etc/nginx/templates/

# Copy SSL configuration files
COPY conf/ /etc/nginx/ssl/

# Set the entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]