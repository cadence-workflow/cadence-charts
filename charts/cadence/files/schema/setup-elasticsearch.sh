#!/bin/sh
set -e

echo "Starting ElasticSearch schema setup..."
echo "=== Installing ElasticSearch Schema ==="

# Source shared utilities from same directory as this script
. "$(dirname "$0")/elasticsearch-utils.sh"

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
    find "$CADENCE_HOME/schema/elasticsearch" -name "*.json" -type f || echo "No schema files found"
    exit 1
fi

# Step 1: Install template
echo "Step 1: Installing Cadence visibility template..."
TEMPLATE_URL="$BASE_URL/_template/cadence-visibility-template"

echo "Uploading template to: $TEMPLATE_URL"
# CURL_OPTS is intentionally unquoted - it's a space-separated string of options
# that must be word-split (e.g., "-k --cacert /path" becomes separate arguments).
# shellcheck disable=SC2086
TEMPLATE_RESPONSE=$(curl $CURL_OPTS -s -w "%{http_code}" -X PUT "$TEMPLATE_URL" -H 'Content-Type: application/json' --data-binary "@$SCHEMA_FILE")
TEMPLATE_HTTP_CODE=$(printf '%s' "$TEMPLATE_RESPONSE" | tail -c 3)
TEMPLATE_BODY=${TEMPLATE_RESPONSE%???}

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
# shellcheck disable=SC2086
INDEX_RESPONSE=$(curl $CURL_OPTS -s -w "%{http_code}" -X PUT "$INDEX_URL")
INDEX_HTTP_CODE=$(printf '%s' "$INDEX_RESPONSE" | tail -c 3)
INDEX_BODY=${INDEX_RESPONSE%???}

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
# shellcheck disable=SC2086
if TEMPLATE_CHECK=$(curl $CURL_OPTS -s -f "$TEMPLATE_URL"); then
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
# shellcheck disable=SC2086
if curl $CURL_OPTS -s -f "$INDEX_URL" > /dev/null; then
    echo "✓ Index verification successful"

    # Get index stats
    # shellcheck disable=SC2086
    if INDEX_STATS=$(curl $CURL_OPTS -s "$INDEX_URL/_stats"); then
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
        # shellcheck disable=SC2086
        if curl $CURL_OPTS -s -f "$TYPE_URL" > /dev/null; then
            echo "✓ ES6 document type mapping exists"
        else
            echo "✗ ES6 document type mapping check failed"
            exit 1
        fi
        ;;
    "v7")
        # Check ES7/8 index mapping
        MAPPING_URL="$BASE_URL/$VISIBILITY_INDEX/_mapping"
        # shellcheck disable=SC2086
        if curl $CURL_OPTS -s -f "$MAPPING_URL" > /dev/null; then
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

# Cleanup
cleanup_es_connection

echo "Elasticsearch schema installation completed successfully!"
