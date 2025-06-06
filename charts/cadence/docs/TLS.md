# TLS Configuration for Database and Service Connections

This document describes how to configure TLS (Transport Layer Security) for secure connections to various databases and services including Cassandra, MySQL, PostgreSQL, Elasticsearch, and Kafka.

## Configuration Overview

The TLS configuration supports multiple security scenarios from basic server authentication to full mutual TLS (mTLS). All services use the same TLS configuration structure and validation logic. Certificates can be provided either through direct file paths or by mounting them as Kubernetes volumes.

### Basic Configuration

```yaml
tls:
  enabled: true
  caFile: "/path/to/ca-cert.pem"
  enableHostVerification: true
```

## Certificate Management

### Kubernetes Volume Mounting

For Kubernetes deployments, TLS certificates can be mounted as volumes from Secrets or ConfigMaps. This is the recommended approach for production environments as it provides better security and management.

#### Global TLS Volume Configuration

Configure TLS volumes at the global level to share certificates across all Cadence services:

```yaml
global:
  tls:
    volumes:
      # Single CA certificate from Secret
      - name: database-ca-cert
        secret:
          secretName: database-tls-secret
          items:
            - key: ca.crt
              path: ca.pem
      
      # Client certificate and key from Secret
      - name: database-client-cert
        secret:
          secretName: database-client-secret
          items:
            - key: tls.crt
              path: client.pem
            - key: tls.key
              path: client-key.pem
    
    volumeMounts:
      # Mount CA certificate
      - name: database-ca-cert
        mountPath: /etc/cadence/ssl/ca
        readOnly: true
      
      # Mount client certificates
      - name: database-client-cert
        mountPath: /etc/cadence/ssl/client
        readOnly: true
```

#### Service-specific TLS Volume Configuration

Individual services can also have their own TLS volume configurations:

```yaml
frontend:
  tls:
    volumes:
      - name: frontend-specific-cert
        secret:
          secretName: frontend-tls-secret
          items:
            - key: frontend.crt
              path: frontend.pem
    volumeMounts:
      - name: frontend-specific-cert
        mountPath: /etc/cadence/ssl/frontend
        readOnly: true
```

#### Database-specific Examples

```yaml
global:
  tls:
    volumes:
      # PostgreSQL TLS certificates
      - name: postgres-tls-certs
        secret:
          secretName: postgres-ssl-secret
          items:
            - key: root.crt
              path: postgresql-ca.pem
            - key: postgresql.crt
              path: postgresql-client.pem
            - key: postgresql.key
              path: postgresql-client-key.pem
      
      # MySQL TLS certificates
      - name: mysql-tls-certs
        secret:
          secretName: mysql-ssl-secret
          items:
            - key: ca.pem
              path: mysql-ca.pem
            - key: client-cert.pem
              path: mysql-client-cert.pem
            - key: client-key.pem
              path: mysql-client-key.pem
      
      # Elasticsearch TLS certificates
      - name: elasticsearch-tls-certs
        secret:
          secretName: elasticsearch-ssl-secret
          items:
            - key: ca.crt
              path: elasticsearch-ca.pem
            - key: client.crt
              path: elasticsearch-client.pem
            - key: client.key
              path: elasticsearch-client-key.pem
      
      # Kafka TLS certificates
      - name: kafka-tls-certs
        secret:
          secretName: kafka-ssl-secret
          items:
            - key: ca.crt
              path: kafka-ca.pem
            - key: client.crt
              path: kafka-client.pem
            - key: client.key
              path: kafka-client-key.pem
    
    volumeMounts:
      - name: postgres-tls-certs
        mountPath: /etc/cadence/ssl/postgres
        readOnly: true
      - name: mysql-tls-certs
        mountPath: /etc/cadence/ssl/mysql
        readOnly: true
      - name: elasticsearch-tls-certs
        mountPath: /etc/cadence/ssl/elasticsearch
        readOnly: true
      - name: kafka-tls-certs
        mountPath: /etc/cadence/ssl/kafka
        readOnly: true
```

#### Multiple CA Certificates Example

```yaml
global:
  tls:
    volumes:
      - name: multiple-ca-certs
        configMap:
          name: database-ca-bundle
          items:
            - key: root-ca.crt
              path: root-ca.pem
            - key: intermediate-ca.crt
              path: intermediate-ca.pem
    volumeMounts:
      - name: multiple-ca-certs
        mountPath: /etc/cadence/ssl/ca-bundle
        readOnly: true
```

## Configuration Parameters

### `enabled`
- **Type**: `boolean`
- **Default**: `false`
- **Description**: Enables or disables TLS connections
- **Usage**: When `false`, all other TLS settings are ignored
- **Applies to**: All database and service connections

