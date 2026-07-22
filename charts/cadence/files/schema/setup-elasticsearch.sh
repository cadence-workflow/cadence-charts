#!/bin/sh
set -e

echo "Starting ElasticSearch schema setup..."
echo "=== Installing ElasticSearch Schema ==="

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
    fi

    # Add authentication if user/password provided
    if [ -n "$ES_USER" ] && [ -n "$ES_PWD" ]; then
        CURL_OPTS="$CURL_OPTS -u $ES_USER:$ES_PWD"
    fi

    # Set global variables
    BASE_URL="$PROTOCOL://$ES_HOST:$ES_PORT"

    echo "Connecting to Elasticsearch at: $BASE_URL"
    echo "TLS Enabled: $TLS_ENABLED"
    if [ "$TLS_ENABLED" = "true" ]; then
        echo "Host Verification: $ENABLE_HOST_VERIFICATION"
        echo "Client Auth Required: $REQUIRE_CLIENT_AUTH"
    fi
}

# Initialize connection parameters
build_es_connection

# Determine schema file path based on ES version
case "$ES_VERSION" in
    "v6")
        SCHEMA_FILE="$CADENCE_HOME/schema/elasticsearch/v6/visibility/index_template.json"
        ;;
    "v7")
        SCHEMA_FILE="$CADENCE_HOME/schema/elasticsearch/v7/visibility/index_template.json"
        ;;
    *)
        echo "Error: Unsupported Elasticsearch version: $ES_VERSION"
        echo "Supported versions: v6, v7, v8 (in values should be v7)"
        exit 1
        ;;
esac

echo "Using schema file: $SCHEMA_FILE"
echo "Elasticsearch version: $ES_VERSION"

# Check if schema file exists
if [ ! -f "$SCHEMA_FILE" ]; then
    echo "Error: Schema file not found: $SCHEMA_FILE"
    echo "Available schema files:"
    find $CADENCE_HOME/schema/elasticsearch -name "*.json" -type f || echo "No schema files found"
    exit 1
fi

# Step 1: Install template
echo "Step 1: Installing Cadence visibility template..."
TEMPLATE_URL="$BASE_URL/_template/cadence-visibility-template"

echo "Uploading template to: $TEMPLATE_URL"
TEMPLATE_RESPONSE=$(curl $CURL_OPTS -s -w "%{http_code}" -X PUT "$TEMPLATE_URL" -H 'Content-Type: application/json' --data-binary "@$SCHEMA_FILE")
TEMPLATE_HTTP_CODE=$(echo "$TEMPLATE_RESPONSE" | tail -c 4)
TEMPLATE_BODY=$(echo "$TEMPLATE_RESPONSE" | head -c -4)

if [ "$TEMPLATE_HTTP_CODE" -eq 200 ] || [ "$TEMPLATE_HTTP_CODE" -eq 201 ]; then
    echo "✓ Template installed successfully"
    echo "Response: $TEMPLATE_BODY"
else
    echo "✗ Failed to install template. HTTP Code: $TEMPLATE_HTTP_CODE"
    echo "Response: $TEMPLATE_BODY"
    exit 1
fi

# Step 2: Create visibility index
echo "Step 2: Creating visibility index..."
INDEX_URL="$BASE_URL/$VISIBILITY_INDEX"

echo "Creating index: $INDEX_URL"
INDEX_RESPONSE=$(curl $CURL_OPTS -s -w "%{http_code}" -X PUT "$INDEX_URL")
INDEX_HTTP_CODE=$(echo "$INDEX_RESPONSE" | tail -c 4)
INDEX_BODY=$(echo "$INDEX_RESPONSE" | head -c -4)

if [ "$INDEX_HTTP_CODE" -eq 200 ] || [ "$INDEX_HTTP_CODE" -eq 201 ]; then
    echo "✓ Index created successfully"
    echo "Response: $INDEX_BODY"
elif [ "$INDEX_HTTP_CODE" -eq 400 ] && echo "$INDEX_BODY" | grep -q "resource_already_exists_exception"; then
    echo "✓ Index already exists"
    echo "Response: $INDEX_BODY"
else
    echo "✗ Failed to create index. HTTP Code: $INDEX_HTTP_CODE"
    echo "Response: $INDEX_BODY"
    exit 1
fi

# Step 3: Verify installation
echo "Step 3: Verifying installation..."

# Check template exists
echo "Checking template..."
TEMPLATE_CHECK=$(curl $CURL_OPTS -s -f "$TEMPLATE_URL")
if [ $? -eq 0 ]; then
    echo "✓ Template verification successful"
    if echo "$TEMPLATE_CHECK" | grep -q "cadence-visibility-template"; then
        echo "✓ Template structure is valid"
    fi
else
    echo "✗ Template verification failed"
    exit 1
fi

# Check index exists and is healthy
echo "Checking index..."
INDEX_CHECK=$(curl $CURL_OPTS -s -f "$INDEX_URL")
if [ $? -eq 0 ]; then
    echo "✓ Index verification successful"

    # Get index stats
    INDEX_STATS=$(curl $CURL_OPTS -s "$INDEX_URL/_stats")
    if [ $? -eq 0 ]; then
        echo "✓ Index is healthy and accessible"
        # Try to extract document count
        DOC_COUNT=$(echo "$INDEX_STATS" | grep -o '"count":[0-9]*' | head -1 | cut -d':' -f2)
        if [ -n "$DOC_COUNT" ]; then
            echo "  - Document count: $DOC_COUNT"
        fi
    fi
else
    echo "✗ Index verification failed"
    exit 1
fi

# Step 4: Version-specific validation
echo "Step 4: Performing version-specific validation..."
case "$ES_VERSION" in
    "v6")
        # Check ES6 document type mapping
        TYPE_URL="$BASE_URL/$VISIBILITY_INDEX/_mapping/_doc"
        TYPE_CHECK=$(curl $CURL_OPTS -s -f "$TYPE_URL")
        if [ $? -eq 0 ]; then
            echo "✓ ES6 document type mapping exists"
        else
            echo "✗ ES6 document type mapping check failed"
            exit 1
        fi
        ;;
    "v7")
        # Check ES7/8 index mapping
        MAPPING_URL="$BASE_URL/$VISIBILITY_INDEX/_mapping"
        MAPPING_CHECK=$(curl $CURL_OPTS -s -f "$MAPPING_URL")
        if [ $? -eq 0 ]; then
            echo "✓ ES7 index mapping exists"
        else
            echo "✗ ES7 index mapping check failed"
            exit 1
        fi
        ;;
esac

# Final summary
echo ""
echo "=== Elasticsearch Schema Installation Summary ==="
echo "Template: Installed ✓"
echo "Index: Created ✓"
echo "Mapping: Verified ✓"
echo "Version: $ES_VERSION"
echo "Schema File: $SCHEMA_FILE"
echo "==============================================="

echo "Elasticsearch schema installation completed successfully!"
