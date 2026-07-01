#!/bin/bash
# Simple deployment script for Cadence with Cloud SQL Proxy or direct connection

set -e

# Default values
AUTO_IAM_AUTHN="false"
DIRECT_CONNECTION="false"
PASSWORD=""
DB_USER=""
DB_HOST=""
DB_PORT="3306"
CHART_PATH="./"
VALUES_FILE=""
DRY_RUN="false"

# Function to show usage
usage() {
    cat << EOF
Usage: $0 -r <release-name> -n <namespace> [CONNECTION OPTIONS] [AUTH OPTIONS]

Required arguments:
  -r, --release-name NAME        Helm release name
  -n, --namespace NAMESPACE      Kubernetes namespace

Connection options (choose one):
  Cloud SQL Proxy (default):
    -g, --gcp-sa EMAIL            GCP Service Account email
    -i, --instance CONNECTION     Cloud SQL instance connection (format: project:region:instance)
    --auto-iam-authn              Enable Cloud SQL IAM authentication

  Direct connection:
    --direct-connection           Use direct database connection (no Cloud SQL Proxy)
    -H, --hostname HOST          Database hostname or IP address
    -P, --port PORT              Database port (default: 3306)

Authentication options:
  -u, --db-user USER            Database username (required for built-in auth, auto-extracted for IAM auth)
  -p, --password PASSWORD       Database password (for built-in auth only)

Other options:
  -c, --chart-path PATH         Path to Helm chart (default: ./)
  -v, --values-file FILE        Values file (default: auto-selected based on connection type)
                                  - Direct connection: examples/values.mysql.yaml
                                  - Cloud SQL Proxy: examples/values.mysql-cloudsql.yaml
  --dry-run                     Print the Helm command without executing it
  -h, --help                    Show this help message

Examples:
  # Cloud SQL Proxy with IAM authentication
  $0 -r cadence -n my-namespace -g cadence@project.iam.gserviceaccount.com -i project:region:instance --auto-iam-authn

  # Cloud SQL Proxy with built-in authentication
  $0 -r cadence -n my-namespace -g cadence@project.iam.gserviceaccount.com -i project:region:instance -u myuser -p mypassword

  # Direct connection with built-in authentication
  $0 -r cadence -n my-namespace --direct-connection -H 10.1.2.3 -u myuser -p mypassword

  # Direct connection with hostname and custom port
  $0 -r cadence -n my-namespace --direct-connection -H mysql.example.com -P 3307 -u myuser -p mypassword

  # Dry-run mode (print command without executing)
  $0 -r cadence -n my-namespace -g cadence@project.iam.gserviceaccount.com -i project:region:instance --auto-iam-authn --dry-run

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--release-name)
            RELEASE_NAME="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -g|--gcp-sa)
            GCP_SA="$2"
            shift 2
            ;;
        -i|--instance)
            INSTANCE_CONNECTION="$2"
            shift 2
            ;;
        -u|--db-user)
            DB_USER="$2"
            shift 2
            ;;
        -p|--password)
            PASSWORD="$2"
            shift 2
            ;;
        -H|--hostname)
            DB_HOST="$2"
            shift 2
            ;;
        -P|--port)
            DB_PORT="$2"
            shift 2
            ;;
        --auto-iam-authn)
            AUTO_IAM_AUTHN="true"
            shift
            ;;
        --direct-connection)
            DIRECT_CONNECTION="true"
            shift
            ;;
        -c|--chart-path)
            CHART_PATH="$2"
            shift 2
            ;;
        -v|--values-file)
            VALUES_FILE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Error: Unknown option $1"
            usage
            ;;
    esac
done

# Validate required arguments
if [ -z "$RELEASE_NAME" ]; then
    echo "Error: Release name is required (-r/--release-name)"
    usage
fi

if [ -z "$NAMESPACE" ]; then
    echo "Error: Namespace is required (-n/--namespace)"
    usage
fi

# Validate connection options
if [ "$DIRECT_CONNECTION" = "true" ]; then
    # Direct connection validation
    if [ -z "$DB_HOST" ]; then
        echo "Error: Database hostname is required for direct connection (-H/--hostname)"
        usage
    fi

    # Cannot use Cloud SQL Proxy options with direct connection
    if [ -n "$GCP_SA" ] || [ -n "$INSTANCE_CONNECTION" ]; then
        echo "Error: Cannot use Cloud SQL Proxy options (-g/-i) with --direct-connection"
        usage
    fi

    # Cannot use IAM auth with direct connection
    if [ "$AUTO_IAM_AUTHN" = "true" ]; then
        echo "Error: Cannot use --auto-iam-authn with --direct-connection"
        usage
    fi
else
    # Cloud SQL Proxy validation
    if [ -z "$GCP_SA" ]; then
        echo "Error: GCP Service Account is required for Cloud SQL Proxy (-g/--gcp-sa)"
        usage
    fi

    if [ -z "$INSTANCE_CONNECTION" ]; then
        echo "Error: Instance connection is required for Cloud SQL Proxy (-i/--instance)"
        usage
    fi

    # Cannot use hostname/port with Cloud SQL Proxy
    if [ -n "$DB_HOST" ]; then
        echo "Error: Cannot use --hostname with Cloud SQL Proxy (use --direct-connection)"
        usage
    fi
fi

# Validate: cannot use password with IAM auth
if [ "$AUTO_IAM_AUTHN" = "true" ] && [ -n "$PASSWORD" ]; then
    echo "Error: Cannot use password with --auto-iam-authn flag"
    exit 1
fi

