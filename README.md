# Cadence Charts

This repository contains the Cadence Helm chart, officially maintained by the Cadence team at Uber. The chart provides a production-ready deployment solution for Cadence workflows and services.

## What is included

- **Cadence backend services** as separate deployments: frontend, history, matching, worker.
- **Fully customizable service configuration** via values.yaml with complete Cadence server settings support.
- **Customizable replica counts** and resource limitations.
- **Customizable dynamic config** as a configmap.
- **Multiple database options**: Cassandra, PostgreSQL, and MySQL support via Bitnami chart dependencies or your external database.
- **Automatic schema setup jobs**: Auto-detection of database versions with configurable schema initialization for:
  - Primary databases (Cassandra, PostgreSQL, MySQL) - enabled by default
  - Elasticsearch for advanced visibility - configurable
- **Advanced visibility support**: Elasticsearch integration for enhanced workflow search and filtering.
- **Cadence Web UI**: Optional web interface for workflow visualization and management.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure (if persistence is enabled for databases)

## Installation

[Helm](https://helm.sh) must be installed to use the charts. Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

### Add Helm Repository

Once Helm has been set up correctly, add the repo as follows:

```bash
helm repo add cadence https://cadence-workflow.github.io/cadence-charts
```

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages:

```bash
helm repo update
```

You can then run `helm search repo cadence` to see the charts.

### Install Chart Dependencies for local Chart

For edit directly the Chart files locally, you need to update the chart dependencies (Cassandra, PostgreSQL, or MySQL):

```bash
# Download the chart
helm pull cadence/cadence --untar

# Navigate to the chart directory
cd cadence

# Update dependencies
helm dependency update

# After that you can install using local directory
```

This will download the required database charts based on your configuration.

### Install Cadence

To install the cadence chart with default settings (includes Cassandra):

```bash
helm install cadence-release -n cadencetest cadence/cadence
```

The chart will automatically:
- Deploy the selected database (Cassandra by default)
- Run schema setup jobs to initialize the database
- Deploy all Cadence services (frontend, history, matching, worker)
- Optionally deploy Cadence Web UI

To install with custom values:

```bash
helm install cadence-release cadence/cadence -f custom-values.yaml
```

### Install with Different Database

To use PostgreSQL instead of Cassandra:

```bash
helm install cadence-release cadence/cadence \
  --set cassandra.enabled=false \
  --set postgresql.enabled=true \
  --set config.persistence.database.driver="postgres" \
  --set config.persistence.database.driver.sql.hosts= \
  --set config.persistence.database.driver.sql.user= \
  --set config.persistence.database.driver.sql.password= 
```

To use MySQL instead of Cassandra:


```bash
helm install cadence-release cadence/cadence \
  --set cassandra.enabled=false \
  --set mysql.enabled=true \
  --set config.persistence.database.driver="mysql" \
  --set config.persistence.database.driver.sql.hosts= \
  --set config.persistence.database.driver.sql.user= \
  --set config.persistence.database.driver.sql.password= 
```

### Verify Installation

Check the status of your deployment:

```bash
# Check all pods
kubectl get pods -l app.kubernetes.io/name=cadence-release

# Check schema setup jobs
kubectl get jobs -l app.kubernetes.io/component=schema-server

# Check service status
kubectl get svc -l app.kubernetes.io/name=cadence-release
```

Wait for all pods to be in `Running` state and schema jobs to complete successfully.

## Configuration

See the [values.yaml](values.yaml) file for configuration options. You can override any value using the `--set` flag or by providing a custom values file.

### Common Configuration Examples

```bash
# Set custom replica counts
helm install cadence-release cadence/cadence -n cadencetest \
  --set server.frontend.replicaCount=3 \
  --set server.history.replicaCount=3

# Use external database
helm install cadence-release cadence/cadence -n cadencetest \
  --set cassandra.enabled=false \
  --set server.config.persistence.default.cassandra.hosts=my-cassandra.example.com

# Disable automatic schema setup (if managing schemas externally)
helm install cadence-release cadence/cadence -n cadencetest \
  --set schema.setup.enabled=false

### Full Server Configuration

All Cadence server configuration options are available through values.yaml under `server.config`. This includes:
- Persistence settings
- Service-specific configurations
- Clustering options
- Authentication and authorization
- Archival configuration
- And more...

Refer to the [Cadence server documentation](https://cadenceworkflow.io/docs/operation-guide/setup/) for detailed configuration options.

## Uninstallation

To uninstall/delete the chart:

```bash
helm delete cadence-release -n cadencetest
```

This will remove all Kubernetes components associated with the chart and delete the release.

## Upgrading

To upgrade an existing release:

```bash
# Update repository
helm repo update

# Upgrade release
helm upgrade cadence-release cadence/cadence -n cadencetest

# Upgrade with new values
helm upgrade cadence-release cadence/cadence -n cadencetest -f custom-values.yaml
```

## Troubleshooting

### Schema Jobs Failing

If schema setup jobs fail, check the logs:
```bash
kubectl logs job/cadence-release-schema-server
kubectl logs job/cadence-release-schema-elasticsearch
```

### Services Not Starting

Ensure schema jobs have completed successfully before services start:
```bash
kubectl get jobs
```

### Version Compatibility

The schema jobs automatically detect versions, but ensure your Cadence server version is compatible with your database version.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for instructions on how to contribute, run samples, and more.

## Support

For issues, questions, or contributions, please visit:
- [GitHub Issues](https://github.com/uber/cadence-charts/issues)
- [Cadence Documentation](https://cadenceworkflow.io/docs/get-started)
- [Cadence Community](https://github.com/cadence-workflow/cadence)