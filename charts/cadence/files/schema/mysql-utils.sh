#!/bin/sh
# Shared MySQL connection utilities

# Build MySQL command with connection parameters and TLS
build_mysql_cmd() {
  _cmd="mariadb -h $DB_HOST -P $DB_PORT -u $DB_USER"

  # Add password if provided (not using IAM auth)
  if [ -n "$MYSQL_PWD" ]; then
    _cmd="$_cmd -p$MYSQL_PWD"
  fi

  # Add SSL parameters if TLS is enabled
  if [ "$TLS_ENABLED" = "true" ]; then
    case "$SSL_MODE" in
      "disable"|"false")
        _cmd="$_cmd --skip-ssl"
        ;;
      "preferred")
        ;;
      "required"|"true"|"skip-verify")
        _cmd="$_cmd --ssl --skip-ssl-verify-server-cert"
        ;;
      "verify-ca")
        _cmd="$_cmd --ssl --ssl-verify-server-cert"
        ;;
      "verify-identity")
        _cmd="$_cmd --ssl --ssl-verify-server-cert"
        ;;
      *)
        _cmd="$_cmd --ssl"
        ;;
    esac

    # Add SSL certificate parameters if provided
    if [ -n "$SSL_CERTFILE" ]; then
      _cmd="$_cmd --ssl-ca=$SSL_CERTFILE"
    fi

    if [ -n "$SSL_CLIENT_CERT" ]; then
      _cmd="$_cmd --ssl-cert=$SSL_CLIENT_CERT"
    fi

    if [ -n "$SSL_CLIENT_KEY" ]; then
      _cmd="$_cmd --ssl-key=$SSL_CLIENT_KEY"
    fi
  else
    _cmd="$_cmd --skip-ssl"
  fi

  echo "$_cmd"
}

# Wait for MySQL to be ready
wait_mysql_ready() {
  echo "Waiting for MySQL to be ready..."
  echo "Connection details:"
  echo "  Host: $DB_HOST"
  echo "  Port: $DB_PORT"
  echo "  User: $DB_USER"
  echo "  Using password: $([ -n "$MYSQL_PWD" ] && echo 'yes' || echo 'no (IAM auth)')"
  echo "  TLS enabled: $TLS_ENABLED"
  echo ""

  until $(build_mysql_cmd) -e "SELECT 1" >/dev/null 2>&1; do
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] MySQL is not ready yet..."
    sleep 5
  done

  echo "MySQL is ready!"
}
