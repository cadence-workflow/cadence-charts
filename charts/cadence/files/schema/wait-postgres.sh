#!/bin/sh
set -e

echo "Waiting for PostgreSQL to be ready..."

# Set up PostgreSQL environment variables
export PGPASSWORD="$POSTGRES_PWD"

# Add SSL mode if TLS is enabled
if [ "$TLS_ENABLED" = "true" ] && [ -n "$SSL_MODE" ]; then
  # Set SSL mode as environment variable (psql reads PGSSLMODE)
  export PGSSLMODE="$SSL_MODE"

  # Add SSL certificate parameters as environment variables if provided
  if [ -n "$SSL_CERTFILE" ]; then
    export PGSSLROOTCERT="$SSL_CERTFILE"
  fi

  if [ -n "$SSL_CLIENT_CERT" ]; then
    export PGSSLCERT="$SSL_CLIENT_CERT"
  fi

  if [ -n "$SSL_CLIENT_KEY" ]; then
    export PGSSLKEY="$SSL_CLIENT_KEY"
  fi
else
  # Disable SSL if TLS is not enabled
  export PGSSLMODE="disable"
fi

# Wait for PostgreSQL to be ready with authentication and TLS
until psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "SELECT 1" >/dev/null 2>&1; do
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] PostgreSQL is not ready yet..."
  sleep 5
done

echo "PostgreSQL is ready!"