### `sslMode`
- **Type**: `string`
- **Default**: `""`
- **Description**: SSL mode configuration (database-specific)
- **PostgreSQL values**: `disable`, `allow`, `prefer`, `require`, `verify-ca`, `verify-full`
- **MySQL values**: `false`, `true`, `skip-verify`, `preferred`
- **Usage**: Controls the level of SSL verification required

### `caFile`
- **Type**: `string`
- **Default**: `""`
- **Description**: Path to Certificate Authority (CA) certificate file
- **Format**: PEM format
- **Usage**: Required to verify server certificates and establish trust
- **Example with volumes**: `"/etc/cadence/ssl/ca/ca.pem"`
- **Direct path**: `"/etc/ssl/certs/ca-certificates.crt"`

### `caFiles`
- **Type**: `array`
- **Default**: `[]`
- **Description**: Array of CA certificate file paths
- **Format**: PEM format
- **Usage**: Alternative to `caFile` when multiple CA certificates are needed
- **Note**: Can be used together with `caFile` - all certificates are combined
- **Example with volumes**: `["/etc/cadence/ssl/ca-bundle/root-ca.pem", "/etc/cadence/ssl/ca-bundle/intermediate-ca.pem"]`

### `certFile`
- **Type**: `string`
- **Default**: `""`
- **Description**: Path to client certificate file
- **Format**: PEM format
- **Usage**: Required for mutual TLS (mTLS) authentication
- **Dependencies**: Must be used together with `keyFile`
- **Example with volumes**: `"/etc/cadence/ssl/client/client.pem"`

### `keyFile`
- **Type**: `string`
- **Default**: `""`
- **Description**: Path to client private key file
- **Format**: PEM format (RSA or ECDSA)
- **Usage**: Required for mutual TLS (mTLS) authentication
- **Dependencies**: Must be used together with `certFile`
- **Security**: Should have restricted file permissions (600)
- **Example with volumes**: `"/etc/cadence/ssl/client/client-key.pem"`

### `enableHostVerification`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Enables hostname verification against server certificate
- **Security**: 
  - `true`: Verifies server certificate matches hostname (secure)
  - `false`: Skips hostname verification (insecure - testing only)
- **Recommendation**: Always `true` in production environments

### `requireClientAuth`
- **Type**: `boolean`
- **Default**: `false`
- **Description**: Requires client certificate authentication (mutual TLS)
- **Usage**: When `true`, server will request and verify client certificates
- **Dependencies**: Clients must provide `certFile` and `keyFile`
- **Server requirement**: Database/service must be configured for mTLS

### `serverName`
- **Type**: `string`
- **Default**: `""`
- **Description**: Override server name for certificate verification
- **Usage**: Use when connecting via IP address or when certificate Common Name differs from hostname
- **Example**: `"database.example.com"` when connecting to `192.168.1.100`

## Certificate Formats

### PEM Format
- **Description**: Privacy-Enhanced Mail format (Base64 encoded, human-readable)
- **Extensions**: `.pem`, `.crt`, `.cer`, `.key`
- **Structure**: Contains `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----` headers
- **Support**: Only format supported by this implementation

## Configuration Scenarios by Database/Service Type

### 1. PostgreSQL with TLS

```yaml
# Using Kubernetes volumes (recommended)
global:
  tls:
    volumes:
      - name: postgres-tls-certs
        secret:
          secretName: postgres-ssl-secret
          items:
            - key: root.crt
              path: postgresql-ca.pem
            - key: postgresql.crt
              path: postgresql-client.pem
            - key: postgresql.key
              path: postgresql-client-key.pem
    volumeMounts:
      - name: postgres-tls-certs
        mountPath: /etc/cadence/ssl/postgres
        readOnly: true

database:
  sql:
    driver: "postgresql"
    tls:
      enabled: true
      sslMode: "require"
      caFile: "/etc/cadence/ssl/postgres/postgresql-ca.pem"
      certFile: "/etc/cadence/ssl/postgres/postgresql-client.pem"
      keyFile: "/etc/cadence/ssl/postgres/postgresql-client-key.pem"
      enableHostVerification: true
```

### 2. MySQL with TLS

```yaml
# Using Kubernetes volumes (recommended)
global:
  tls:
    volumes:
      - name: mysql-tls-certs
        secret:
          secretName: mysql-ssl-secret
          items:
            - key: ca.pem
              path: mysql-ca.pem
            - key: client-cert.pem
              path: mysql-client-cert.pem
            - key: client-key.pem
              path: mysql-client-key.pem
    volumeMounts:
      - name: mysql-tls-certs
        mountPath: /etc/cadence/ssl/mysql
        readOnly: true

database:
  sql:
    driver: "mysql"
    tls:
      enabled: true
      sslMode: "true"
      caFile: "/etc/cadence/ssl/mysql/mysql-ca.pem"
      certFile: "/etc/cadence/ssl/mysql/mysql-client-cert.pem"
      keyFile: "/etc/cadence/ssl/mysql/mysql-client-key.pem"
      enableHostVerification: true
```

