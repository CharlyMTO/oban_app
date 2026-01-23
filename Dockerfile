# Use the official PostgreSQL image as the base
FROM postgres:17

# Set environment variables
ENV POSTGRES_USER=root
ENV POSTGRES_PASSWORD=mypassword
ENV POSTGRES_DB=mydatabase

# Copy custom initialization scripts (optional)
#COPY init.sql /docker-entrypoint-initdb.d/

# Optional: Copy custom configuration file
#COPY postgresql.conf /etc/postgresql/main/

# Expose the default PostgreSQL port
EXPOSE 5432

# The container will start PostgreSQL automatically
# No need for CMD unless you want to override the default   