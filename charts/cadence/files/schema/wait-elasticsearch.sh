#!/bin/sh
set -e

echo "Starting Elasticsearch readiness check..."

# Build Elasticsearch connection parameters
build_es_connection() {
    # Determine protocol - allow override from values or default based on TLS
    if [ -n "$ES_PROTOCOL" ]; then
        PROTOCOL="$ES_PROTOCOL"
    elif [ "$TLS_ENABLED" = "true" ]; then
        PROTOCOL="https"
    else
        PROTOCOL="http"
    fi

    # Build curl options for TLS
    CURL_OPTS=""
    if [ "$TLS_ENABLED" = "true" ]; then
        # Configure SSL verification based on host verification setting
        if [ "$ENABLE_HOST_VERIFICATION" = "false" ]; then
            CURL_OPTS="$CURL_OPTS -k"
        fi

        # Add CA certificate if provided
        if [ -n "$SSL_CA_FILE" ]; then
            CURL_OPTS="$CURL_OPTS --cacert $SSL_CA_FILE"
        fi

        # Add client certificate for mutual TLS if provided
        if [ -n "$SSL_CLIENT_CERT" ] && [ -n "$SSL_CLIENT_KEY" ]; then
            CURL_OPTS="$CURL_OPTS --cert $SSL_CLIENT_CERT --key $SSL_CLIENT_KEY"
        fi

        # Override server name if specified
        if [ -n "$SSL_SERVER_NAME" ]; then
            CURL_OPTS="$CURL_OPTS --resolve $SSL_SERVER_NAME:$ES_PORT:$ES_HOST"
        fi

        # Additional TLS options
        if [ "$REQUIRE_CLIENT_AUTH" = "true" ]; then
            # Client auth is required, ensure we have client cert
            if [ -z "$SSL_CLIENT_CERT" ] || [ -z "$SSL_CLIENT_KEY" ]; then
                echo "Error: Client authentication required but client certificate/key not provided"
                exit 1
            fi
        fi
    fi

    # Add authentication if user/password provided
    if [ -n "$ES_USER" ] && [ -n "$ES_PWD" ]; then
        # Use netrc to avoid exposing password in process list
        NETRC_FILE=$(mktemp)
        chmod 600 "$NETRC_FILE"
        cat > "$NETRC_FILE" << EOF
machine $ES_HOST
login $ES_USER
password $ES_PWD
EOF
        CURL_OPTS="$CURL_OPTS --netrc-file $NETRC_FILE"
    fi

    # Set base URL using SSL_SERVER_NAME if provided (for SNI), otherwise ES_HOST
    if [ -n "$SSL_SERVER_NAME" ]; then
        BASE_URL="$PROTOCOL://$SSL_SERVER_NAME:$ES_PORT"
    else
        BASE_URL="$PROTOCOL://$ES_HOST:$ES_PORT"
    fi

    echo "Connecting to Elasticsearch at: $BASE_URL"
    echo "TLS Enabled: $TLS_ENABLED"
    if [ "$TLS_ENABLED" = "true" ]; then
        echo "Host Verification: $ENABLE_HOST_VERIFICATION"
        echo "Client Auth Required: $REQUIRE_CLIENT_AUTH"
    fi
}

# Wait for Elasticsearch to be ready
echo "Waiting for Elasticsearch to be ready..."
build_es_connection

# Check Elasticsearch health
until curl $CURL_OPTS -s -f "$BASE_URL/_cluster/health?wait_for_status=yellow&timeout=5s" > /dev/null; do
    echo "Elasticsearch is not ready yet..."
    sleep 10
done

# Cleanup netrc file if created
if [ -n "$NETRC_FILE" ]; then
    rm -f "$NETRC_FILE"
fi

echo "Elasticsearch is ready!"
