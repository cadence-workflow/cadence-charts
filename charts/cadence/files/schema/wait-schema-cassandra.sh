#!/bin/sh
set -e

# Wait for versions file from extract-schema-version init container
while [ ! -f /shared/schema-versions.env ]; do
  echo "Waiting for schema versions file..."
  sleep 2
done

# Load extracted versions
# shellcheck disable=SC2046
export $(cat /shared/schema-versions.env | xargs)
echo "Using extracted versions:"
echo "  DEFAULT_VERSION=$DEFAULT_VERSION"
echo "  VISIBILITY_VERSION=$VISIBILITY_VERSION"

# Create .cassandra directory for cqlshrc if it doesn't exist
mkdir -p ~/.cassandra

# Build cqlshrc configuration file
cat > ~/.cassandra/cqlshrc << EOF
[connection]
hostname = $DB_HOST
port = $DB_PORT

EOF

# Add authentication section if user is provided
if [ -n "$DB_USER" ] && [ "$DB_USER" != "" ]; then
  cat >> ~/.cassandra/cqlshrc << EOF
[authentication]
username = $DB_USER
EOF
  # Add password if provided
  if [ -n "$CASSANDRA_PASSWORD" ] && [ "$CASSANDRA_PASSWORD" != "" ]; then
    cat >> ~/.cassandra/cqlshrc << EOF
password = $CASSANDRA_PASSWORD
EOF
  fi
fi

# Add SSL configuration if enabled
if [ "$TLS_ENABLED" = "true" ]; then
  cat >> ~/.cassandra/cqlshrc << EOF

[ssl]
EOF
  # Add certificate file if specified (CA certificate)
  if [ -n "$SSL_CERTFILE" ] && [ "$SSL_CERTFILE" != "" ]; then
    cat >> ~/.cassandra/cqlshrc << EOF
certfile = $SSL_CERTFILE
EOF
  fi

  # Add client certificate for mutual TLS
  if [ -n "$SSL_CLIENT_CERT" ] && [ "$SSL_CLIENT_CERT" != "" ]; then
    cat >> ~/.cassandra/cqlshrc << EOF
usercert = $SSL_CLIENT_CERT
EOF
  fi

  # Add client private key for mutual TLS
  if [ -n "$SSL_CLIENT_KEY" ] && [ "$SSL_CLIENT_KEY" != "" ]; then
    cat >> ~/.cassandra/cqlshrc << EOF
userkey = $SSL_CLIENT_KEY
EOF
  fi

  # Add validate setting
  if [ -n "$SSL_VALIDATE" ] && [ "$SSL_VALIDATE" != "" ]; then
    cat >> ~/.cassandra/cqlshrc << EOF
validate = $SSL_VALIDATE
EOF
  else
    cat >> ~/.cassandra/cqlshrc << EOF
validate = true
EOF
  fi
fi

# Build cqlsh command
build_cqlsh_cmd() {
  _cmd="cqlsh"

  # Add SSL option if enabled
  if [ "$TLS_ENABLED" = "true" ]; then
    _cmd="$_cmd --ssl"
  fi

  echo "$_cmd"
}

# Check schema versions
echo "Checking Cassandra schema versions..."
until $(build_cqlsh_cmd) -e "
  USE $DB_NAME;
  SELECT curr_version FROM schema_version WHERE keyspace_name = '$DB_NAME';" | grep -q "$DEFAULT_VERSION" &&
  {
    if [ "$ES_ENABLED" = "false" ]; then
      $(build_cqlsh_cmd) -e "
        USE $DB_VISIBILITY_NAME;
        SELECT curr_version FROM schema_version WHERE keyspace_name = '$DB_VISIBILITY_NAME';" | grep -q "$VISIBILITY_VERSION"
    else
      true
    fi
  }
do
  echo 'Waiting for Cassandra schema to be ready...'
  sleep 10
done

echo "Cassandra schema is ready!"
