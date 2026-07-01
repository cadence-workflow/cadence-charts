# Deploying Cadence on GKE with Cloud SQL for MySQL

This guide provides step-by-step instructions for deploying Cadence on Google Kubernetes Engine (GKE) using Cloud SQL for MySQL as the persistence layer.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Deployment Options](#deployment-options)
  - [Option 1: Direct Connection with Built-in Authentication](#option-1-direct-connection-with-built-in-authentication)
  - [Option 2: Cloud SQL Proxy with Built-in Authentication (Password)](#option-2-cloud-sql-proxy-with-built-in-authentication-password)
  - [Option 3: Cloud SQL Proxy with Built-in Authentication (No Password)](#option-3-cloud-sql-proxy-with-built-in-authentication-no-password)
  - [Option 4: Cloud SQL Proxy with IAM Authentication](#option-4-cloud-sql-proxy-with-iam-authentication)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before you begin, ensure you have:

1. **GKE Cluster**: A running GKE cluster with Workload Identity enabled (required for Options 2, 3 and 4)
2. **Cloud SQL Instance**: A Cloud SQL for MySQL instance (MySQL 8.0)
3. **Tools Installed**:
   - `gcloud` CLI configured with appropriate permissions
   - `kubectl` configured to access your GKE cluster
   - `helm` 3.x installed
4. **GCP Permissions**:
   - Cloud SQL Admin (to create databases and users)
   - Kubernetes Engine Admin (to deploy to GKE)
   - Service Account Admin (for IAM authentication setup)

---

## Deployment Options

Choose the deployment option that best fits your security and operational requirements.

### Option 1: Direct Connection with Built-in Authentication

**Use case**: Simplest setup, suitable for development or when Cloud SQL Proxy overhead is not acceptable.

**Architecture**: Cadence pods connect directly to Cloud SQL via private IP or public IP with authorized networks.

#### Prerequisites

- Cloud SQL instance has either:
  - **Private IP** configured with VPC peering to your GKE cluster's VPC, OR
  - **Public IP** with authorized networks configured to allow GKE node IPs

#### Step 1: Create Database User

Create a database user with `cloudsqlsuperuser` role using the gcloud CLI:

```bash
# Built-in users will be granted the cloudsqlsuperuser role automatically if no roles are specified.
gcloud sql users create cadence-user \
  --instance=YOUR-INSTANCE-NAME \
  --host=% \
  --password=your-strong-password
```

**Alternatively**, you can create the user from the Google Cloud Console:
1. Go to Cloud SQL Instances → Select your instance → Users
2. Click "Add User Account"
3. Select "Built-in authentication"
4. Username: `cadence-user`
5. Password: `your-strong-password`
6. Check "Grant this user the cloudsqlsuperuser privilege"
7. Click "Add"

**Note**: The `cloudsqlsuperuser` privilege grants the user full access to create databases and manage schemas, which is required for Cadence's schema job to create the `cadence` and `cadence_visibility` databases during deployment.

#### Step 2: Get Database Connection Details

```bash
# Get the private IP (if using VPC peering)
gcloud sql instances describe YOUR-INSTANCE-NAME --format="value(ipAddresses[0].ipAddress)"

# Or get the public IP (if using authorized networks)
gcloud sql instances describe YOUR-INSTANCE-NAME --format="value(ipAddresses[1].ipAddress)"
```

#### Step 3: Deploy Cadence

```bash
cd charts/cadence

./scripts/deploy-with-cloudsql.sh \
  -r cadence \
  -n cadence \
  --direct-connection \
  -H 10.1.2.3 \
  -u cadence-user \
  -p your-strong-password
```

**Parameters:**
- `-r cadence` - Helm release name
- `-n cadence` - Kubernetes namespace
- `--direct-connection` - Use direct database connection (no proxy)
- `-H 10.1.2.3` - Database IP address or hostname
- `-u cadence-user` - Database username
- `-p your-strong-password` - Database password

#### Security Notes

- Store the password in a secure secret manager instead of passing it via command line
- Use private IP with VPC peering for better security
- If using public IP, ensure authorized networks are properly restricted

---

### Option 2: Cloud SQL Proxy with Built-in Authentication (Password)

**Use case**: Enhanced security with Cloud SQL Proxy while using traditional password authentication.

**Architecture**: Cloud SQL Proxy runs as an init container in each Cadence pod, establishing a secure tunnel to Cloud SQL.

#### Step 1: Create GCP Service Account

```bash
# Set variables
PROJECT_ID="your-gcp-project"
GSA_NAME="cadence-cloud-sql"
GSA_EMAIL="${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Create GCP Service Account
gcloud iam service-accounts create $GSA_NAME \
  --display-name="Cadence Cloud SQL Proxy" \
  --project=$PROJECT_ID

# Grant Cloud SQL Client role
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${GSA_EMAIL}" \
  --role="roles/cloudsql.client"
```

#### Step 2: Configure Workload Identity

```bash
# Set variables
K8S_NAMESPACE="cadence"
KSA_NAME="cadence"  # This will be created by the Helm chart

# Bind Kubernetes SA to GCP SA
gcloud iam service-accounts add-iam-policy-binding ${GSA_EMAIL} \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:${PROJECT_ID}.svc.id.goog[${K8S_NAMESPACE}/${KSA_NAME}]" \
  --project=$PROJECT_ID
```

#### Step 3: Create Database User

Follow [**Step 1 from Option 1**](#option-1-direct-connection-with-built-in-authentication) to create the database user with password.

#### Step 4: Deploy Cadence

```bash
cd charts/cadence

# Get instance connection name
INSTANCE_CONNECTION=$(gcloud sql instances describe YOUR-INSTANCE-NAME --format="value(connectionName)")

./scripts/deploy-with-cloudsql.sh \
  -r cadence \
  -n cadence \
  -g ${GSA_EMAIL} \
  -i ${INSTANCE_CONNECTION} \
  -u cadence-user \
  -p your-strong-password
```

**Parameters:**
- `-r cadence` - Helm release name
- `-n cadence` - Kubernetes namespace
- `-g ${GSA_EMAIL}` - GCP Service Account email
- `-i ${INSTANCE_CONNECTION}` - Cloud SQL instance connection name (format: `project:region:instance`)
- `-u cadence-user` - Database username
- `-p your-strong-password` - Database password

---

### Option 3: Cloud SQL Proxy with Built-in Authentication (No Password)

**Use case**: Simplify credential management by using Cloud SQL Proxy with no-password MySQL authentication.

**Architecture**: Cloud SQL Proxy provides secure connectivity, MySQL user has no password (authentication is based on the secure proxy connection).

#### Prerequisites

- Same as Option 2 (GCP Service Account and Workload Identity setup)

#### Step 1: Setup GCP Service Account and Workload Identity

Follow **Steps 1-2 from Option 2** to create the GCP Service Account and configure Workload Identity.

#### Step 2: Create Database User (No Password)

Create a database user without a password, restricted to Cloud SQL Proxy connections only:

```bash
# Create user without password, restricted to Cloud SQL Proxy, with cloudsqlsuperuser role
gcloud sql users create cadence-user \
  --instance=YOUR-INSTANCE-NAME \
  --host=cloudsqlproxy~%
```

**Alternatively**, you can create the user from the Google Cloud Console:
1. Go to Cloud SQL Instances → Select your instance → Users
2. Click "Add User Account"
3. Select "Built-in authentication"
4. Username: `cadence-user`
5. Hostname: `cloudsqlproxy~%`
6. Leave password field empty
7. Check "Grant this user the cloudsqlsuperuser privilege"
8. Click "Add"

**Important**: 
- The `cloudsqlproxy~%` host pattern restricts the user to only connect via Cloud SQL Proxy
- This provides an additional security layer - the user cannot be used for direct connections
- The `cloudsqlsuperuser` role grants full database creation and management privileges needed for Cadence's schema job

**Security Note**: This user can only connect via the Cloud SQL Proxy from authorized workloads with the correct GCP Service Account.

#### Step 3: Deploy Cadence

```bash
cd charts/cadence

# Get instance connection name
INSTANCE_CONNECTION=$(gcloud sql instances describe YOUR-INSTANCE-NAME --format="value(connectionName)")

./scripts/deploy-with-cloudsql.sh \
  -r cadence \
  -n cadence \
  -g ${GSA_EMAIL} \
  -i ${INSTANCE_CONNECTION} \
  -u cadence-user
```

**Parameters:**
- `-r cadence` - Helm release name
- `-n cadence` - Kubernetes namespace
- `-g ${GSA_EMAIL}` - GCP Service Account email
- `-i ${INSTANCE_CONNECTION}` - Cloud SQL instance connection name
- `-u cadence-user` - Database username
- **Note**: No password parameter

---

### Option 4: Cloud SQL Proxy with IAM Authentication

**Use case**: Highest security - leverages Google Cloud IAM for database authentication, no passwords stored anywhere.

**Architecture**: Cloud SQL Proxy with IAM authentication enabled. Database user is authenticated via the GCP Service Account's IAM permissions.

#### Prerequisites

- Cloud SQL instance must have the **Cloud SQL IAM database authentication** flag enabled:

```bash
gcloud sql instances patch YOUR-INSTANCE-NAME \
  --database-flags=cloudsql_iam_authentication=on
```

#### Step 1: Setup GCP Service Account and Workload Identity

Follow **Steps 1-2 from Option 2** to create the GCP Service Account and configure Workload Identity.

#### Step 2: Grant Cloud SQL Instance User Role

```bash
# Grant the IAM database user role to the service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${GSA_EMAIL}" \
  --role="roles/cloudsql.instanceUser"
```

#### Step 3: Create IAM Database User

The database username **must match** the GCP Service Account name (the part before `@`).

Create the IAM-authenticated user using gcloud:

```bash
gcloud sql users create cadence-cloud-sql@project.iam.gserviceaccount.com \
  --instance=YOUR-INSTANCE-NAME \
  --database-roles=cloudsqlsuperuser \
  --type=cloud_iam_service_account
```

**Note**: The `--type=cloud_iam_service_account` flag creates a user authenticated via Cloud IAM. 

**Important**: 
- IAM users don't have passwords - authentication is done via the GCP Service Account
- The user can only connect via Cloud SQL Proxy with the correct GCP Service Account credentials

#### Step 4: Deploy Cadence

```bash
cd charts/cadence

# Get instance connection name
INSTANCE_CONNECTION=$(gcloud sql instances describe YOUR-INSTANCE-NAME --format="value(connectionName)")

./scripts/deploy-with-cloudsql.sh \
  -r cadence \
  -n cadence \
  -g ${GSA_EMAIL} \
  -i ${INSTANCE_CONNECTION} \
  --auto-iam-authn
```

**Parameters:**
- `-r cadence` - Helm release name
- `-n cadence` - Kubernetes namespace
- `-g ${GSA_EMAIL}` - GCP Service Account email
- `-i ${INSTANCE_CONNECTION}` - Cloud SQL instance connection name
- `--auto-iam-authn` - Enable IAM authentication
- **Note**: Username is automatically extracted from the GCP Service Account email

#### Verification

Verify IAM authentication is working:

```bash
# Check pod logs for successful connection
kubectl logs -n cadence -l app.kubernetes.io/name=cadence -c cloud-sql-proxy

# Should see: "Listening on 127.0.0.1:3306"
```

---

## Verification

After deployment, verify that Cadence is running correctly:

### 1. Check Pod Status

```bash
kubectl get pods -n cadence

# Expected output: All pods should be Running
# NAME                               READY   STATUS    RESTARTS   AGE
# cadence-frontend-xxxxxxxxx-xxxxx   1/1     Running   0          2m
# cadence-history-xxxxxxxxx-xxxxx    1/1     Running   0          2m
# cadence-matching-xxxxxxxxx-xxxxx   1/1     Running   0          2m
# cadence-worker-xxxxxxxxx-xxxxx     1/1     Running   0          2m
```

### 2. Check Schema Job

```bash
kubectl get jobs -n cadence

# The schema job should show COMPLETIONS: 1/1
kubectl logs -n cadence job/cadence-schema-server
```

### 3. Verify Database Connection

```bash
# Check main container logs
kubectl logs -n cadence -l app.kubernetes.io/component=frontend -c cadence-frontend

# For Cloud SQL Proxy deployments, check proxy logs
kubectl logs -n cadence -l app.kubernetes.io/component=frontend -c cloud-sql-proxy
```

### 4. Test Cadence CLI

```bash
# Port-forward to frontend service
kubectl port-forward -n cadence svc/cadence-frontend 7933:7933

# In another terminal, register a domain
docker run --network=host --rm ubercadence/cli:master \
  --address localhost:7933 \
  domain register --global_domain false cadence-test

# List domains
docker run --network=host --rm ubercadence/cli:master \
  --address localhost:7933 \
  domain list
```

---

## Troubleshooting

### Cloud SQL Proxy Connection Issues

**Problem**: Schema job or pods stuck with "MySQL is not ready yet..."

**Solution**: Check Cloud SQL Proxy logs for detailed error messages:

```bash
# Check init container logs (schema job)
kubectl logs -n cadence job/cadence-schema-server -c cloud-sql-proxy

# Check deployment init container logs
kubectl logs -n cadence -l app.kubernetes.io/name=cadence -c cloud-sql-proxy
```

**Common errors:**

1. **"failed to refresh token"**
   - Workload Identity not configured correctly
   - Verify: `gcloud iam service-accounts get-iam-policy ${GSA_EMAIL}`

2. **"connection refused"**
   - Instance connection name is incorrect
   - Verify: `gcloud sql instances describe YOUR-INSTANCE-NAME --format="value(connectionName)"`

3. **"Access denied for user"**
   - Database user doesn't exist or lacks permissions
   - Verify user: `SELECT User, Host FROM mysql.user WHERE User = 'your-user';`

### IAM Authentication Issues

**Problem**: Connection fails with IAM authentication enabled

**Checklist**:
1. Cloud SQL instance has `cloudsql_iam_authentication=on` flag
2. GCP Service Account has `roles/cloudsql.instanceUser` role
3. Database username matches GCP Service Account name (part before `@`)
4. User was created with: `IDENTIFIED WITH caching_sha2_password AS 'cloudsqliam'`

**Verify IAM user:**
```sql
SELECT User, Host, plugin FROM mysql.user WHERE User = 'cadence-cloud-sql';
-- plugin should be: caching_sha2_password
```

### Direct Connection Issues

**Problem**: Cannot connect to database via direct connection

**Solutions**:

1. **Private IP**: Verify VPC peering
   ```bash
   gcloud compute networks peerings list --network=YOUR-VPC-NETWORK
   ```

2. **Public IP**: Check authorized networks
   ```bash
   # Get your GKE node IPs
   kubectl get nodes -o wide
   
   # Verify they're in authorized networks
   gcloud sql instances describe YOUR-INSTANCE-NAME --format="value(settings.ipConfiguration.authorizedNetworks)"
   ```

### Schema Migration Failures

**Problem**: Schema job fails to complete

**Debug**:
```bash
# View detailed schema job logs
kubectl logs -n cadence job/cadence-schema-server -c wait-for-database

# Check MySQL connection from schema job
kubectl logs -n cadence job/cadence-schema-server -c cadence-sql-tool
```

**Common issues**:
- Database doesn't exist - Create `cadence` and `cadence_visibility` databases
- User lacks permissions - Grant ALL PRIVILEGES on both databases
- Wrong database driver - Ensure `config.persistence.database.driver: mysql` in values

### Performance Tuning

For production deployments:

1. **Cloud SQL Proxy resources**: Adjust if experiencing connection issues
   ```yaml
   cloudSqlProxy:
     resources:
       requests:
         cpu: 200m
         memory: 256Mi
       limits:
         cpu: 500m
         memory: 512Mi
   ```

2. **Database connection pool**: Tune based on workload
   ```yaml
   config:
     persistence:
       database:
         sql:
           maxConns: 50
           maxIdleConns: 20
   ```

3. **Cloud SQL instance size**: Scale based on Cadence workload
   ```bash
   gcloud sql instances patch YOUR-INSTANCE-NAME \
     --tier=db-n1-standard-2 \
     --database-flags=max_connections=1000
   ```

---

## References

- [Cloud SQL Proxy Documentation](https://cloud.google.com/sql/docs/mysql/sql-proxy)
- [Cloud SQL IAM Authentication](https://cloud.google.com/sql/docs/mysql/authentication)
- [GKE Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [Cadence Documentation](https://cadenceworkflow.io/docs/)
