FROM owasp/modsecurity-crs:nginx

# Copy entrypoint script and make it executable
COPY docker-entrypoint.sh /docker-entrypoint.sh

# Switch to root user to change permissions
USER root
RUN chmod +x /docker-entrypoint.sh

# Create directory for pid file and set proper permissions
RUN mkdir -p /var/run/nginx && \
    chown -R nginx:nginx /var/run/nginx && \
    chmod 755 /var/run/nginx

# Copy Nginx configuration templates
COPY templates/ /etc/nginx/templates/

# Copy SSL configuration files
COPY ssl/ /etc/nginx/ssl/

# Set the entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]

# Switch back to the nginx user
USER nginx