### 3. Cassandra with TLS

```yaml
# Using Kubernetes volumes (recommended)
global:
  tls:
    volumes:
      - name: cassandra-tls-certs
        secret:
          secretName: cassandra-tls-secret
          items:
            - key: ca.crt
              path: cassandra-ca.pem
            - key: client.crt
              path: cassandra-client.pem
            - key: client.key
              path: cassandra-client-key.pem
    volumeMounts:
      - name: cassandra-tls-certs
        mountPath: /etc/cadence/ssl/cassandra
        readOnly: true

database:
  cassandra:
    tls:
      enabled: true
      caFile: "/etc/cadence/ssl/cassandra/cassandra-ca.pem"
      certFile: "/etc/cadence/ssl/cassandra/cassandra-client.pem"
      keyFile: "/etc/cadence/ssl/cassandra/cassandra-client-key.pem"
      enableHostVerification: true
      requireClientAuth: true
```

### 4. Elasticsearch with TLS

```yaml
# Using Kubernetes volumes (recommended)
global:
  tls:
    volumes:
      - name: elasticsearch-tls-certs
        secret:
          secretName: elasticsearch-ssl-secret
          items:
            - key: ca.crt
              path: elasticsearch-ca.pem
            - key: client.crt
              path: elasticsearch-client.pem
            - key: client.key
              path: elasticsearch-client-key.pem
    volumeMounts:
      - name: elasticsearch-tls-certs
        mountPath: /etc/cadence/ssl/elasticsearch
        readOnly: true

elasticsearch:
  tls:
    enabled: true
    caFile: "/etc/cadence/ssl/elasticsearch/elasticsearch-ca.pem"
    certFile: "/etc/cadence/ssl/elasticsearch/elasticsearch-client.pem"
    keyFile: "/etc/cadence/ssl/elasticsearch/elasticsearch-client-key.pem"
    enableHostVerification: true
```

### 5. Kafka with TLS

```yaml
# Using Kubernetes volumes (recommended)
global:
  tls:
    volumes:
      - name: kafka-tls-certs
        secret:
          secretName: kafka-ssl-secret
          items:
            - key: ca.crt
              path: kafka-ca.pem
            - key: client.crt
              path: kafka-client.pem
            - key: client.key
              path: kafka-client-key.pem
    volumeMounts:
      - name: kafka-tls-certs
        mountPath: /etc/cadence/ssl/kafka
        readOnly: true

kafka:
  tls:
    enabled: true
    caFile: "/etc/cadence/ssl/kafka/kafka-ca.pem"
    certFile: "/etc/cadence/ssl/kafka/kafka-client.pem"
    keyFile: "/etc/cadence/ssl/kafka/kafka-client-key.pem"
    enableHostVerification: true
```

### 6. Multiple Services with Shared Certificates

```yaml
# Single certificate bundle for multiple services
global:
  tls:
    volumes:
      - name: shared-tls-bundle
        secret:
          secretName: shared-ssl-secret
          items:
            - key: ca-bundle.crt
              path: ca-bundle.pem
            - key: client.crt
              path: client.pem
            - key: client.key
              path: client-key.pem
    volumeMounts:
      - name: shared-tls-bundle
        mountPath: /etc/cadence/ssl/shared
        readOnly: true

database:
  cassandra:
    tls:
      enabled: true
      caFile: "/etc/cadence/ssl/shared/ca-bundle.pem"
      certFile: "/etc/cadence/ssl/shared/client.pem"
      keyFile: "/etc/cadence/ssl/shared/client-key.pem"
      enableHostVerification: true

elasticsearch:
  tls:
    enabled: true
    caFile: "/etc/cadence/ssl/shared/ca-bundle.pem"
    certFile: "/etc/cadence/ssl/shared/client.pem"
    keyFile: "/etc/cadence/ssl/shared/client-key.pem"
    enableHostVerification: true

kafka:
  tls:
    enabled: true
    caFile: "/etc/cadence/ssl/shared/ca-bundle.pem"
    certFile: "/etc/cadence/ssl/shared/client.pem"
    keyFile: "/etc/cadence/ssl/shared/client-key.pem"
    enableHostVerification: true
```

### 7. Development/Testing with Self-signed Certificates

```yaml
# For any database/service with self-signed certificates
tls:
  enabled: true
  caFile: "/path/to/self-signed-ca.pem"
  enableHostVerification: false  # Only if hostname doesn't match
  serverName: "service.local"     # If needed for verification
```

