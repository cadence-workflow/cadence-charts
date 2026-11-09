#!/bin/sh
# Shared PostgreSQL connection utilities

# Setup PostgreSQL environment
setup_postgres_env() {
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
}

# Build psql command
build_psql_cmd() {
  _cmd="psql -h $DB_HOST -p $DB_PORT -U $DB_USER"
  echo "$_cmd"
}

# Wait for PostgreSQL to be ready
wait_postgres_ready() {
  echo "Waiting for PostgreSQL to be ready..."
  setup_postgres_env

  until psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "SELECT 1"; do
    echo "PostgreSQL is not ready yet..."
    sleep 5
  done

  echo "PostgreSQL is ready!"
}

# setup-schema resets schema_version to 0.0 on every run, so mark databases
# that are already versioned and let the schema Job skip it for them.
mark_if_versioned() {
  _db=$1

  _dbExists=$($(build_psql_cmd) -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$_db'")
  if [ "$_dbExists" != "1" ]; then
    echo "Database $_db does not exist yet"
    return 0
  fi

  _hasTable=$($(build_psql_cmd) -d "$_db" -tAc "SELECT to_regclass('schema_version') IS NOT NULL")
  if [ "$_hasTable" != "t" ]; then
    echo "Database $_db has no schema_version table yet"
    return 0
  fi

  _hasRow=$($(build_psql_cmd) -d "$_db" -tAc "SELECT 1 FROM schema_version WHERE db_name = '$_db'")
  if [ "$_hasRow" = "1" ]; then
    echo "Database $_db is already versioned"
    touch "/schema-state/$_db.versioned"
  fi
}
