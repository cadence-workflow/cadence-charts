{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "cadence.name" -}}
    {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cadence.fullname" -}}
  {{- if .Values.fullnameOverride -}}
    {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- $name := default .Chart.Name .Values.nameOverride -}}
    {{- if contains $name .Release.Name -}}
      {{- .Release.Name | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
      {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cadence.chart" -}}
    {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "cadence.labels" -}}
helm.sh/chart: {{ include "cadence.chart" . }}
{{ include "cadence.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Create service selector labels for a specific service
*/}}
{{- define "cadence.serviceLabels" -}}
{{- $serviceName := .serviceName }}
{{ include "cadence.selectorLabels" . }}
app.kubernetes.io/component: {{ $serviceName }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cadence.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cadence.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "cadence.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "cadence.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create HPA name for a service
*/}}
{{- define "cadence.hpaName" -}}
{{- $serviceName := .serviceName }}
{{- printf "%s-%s" (include "cadence.fullname" .) $serviceName }}
{{- end }}

{{/*
Check if HPA is enabled for a specific service
*/}}
{{- define "cadence.isHpaEnabled" -}}
{{- $serviceName := .serviceName }}
{{- $hpaConfig := index .Values.autoscaling $serviceName }}
{{- if $hpaConfig }}
{{- $hpaConfig.enabled | default false }}
{{- else }}
{{- false }}
{{- end }}
{{- end }}

{{/*
Generate Cassandra hostname dynamically
Replicates Bitnami's service naming logic:
- If cassandra.fullnameOverride is set, use it
- Else if cassandra.nameOverride is set, use {release-name}-{nameOverride}
- Else use {release-name}-cassandra
NOTE: If you modify the chart dependency name in Chart.yaml, set config.persistence.database.cassandra.hosts manually
*/}}
{{- define "cadence.cassandraHost" -}}
  {{- if .Values.cassandra.enabled -}}
    {{- $serviceName := "" -}}
    {{- if .Values.cassandra.fullnameOverride -}}
      {{- $serviceName = .Values.cassandra.fullnameOverride -}}
    {{- else if .Values.cassandra.nameOverride -}}
      {{- $serviceName = printf "%s-%s" .Release.Name .Values.cassandra.nameOverride -}}
    {{- else -}}
      {{- $serviceName = printf "%s-cassandra" .Release.Name -}}
    {{- end -}}
    {{- printf "%s.%s.svc.cluster.local" $serviceName .Release.Namespace -}}
  {{- else if .Values.config.persistence.database.cassandra.hosts -}}
    {{- .Values.config.persistence.database.cassandra.hosts -}}
  {{- else -}}
    {{- fail "config.persistence.database.cassandra.hosts must be set when cassandra.enabled is false" -}}
  {{- end -}}
{{- end -}}

{{/*
Generate PostgreSQL hostname dynamically
Replicates Bitnami's service naming logic:
- If postgresql.fullnameOverride is set, use it
- Else if postgresql.nameOverride is set, use {release-name}-{nameOverride}
- Else use {release-name}-postgresql
*/}}
{{- define "cadence.postgresqlHost" -}}
  {{- if .Values.postgresql.enabled -}}
    {{- $serviceName := "" -}}
    {{- if .Values.postgresql.fullnameOverride -}}
      {{- $serviceName = .Values.postgresql.fullnameOverride -}}
    {{- else if .Values.postgresql.nameOverride -}}
      {{- $serviceName = printf "%s-%s" .Release.Name .Values.postgresql.nameOverride -}}
    {{- else -}}
      {{- $serviceName = printf "%s-postgresql" .Release.Name -}}
    {{- end -}}
    {{- printf "%s.%s.svc.cluster.local" $serviceName .Release.Namespace -}}
  {{- else if .Values.config.persistence.database.sql.hosts -}}
    {{- .Values.config.persistence.database.sql.hosts -}}
  {{- else -}}
    {{- fail "config.persistence.database.sql.hosts must be set when postgresql.enabled is false" -}}
  {{- end -}}
{{- end -}}

{{/*
Generate MySQL hostname dynamically
Replicates Bitnami's service naming logic:
- If mysql.fullnameOverride is set, use it
- Else if mysql.nameOverride is set, use {release-name}-{nameOverride}
- Else use {release-name}-mysql
*/}}
{{- define "cadence.mysqlHost" -}}
  {{- if .Values.mysql.enabled -}}
    {{- $serviceName := "" -}}
    {{- if .Values.mysql.fullnameOverride -}}
      {{- $serviceName = .Values.mysql.fullnameOverride -}}
    {{- else if .Values.mysql.nameOverride -}}
      {{- $serviceName = printf "%s-%s" .Release.Name .Values.mysql.nameOverride -}}
    {{- else -}}
      {{- $serviceName = printf "%s-mysql" .Release.Name -}}
    {{- end -}}
    {{- printf "%s.%s.svc.cluster.local" $serviceName .Release.Namespace -}}
  {{- else if .Values.config.persistence.database.sql.hosts -}}
    {{- .Values.config.persistence.database.sql.hosts -}}
  {{- else -}}
    {{- fail "config.persistence.database.sql.hosts must be set when mysql.enabled is false" -}}
  {{- end -}}
{{- end -}}

{{/*
Generate SQL database hostname dynamically (PostgreSQL or MySQL based on driver)
*/}}
{{- define "cadence.sqlHost" -}}
  {{- if eq .Values.config.persistence.database.driver "postgres" -}}
  {{- include "cadence.postgresqlHost" . -}}
  {{- else if eq .Values.config.persistence.database.driver "mysql" -}}
  {{- include "cadence.mysqlHost" . -}}
  {{- else -}}
  {{- .Values.config.persistence.database.sql.hosts | default "" -}}
  {{- end -}}
{{- end -}}

{{/*
Generate Elasticsearch hostname dynamically
Replicates Bitnami's service naming logic:
- If elasticsearch.fullnameOverride is set, use it
- Else if elasticsearch.nameOverride is set, use {release-name}-{nameOverride}
- Else use {release-name}-elasticsearch
NOTE: If you modify the chart dependency name in Chart.yaml, set config.persistence.elasticsearch.hosts manually
*/}}
{{- define "cadence.elasticsearchHost" -}}
  {{- if .Values.elasticsearch.enabled -}}
    {{- $serviceName := "" -}}
    {{- if .Values.elasticsearch.fullnameOverride -}}
      {{- $serviceName = .Values.elasticsearch.fullnameOverride -}}
    {{- else if .Values.elasticsearch.nameOverride -}}
      {{- $serviceName = printf "%s-%s" .Release.Name .Values.elasticsearch.nameOverride -}}
    {{- else -}}
      {{- $serviceName = printf "%s-elasticsearch" .Release.Name -}}
    {{- end -}}
    {{- printf "%s.%s.svc.cluster.local" $serviceName .Release.Namespace -}}
  {{- else if .Values.config.persistence.elasticsearch.hosts -}}
    {{- .Values.config.persistence.elasticsearch.hosts -}}
  {{- else -}}
    {{- fail "config.persistence.elasticsearch.hosts must be set when elasticsearch.enabled is false" -}}
  {{- end -}}
{{- end -}}

{{/*
Generate OpenSearch hostname dynamically
Replicates OpenSearch chart's opensearch.masterService logic:
- If masterService is set, use it
- Else if fullnameOverride is set, use it (no -master suffix)
- Else if nameOverride is set, use {nameOverride}-master
- Else use {clusterName}-master (defaults to opensearch-cluster-master)
NOTE: If you modify the chart dependency name in Chart.yaml, set config.persistence.elasticsearch.hosts manually
*/}}
{{- define "cadence.opensearchHost" -}}
  {{- if .Values.opensearch.enabled -}}
    {{- $serviceName := "" -}}
    {{- if .Values.opensearch.masterService -}}
      {{- $serviceName = .Values.opensearch.masterService -}}
    {{- else if .Values.opensearch.fullnameOverride -}}
      {{- $serviceName = .Values.opensearch.fullnameOverride -}}
    {{- else if .Values.opensearch.nameOverride -}}
      {{- $serviceName = printf "%s-master" .Values.opensearch.nameOverride -}}
    {{- else -}}
      {{- $clusterName := .Values.opensearch.clusterName | default "opensearch-cluster" -}}
      {{- $serviceName = printf "%s-master" $clusterName -}}
    {{- end -}}
    {{- printf "%s.%s.svc.cluster.local" $serviceName .Release.Namespace -}}
  {{- else if .Values.config.persistence.elasticsearch.hosts -}}
    {{- .Values.config.persistence.elasticsearch.hosts -}}
  {{- else -}}
    {{- fail "config.persistence.elasticsearch.hosts must be set when opensearch.enabled is false" -}}
  {{- end -}}
{{- end -}}

{{/*
Generate search engine hostname (Elasticsearch or OpenSearch)
Automatically detects which is enabled
Fails if both are enabled simultaneously
If both are disabled but search is needed, requires manual hosts configuration
*/}}
{{- define "cadence.searchHost" -}}
  {{- if and .Values.elasticsearch.enabled .Values.opensearch.enabled -}}
    {{- fail "Cannot enable both elasticsearch.enabled and opensearch.enabled. Choose one." -}}
  {{- else if .Values.elasticsearch.enabled -}}
  {{- include "cadence.elasticsearchHost" . -}}
  {{- else if .Values.opensearch.enabled -}}
  {{- include "cadence.opensearchHost" . -}}
  {{- else -}}
    {{- if .Values.config.persistence.elasticsearch.enabled -}}
      {{- if not .Values.config.persistence.elasticsearch.hosts -}}
        {{- fail "config.persistence.elasticsearch.hosts must be set when both elasticsearch.enabled and opensearch.enabled are false but search is enabled" -}}
      {{- end -}}
    {{- end -}}
    {{- .Values.config.persistence.elasticsearch.hosts | default "" -}}
  {{- end -}}
{{- end -}}

{{/*
Generate Kafka broker hostname dynamically
Replicates Bitnami's service naming logic:
- If kafka.fullnameOverride is set, use it
- Else if kafka.nameOverride is set, use {release-name}-{nameOverride}
- Else use {release-name}-kafka
NOTE: If you modify the chart dependency name in Chart.yaml, set config.kafka.brokers manually
*/}}
{{- define "cadence.kafkaBroker" -}}
  {{- if .Values.kafka.enabled -}}
    {{- $serviceName := "" -}}
    {{- if .Values.kafka.fullnameOverride -}}
      {{- $serviceName = .Values.kafka.fullnameOverride -}}
    {{- else if .Values.kafka.nameOverride -}}
      {{- $serviceName = printf "%s-%s" .Release.Name .Values.kafka.nameOverride -}}
    {{- else -}}
      {{- $serviceName = printf "%s-kafka" .Release.Name -}}
    {{- end -}}
    {{- printf "%s.%s.svc.cluster.local" $serviceName .Release.Namespace -}}
  {{- else if .Values.config.kafka.brokers -}}
    {{- .Values.config.kafka.brokers -}}
  {{- else -}}
    {{- fail "config.kafka.brokers must be set when kafka.enabled is false" -}}
  {{- end -}}
{{- end -}}

{{/*
Helper to generate database and service secrets based on configuration
Receives context as parameter
*/}}
{{- define "cadence.databaseSecrets" -}}
{{- $context := . -}}
{{- $secrets := list -}}

{{- /* Cassandra password */ -}}
{{- if and (eq $context.Values.config.persistence.database.driver "cassandra") $context.Values.config.persistence.database.cassandra.password -}}
{{- $secrets = append $secrets (dict "name" "CASSANDRA_PASSWORD" "value" $context.Values.config.persistence.database.cassandra.password) -}}
{{- end -}}

{{- /* MySQL password */ -}}
{{- if and (eq $context.Values.config.persistence.database.driver "mysql") $context.Values.config.persistence.database.sql.password -}}
{{- $secrets = append $secrets (dict "name" "MYSQL_PWD" "value" $context.Values.config.persistence.database.sql.password) -}}
{{- end -}}

{{- /* PostgreSQL password */ -}}
{{- if and (eq $context.Values.config.persistence.database.driver "postgres") $context.Values.config.persistence.database.sql.password -}}
{{- $secrets = append $secrets (dict "name" "POSTGRES_PWD" "value" $context.Values.config.persistence.database.sql.password) -}}
{{- end -}}

{{- /* Elasticsearch password */ -}}
{{- if and $context.Values.config.persistence.elasticsearch.enabled $context.Values.config.persistence.elasticsearch.password -}}
{{- $secrets = append $secrets (dict "name" "ES_PWD" "value" $context.Values.config.persistence.elasticsearch.password) -}}
{{- end -}}

{{- /* Kafka SASL password */ -}}
{{- if and $context.Values.config.kafka.enabled $context.Values.config.kafka.sasl.enabled $context.Values.config.kafka.sasl.password -}}
{{- $secrets = append $secrets (dict "name" "SASL_PASSWORD" "value" $context.Values.config.kafka.sasl.password) -}}
{{- end -}}

{{- /* Store secrets in a shared variable using a unique key */ -}}
{{- $_ := set $context "databaseSecrets" $secrets -}}
{{- end -}}

{/*
Cadence GRPC Peers endpoint
*/}}
{{- define "cadence.grpcPeers" -}}
{{ include "cadence.fullname" . }}-frontend.{{ .Release.Namespace }}.svc.cluster.local:{{ .Values.frontend.grpcPort | default 7833 }}
{{- end }}