**⚠️ Warning**: Only use `enableHostVerification: false` in development environments

## Security Best Practices

### Production Environments
- **Use Kubernetes Secrets** for certificate storage instead of direct file paths
- Always use `enableHostVerification: true`
- Use certificates from trusted Certificate Authorities
- Regularly rotate certificates before expiration
- Use mutual TLS for high-security requirements
- Mount certificates as read-only volumes
- Use appropriate `sslMode` for SQL databases

### Database-specific Security
- **PostgreSQL**: Use `sslMode: "verify-full"` for maximum security
- **MySQL**: Use `sslMode: "true"` and verify certificates
- **Cassandra**: Enable `requireClientAuth: true` for mutual TLS
- **Elasticsearch**: Configure cluster security with proper certificates
- **Kafka**: Use SASL_SSL for authentication combined with TLS

### Kubernetes Security
- Store certificates in Kubernetes Secrets, not ConfigMaps
- Use RBAC to restrict access to certificate secrets
- Consider using cert-manager for automated certificate lifecycle management
- Implement certificate rotation strategies
- Use different certificates for different environments

### Certificate Management
- Monitor certificate expiration dates
- Implement automated certificate renewal
- Keep CA certificates up to date
- Use separate certificates for different services when possible
- Consider using Kubernetes cert-manager for automation

## Troubleshooting

### Common Issues

1. **Certificate verification failed**
   - Check if CA certificate is correct for the specific service
   - Verify certificate chain is complete
   - Ensure certificate hasn't expired
   - Verify volume mounts are correct when using Kubernetes

2. **SSL mode issues (SQL databases)**
   - Verify `sslMode` is appropriate for your database type
   - Check database server SSL configuration
   - Ensure SSL is enabled on the database server

3. **Volume mount issues**
   - Verify Secret/ConfigMap exists in the correct namespace
   - Check that the secret keys match the volume configuration
   - Ensure proper RBAC permissions for accessing secrets

4. **Service-specific connection issues**
   - **Cassandra**: Verify TLS port (usually 9142) is used
   - **PostgreSQL**: Check `sslmode` parameter in connection string
   - **MySQL**: Verify SSL parameters are correctly set
   - **Elasticsearch**: Check HTTPS port and cluster security
   - **Kafka**: Verify SASL_SSL configuration

### Validation Commands

Test certificate validity:
```bash
# Check certificate details
openssl x509 -in /path/to/cert.pem -text -noout

# Verify certificate chain
openssl verify -CAfile /path/to/ca.pem /path/to/cert.pem

# Test TLS connection to different services
openssl s_client -connect cassandra-host:9142 -CAfile /path/to/ca.pem
openssl s_client -connect postgres-host:5432 -CAfile /path/to/ca.pem
openssl s_client -connect mysql-host:3306 -CAfile /path/to/ca.pem
openssl s_client -connect elasticsearch-host:9200 -CAfile /path/to/ca.pem
openssl s_client -connect kafka-host:9093 -CAfile /path/to/ca.pem
```

Test Kubernetes volume mounts:
```bash
# Check if certificates are mounted correctly
kubectl exec -it <pod-name> -- ls -la /etc/cadence/ssl/
kubectl exec -it <pod-name> -- cat /etc/cadence/ssl/ca/ca.pem

# Verify Secret contents
kubectl get secret <secret-name> -o yaml
kubectl describe secret <secret-name>
```

## Service-specific Integration Notes

### PostgreSQL
```yaml
# postgresql.conf
ssl = on
ssl_cert_file = 'server.crt'
ssl_key_file = 'server.key'
ssl_ca_file = 'ca.crt'
```

### MySQL
```yaml
# my.cnf
[mysqld]
ssl-ca=/path/to/ca.pem
ssl-cert=/path/to/server-cert.pem
ssl-key=/path/to/server-key.pem
require_secure_transport=ON
```

### Cassandra
```yaml
# cassandra.yaml
client_encryption_options:
  enabled: true
  optional: false
  keystore: /path/to/server-keystore.jks
  truststore: /path/to/server-truststore.jks
```

### Elasticsearch
```yaml
# elasticsearch.yml
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: /path/to/keystore.p12
xpack.security.http.ssl.truststore.path: /path/to/truststore.p12
```

### Kafka
```yaml
# server.properties
listeners=SASL_SSL://kafka:9093
ssl.keystore.location=/path/to/kafka.server.keystore.jks
ssl.truststore.location=/path/to/kafka.server.truststore.jks
```

This configuration provides a secure, production-ready TLS setup for all supported databases and services with proper certificate management through Kuber