#!/bin/sh
set -e

echo "Starting Cadence schema setup for PostgreSQL"
echo "=== Setting up PostgreSQL Schema ==="

# Build sql-tool command with TLS options
build_postgres_cmd() {
  _cmd="cadence-sql-tool --ep $DB_HOST -p $DB_PORT -u $DB_USER --plugin postgres"

  # Add password only if provided (not using IAM auth)
  if [ -n "$POSTGRES_PWD" ]; then
    _cmd="$_cmd -pw $POSTGRES_PWD"
  fi

  # Add TLS options if enabled
  if [ "$TLS_ENABLED" = "true" ]; then
    _cmd="$_cmd --tls"
    if [ -n "$SSL_CERTFILE" ]; then
      _cmd="$_cmd --tls-ca-file $SSL_CERTFILE"
    fi
    if [ -n "$SSL_CLIENT_CERT" ]; then
      _cmd="$_cmd --tls-cert-file $SSL_CLIENT_CERT"
    fi
    if [ -n "$SSL_CLIENT_KEY" ]; then
      _cmd="$_cmd --tls-key-file $SSL_CLIENT_KEY"
    fi
  fi

  echo "$_cmd"
}

# Create main database
echo "Creating main database: $DB_NAME"
$(build_postgres_cmd) create-database --db $DB_NAME || echo "Database $DB_NAME already exists"

echo "Setting up main schema version 0.0"
$(build_postgres_cmd) --db $DB_NAME setup-schema -v 0.0 || echo "Schema 0.0 already exists"

echo "Updating main schema to latest version"
$(build_postgres_cmd) --db $DB_NAME update-schema -d $CADENCE_HOME/schema/postgres/cadence/versioned || echo "Rollback is not allowed"

# Setup visibility database (only if ES is not enabled)
if [ "$ES_ENABLED" = "false" ]; then
  echo "Creating visibility database: $DB_VISIBILITY_NAME"
  $(build_postgres_cmd) create-database --db $DB_VISIBILITY_NAME || echo "Database $DB_VISIBILITY_NAME already exists"

  echo "Setting up visibility schema version 0.0"
  $(build_postgres_cmd) --db $DB_VISIBILITY_NAME setup-schema -v 0.0 || echo "Schema 0.0 already exists"

  echo "Updating visibility schema to latest version"
  $(build_postgres_cmd) --db $DB_VISIBILITY_NAME update-schema -d $CADENCE_HOME/schema/postgres/visibility/versioned || echo "Rollback is not allowed"
else
  echo "Skipping visibility schema setup (Elasticsearch enabled)"
fi

echo "Schema setup completed successfully!"
