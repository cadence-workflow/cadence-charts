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

# Build connection string based on TLS configuration
build_mysql_cmd() {
  _cmd="mariadb -h $DB_HOST -P $DB_PORT -u $DB_USER"

  # Add SSL parameters if TLS is enabled
  if [ "$TLS_ENABLED" = "true" ]; then
    case "$SSL_MODE" in
      "disable"|"false")
        _cmd="$_cmd --skip-ssl"
        ;;
      "preferred")
        ;;
      "required"|"true"|"skip-verify")
        _cmd="$_cmd --ssl --ssl-verify-server-cert=false"
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
  fi

  echo "$_cmd"
}

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
if [ -n "$MYSQL_PWD" ]; then
  until mariadb-admin ping -h $DB_HOST -P $DB_PORT -u $DB_USER --password=$MYSQL_PWD --skip-ssl --silent; do
    echo 'MySQL is not ready yet...'
    sleep 5
  done
else
  until mariadb-admin ping -h $DB_HOST -P $DB_PORT -u $DB_USER --skip-ssl --silent; do
    echo 'MySQL is not ready yet...'
    sleep 5
  done
fi
echo "MySQL is ready!"

# Check schema versions in both databases
echo "Checking schema versions..."
until
  # Check main database schema version
  $(build_mysql_cmd) -D $DB_NAME -e "
    SELECT curr_version FROM schema_version WHERE db_name = '$DB_NAME';" | grep -q "$DEFAULT_VERSION" &&

  # Check visibility database schema version (only if ES is not enabled)
  {
    if [ "$ES_ENABLED" = "false" ]; then
      $(build_mysql_cmd) -D $DB_VISIBILITY_NAME -e "
        SELECT curr_version FROM schema_version WHERE db_name = '$DB_VISIBILITY_NAME';" | grep -q "$VISIBILITY_VERSION"
    else
      true
    fi
  }
do
  echo 'Waiting for MySQL schema to be ready...'
  sleep 10
done

echo "MySQL schema is ready!"
