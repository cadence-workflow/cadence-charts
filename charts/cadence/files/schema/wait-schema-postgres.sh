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

# Set up PostgreSQL password
export PGPASSWORD="$POSTGRES_PWD"

# Build psql command with TLS options
build_psql_cmd() {
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
echo "Waiting for PostgreSQL to be ready..."
until pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USER; do
  echo 'PostgreSQL is not ready yet...'
  sleep 5
done
echo "PostgreSQL is ready!"

# Check schema versions in both databases
echo "Checking schema versions..."
until
  # Check main database schema version
  $(build_psql_cmd) -d $DB_NAME -t -c "
    SELECT curr_version FROM schema_version WHERE db_name = '$DB_NAME';" | grep -q "$DEFAULT_VERSION" &&

  # Check visibility database schema version (only if ES is not enabled)
  {
    if [ "$ES_ENABLED" = "false" ]; then
      $(build_psql_cmd) -d $DB_VISIBILITY_NAME -t -c "
        SELECT curr_version FROM schema_version WHERE db_name = '$DB_VISIBILITY_NAME';" | grep -q "$VISIBILITY_VERSION"
    else
      true
    fi
  }
do
  echo 'Waiting for PostgreSQL schema to be ready...'
  sleep 10
done

echo "PostgreSQL schema is ready!"
