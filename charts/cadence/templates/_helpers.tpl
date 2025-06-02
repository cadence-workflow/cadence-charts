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
Get log configuration (with global fallback)
*/}}
{{- define "cadence.logLevel" -}}
{{- $global := .Values.global.log | default dict }}
{{- $service := .service }}
{{- $log := $service.log | default $global }}
{{- $log.level | default "info" }}
{{- end }}

{{/*
Get log stdout configuration (with global fallback)
*/}}
{{- define "cadence.logStdout" -}}
{{- $global := .Values.global.log | default dict }}
{{- $service := .service }}
{{- $log := $service.log | default $global }}
{{- $log.stdout | default true }}
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
Get HPA configuration for a service
*/}}
{{- define "cadence.hpaConfig" -}}
{{- $serviceName := .serviceName }}
{{- $hpaConfig := index .Values.autoscaling $serviceName }}
{{- toYaml $hpaConfig }}
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
Create pod annotations including service-specific annotations
*/}}
{{- define "cadence.podAnnotations" -}}
{{- $service := .service }}
{{- if $service.podAnnotations }}
{{ toYaml $service.podAnnotations }}
{{- end }}
{{- end }}

{{/*
Generate metrics port configuration
*/}}
{{- define "cadence.metricsPort" -}}
{{- if .Values.metrics.enabled }}
- name: {{ .Values.metrics.portName | default "metrics" }}
  containerPort: {{ .Values.metrics.port | default 9090 }}
  protocol: TCP
{{- end }}
{{- end }}

{{/*
Generate Ringpop seeds for service discovery
*/}}
{{- define "cadence.ringpopSeeds" -}}
{{- $seeds := list }}
{{- $namespace := .Release.Namespace }}
{{- $seeds = append $seeds (printf "cadence-frontend-headless.%s.svc.cluster.local:%d" $namespace (.Values.frontend.port | int)) }}
{{- $seeds = append $seeds (printf "cadence-history-headless.%s.svc.cluster.local:%d" $namespace (.Values.history.port | int)) }}
{{- $seeds = append $seeds (printf "cadence-matching-headless.%s.svc.cluster.local:%d" $namespace (.Values.matching.port | int)) }}
{{- $seeds = append $seeds (printf "cadence-worker-headless.%s.svc.cluster.local:%d" $namespace (.Values.worker.port | int)) }}
{{- join "," $seeds }}
{{- end }}

{{/*
Get the Cassandra endpoint
*/}}
{{- define "cassandra.endpoint" -}}
{{ .Values.cassandra.endpoint | default (printf "cassandra-service.%s.svc.cluster.local" $.Release.Namespace)  }}
{{- end -}}