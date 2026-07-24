#!/bin/sh
# Shared PostgreSQL connection utilities

# Build psql command with TLS options
build_psql_cmd() {
  export PGPASSWORD="$POSTGRES_PWD"
  _cmd="psql -h $DB_HOST -p $DB_PORT -U $DB_USER"

  # Add SSL mode if TLS is enabled
  if [ "$TLS_ENABLED" = "true" ] && [ -n "$SSL_MODE" ]; then
    _cmd="$_cmd --set=sslmode=$SSL_MODE"

    # Add SSL certificate parameters if provided
    if [ -n "$SSL_CERTFILE" ]; then
      _cmd="$_cmd --set=sslrootcert=$SSL_CERTFILE"
    fi

    if [ -n "$SSL_CLIENT_CERT" ]; then
      _cmd="$_cmd --set=sslcert=$SSL_CLIENT_CERT"
    fi

    if [ -n "$SSL_CLIENT_KEY" ]; then
      _cmd="$_cmd --set=sslkey=$SSL_CLIENT_KEY"
    fi
  fi

  echo "$_cmd"
}

# Wait for PostgreSQL to be ready
wait_postgres_ready() {
  echo "Waiting for PostgreSQL to be ready..."

  until $(build_psql_cmd) -d postgres -c "SELECT 1" >/dev/null 2>&1; do
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] PostgreSQL is not ready yet..."
    sleep 5
  done

  echo "PostgreSQL is ready!"
}
