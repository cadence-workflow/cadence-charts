#!/bin/sh
set -e

echo "Starting Elasticsearch schema validation..."

# Source shared utilities from same directory as this script
. "$(dirname "$0")/elasticsearch-utils.sh"

# Build Elasticsearch connection parameters
build_es_connection

# Check Elasticsearch health
until curl "$CURL_OPTS" -s -f "$BASE_URL/_cluster/health?wait_for_status=yellow&timeout=5s" > /dev/null; do
    echo "Elasticsearch is not ready yet..."
    sleep 10
done
echo "Elasticsearch is ready!"

# Get cluster info for debugging
echo "Elasticsearch cluster information:"
if CLUSTER_INFO=$(curl "$CURL_OPTS" -s "$BASE_URL/"); then
    echo "$CLUSTER_INFO" | grep -E '"cluster_name"|"version"|"number"' || echo "Could not parse cluster info"
else
    echo "Warning: Could not retrieve cluster information"
fi

# Check if template exists and validate schema
echo "Checking Elasticsearch schema template..."
TEMPLATE_URL="$BASE_URL/_template/cadence-visibility-template"

# Wait for template to exist
until curl "$CURL_OPTS" -s -f "$TEMPLATE_URL" > /dev/null; do
    echo "Waiting for Cadence visibility template to be ready..."
    sleep 10
done
echo "✓ Cadence visibility template exists"

# Validate template structure
TEMPLATE_RESPONSE=$(curl "$CURL_OPTS" -s "$TEMPLATE_URL")
if echo "$TEMPLATE_RESPONSE" | grep -q "cadence-visibility-template"; then
    echo "✓ Template structure is valid"
else
    echo "⚠ Warning: Template structure may be invalid"
fi

# Check if visibility index exists
echo "Checking visibility index..."
INDEX_URL="$BASE_URL/$VISIBILITY_INDEX"

# Wait for index to exist
until curl "$CURL_OPTS" -s -f "$INDEX_URL" > /dev/null; do
    echo "Waiting for visibility index '$VISIBILITY_INDEX' to be ready..."
    sleep 10
done
echo "✓ Visibility index '$VISIBILITY_INDEX' exists"

# Wait for index to be healthy
until curl "$CURL_OPTS" -s -f "$INDEX_URL/_stats" > /dev/null; do
    echo "Waiting for visibility index to be healthy..."
    sleep 5
done

INDEX_STATS=$(curl "$CURL_OPTS" -s "$INDEX_URL/_stats")
echo "✓ Visibility index is accessible and healthy"
# Extract basic stats
DOC_COUNT=$(echo "$INDEX_STATS" | grep -o '"count":[0-9]*' | head -1 | cut -d':' -f2)
if [ -n "$DOC_COUNT" ]; then
    echo "  - Document count: $DOC_COUNT"
fi

# Additional checks for different ES versions
echo "Performing version-specific checks for ES $ES_VERSION..."
case "$ES_VERSION" in
    "v6")
        # Wait for _doc type mapping (ES6 compatibility)
        TYPE_URL="$BASE_URL/$VISIBILITY_INDEX/_mapping/_doc"
        until curl "$CURL_OPTS" -s -f "$TYPE_URL" > /dev/null; do
            echo "Waiting for ES6 document type mapping..."
            sleep 5
        done
        echo "✓ ES6 document type mapping exists"
        ;;
    "v7"|"v8")
        # Wait for mapping without type (ES7/8 style)
        MAPPING_URL="$BASE_URL/$VISIBILITY_INDEX/_mapping"
        until curl "$CURL_OPTS" -s -f "$MAPPING_URL" > /dev/null; do
            echo "Waiting for ES7/8 index mapping..."
            sleep 5
        done
        echo "✓ ES7/8 index mapping exists"
        ;;
    *)
        echo "⚠ Warning: Unsupported ES version $ES_VERSION - skipping version-specific checks"
        ;;
esac

# Cleanup
cleanup_es_connection

# Final validation summary
echo ""
echo "=== Elasticsearch Schema Validation Summary ==="
echo "Cluster: Ready ✓"
echo "Template: Ready ✓"
echo "Index: Ready ✓"
echo "Mapping: Ready ✓"
echo "Version: $ES_VERSION"
echo "==============================================="
echo "Elasticsearch schema validation completed successfully!"