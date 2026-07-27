#!/bin/sh
# Shared Cassandra connection utilities

# Build cqlshrc configuration file
build_cqlshrc() {
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
}

# Build cqlsh command
build_cqlsh_cmd() {
  _cmd="cqlsh"

  # Add SSL option if enabled
  if [ "$TLS_ENABLED" = "true" ]; then
    _cmd="$_cmd --ssl"
  fi

  echo "$_cmd"
}

# Wait for Cassandra to be ready
wait_cassandra_ready() {
  echo "Waiting for Cassandra to be ready..."
  build_cqlshrc

  until $(build_cqlsh_cmd) -e "SELECT now() FROM system.local;"; do
    echo "Cassandra is not ready yet..."
    sleep 5
  done

  echo "Cassandra is ready!"
}
