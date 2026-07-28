#!/bin/sh
set -e

echo "Starting Cadence schema setup for Cassandra"
echo "=== Setting up Cassandra Schema ==="

# Build cassandra-tool command with TLS options
build_cassandra_cmd() {
  _cmd="cadence-cassandra-tool --ep $DB_HOST"

  # Add authentication
  if [ -n "$DB_USER" ]; then
    _cmd="$_cmd -u $DB_USER"
  fi
  if [ -n "$CASSANDRA_PASSWORD" ]; then
    _cmd="$_cmd -pw $CASSANDRA_PASSWORD"
  fi

  # Add protocol version
  _cmd="$_cmd -pv $PROTOCOL_VERSION"

  # Add allowed authenticators from environment variable
  if [ -n "$ALLOWED_AUTHENTICATORS" ]; then
    _cmd="$_cmd $ALLOWED_AUTHENTICATORS"
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

# Setup main database schema
echo "Creating main keyspace: $DB_NAME"
if [ "$DATA_CENTER" = "" ]; then
  if ! $(build_cassandra_cmd) create -k "$DB_NAME" --rf "$REPLICATION_FACTOR"; then
    if $(build_cassandra_cmd) -e "DESCRIBE KEYSPACE $DB_NAME;"; then
      echo "Keyspace $DB_NAME already exists, continuing..."
    else
      echo "ERROR: Failed to create keyspace $DB_NAME"
      exit 1
    fi
  fi
else
  if ! $(build_cassandra_cmd) create -k "$DB_NAME" --rf "$REPLICATION_FACTOR" -dc "$DATA_CENTER"; then
    if $(build_cassandra_cmd) -e "DESCRIBE KEYSPACE $DB_NAME;"; then
      echo "Keyspace $DB_NAME already exists, continuing..."
    else
      echo "ERROR: Failed to create keyspace $DB_NAME"
      exit 1
    fi
  fi
fi

echo "Setting up main schema version 0.0"
$(build_cassandra_cmd) -k "$DB_NAME" setup-schema -v 0.0 || echo "Schema 0.0 already exists"

echo "Updating main schema to latest version"
$(build_cassandra_cmd) -k "$DB_NAME" update-schema -d "$CADENCE_HOME/schema/cassandra/cadence/versioned" || echo "Rollback is not allowed"

# Setup visibility database schema (only if ES is not enabled)
if [ "$ES_ENABLED" = "false" ]; then
  echo "Creating visibility keyspace: $DB_VISIBILITY_NAME"
  if [ "$DATA_CENTER" = "" ]; then
    if ! $(build_cassandra_cmd) create -k "$DB_VISIBILITY_NAME" --rf "$REPLICATION_FACTOR"; then
      if $(build_cassandra_cmd) -e "DESCRIBE KEYSPACE $DB_VISIBILITY_NAME;"; then
        echo "Keyspace $DB_VISIBILITY_NAME already exists, continuing..."
      else
        echo "ERROR: Failed to create keyspace $DB_VISIBILITY_NAME"
        exit 1
      fi
    fi
  else
    if ! $(build_cassandra_cmd) create -k "$DB_VISIBILITY_NAME" --rf "$REPLICATION_FACTOR" -dc "$DATA_CENTER"; then
      if $(build_cassandra_cmd) -e "DESCRIBE KEYSPACE $DB_VISIBILITY_NAME;"; then
        echo "Keyspace $DB_VISIBILITY_NAME already exists, continuing..."
      else
        echo "ERROR: Failed to create keyspace $DB_VISIBILITY_NAME"
        exit 1
      fi
    fi
  fi

  echo "Setting up visibility schema version 0.0"
  $(build_cassandra_cmd) -k "$DB_VISIBILITY_NAME" setup-schema -v 0.0 || echo "Schema 0.0 already exists"

  echo "Updating visibility schema to latest version"
  $(build_cassandra_cmd) -k "$DB_VISIBILITY_NAME" update-schema -d "$CADENCE_HOME/schema/cassandra/visibility/versioned" || echo "Rollback is not allowed"
else
  echo "Skipping visibility schema setup (Elasticsearch enabled)"
fi

echo "Schema setup completed successfully!"