# Handle database username
if [ -z "$DB_USER" ]; then
    if [ "$AUTO_IAM_AUTHN" = "true" ]; then
        # For IAM auth, auto-extract from GCP SA email
        DB_USER=$(echo "$GCP_SA" | cut -d@ -f1)
        echo "Database username not provided, using: $DB_USER (extracted from GCP SA for IAM auth)"
    else
        # For built-in auth, username is required
        echo "Error: Database username is required for built-in authentication (-u/--db-user)"
        usage
    fi
fi

# Set default values file based on connection type
if [ -z "$VALUES_FILE" ]; then
    if [ "$DIRECT_CONNECTION" = "true" ]; then
        VALUES_FILE="examples/values.mysql.yaml"
    else
        VALUES_FILE="examples/values.mysql-cloudsql.yaml"
    fi
fi

# Display configuration
if [ "$DIRECT_CONNECTION" = "true" ]; then
    echo "Deploying Cadence with direct database connection:"
    echo "  Release:   $RELEASE_NAME"
    echo "  Namespace: $NAMESPACE"
    echo "  DB Host:   $DB_HOST"
    echo "  DB Port:   $DB_PORT"
    echo "  DB User:   $DB_USER"
    echo "  Password:  $([ -n "$PASSWORD" ] && echo 'yes' || echo 'no')"
else
    echo "Deploying Cadence with Cloud SQL Proxy:"
    echo "  Release:   $RELEASE_NAME"
    echo "  Namespace: $NAMESPACE"
    echo "  GCP SA:    $GCP_SA"
    echo "  Instance:  $INSTANCE_CONNECTION"
    echo "  DB User:   $DB_USER"
    echo "  Password:  $([ -n "$PASSWORD" ] && echo 'yes' || echo 'no')"
    echo "  Auth Mode: $([ "$AUTO_IAM_AUTHN" = "true" ] && echo 'IAM' || echo 'Built-in MySQL')"
fi
echo ""

# Build Helm command as an array (safer than string concatenation + eval)
helm_args=(
  upgrade --install "$RELEASE_NAME" "$CHART_PATH"
  --namespace "$NAMESPACE"
  --values "$CHART_PATH/$VALUES_FILE"
  --set "config.persistence.database.sql.user=$DB_USER"
  --create-namespace
)

if [ "$DIRECT_CONNECTION" = "true" ]; then
    # Direct connection mode
    helm_args+=(
      --set cloudSqlProxy.enabled=false
      --set "config.persistence.database.sql.hosts=$DB_HOST"
      --set "config.persistence.database.mysql.port=$DB_PORT"
    )
else
    # Cloud SQL Proxy mode - always use private IP
    helm_args+=(
      --set-string "serviceAccount.annotations.iam\.gke\.io/gcp-service-account=$GCP_SA"
      --set "cloudSqlProxy.initContainer.args[0]=$INSTANCE_CONNECTION"
      --set "cloudSqlProxy.initContainer.args[1]=--port=3306"
      --set "cloudSqlProxy.initContainer.args[2]=--private-ip"
    )

    # Add --auto-iam-authn if enabled
    if [ "$AUTO_IAM_AUTHN" = "true" ]; then
        helm_args+=(--set "cloudSqlProxy.initContainer.args[3]=--auto-iam-authn")
    fi
fi

# Add password if provided (use --set-string to avoid type conversion issues)
if [ -n "$PASSWORD" ]; then
    helm_args+=(--set-string "config.persistence.database.sql.password=$PASSWORD")
fi

# Print or execute Helm command
if [ "$DRY_RUN" = "true" ]; then
    echo ""
    echo "=========================================="
    echo "DRY-RUN MODE - Command to be executed:"
    echo "=========================================="
    echo ""
    # Print the command in a readable format
    printf "helm"
    printf " %q" "${helm_args[@]}"
    echo ""
    echo ""
    echo "=========================================="
    echo ""
    echo "Note: This command was NOT executed. Remove --dry-run to actually deploy."
    exit 0
fi

# Execute deployment
helm "${helm_args[@]}"

echo ""
echo "Deployment complete! Check status with:"
echo "  kubectl get pods -n $NAMESPACE"
echo "  helm status $RELEASE_NAME -n $NAMESPACE"
echo ""

if [ "$DIRECT_CONNECTION" = "true" ]; then
    echo "Direct database connection is enabled. Ensure:"
    echo "  1. Database server '$DB_HOST:$DB_PORT' is accessible from the cluster"
    echo "  2. Database user '$DB_USER' exists and has appropriate privileges"
    if [ -z "$PASSWORD" ]; then
        echo "  3. User is configured for no-password authentication"
    fi
else
    if [ "$AUTO_IAM_AUTHN" = "true" ]; then
        echo "IAM Authentication is enabled. Ensure:"
        echo "  1. GCP Service Account '$GCP_SA' has 'Cloud SQL Client' and 'Cloud SQL Instance User' roles"
        echo "  2. Database user is created with IAM authentication and has 'cloudsqlsuperuser' role:"
        echo "     gcloud sql users create '$DB_USER' --instance=YOUR-INSTANCE-NAME --database-roles=cloudsqlsuperuser --type=cloud_iam_service_account"
    else
        echo "Built-in MySQL authentication is enabled. Ensure:"
        echo "  1. Database user '$DB_USER' exists in Cloud SQL"
        echo "  2. User has privileges on cadence and cadence_visibility databases"
        if [ -z "$PASSWORD" ]; then
            echo "  3. User is configured for no-password authentication"
        fi
    fi
fi

