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
Get image configuration for Cadence services (with global fallback)
*/}}
{{- define "cadence.image" -}}
{{- $global := .Values.global.image | default dict }}
{{- $service := .service }}
{{- $repository := $service.repository | default $global.repository }}
{{- $tag := $service.tag | default $global.tag }}
{{- $pullPolicy := $service.pullPolicy | default $global.pullPolicy | default "IfNotPresent" }}
{{- printf "%s:%s" $repository $tag }}
{{- end }}

{{/*
Get image pull policy for Cadence services
*/}}
{{- define "cadence.imagePullPolicy" -}}
{{- $global := .Values.global.image | default dict }}
{{- $service := .service }}
{{- $pullPolicy := $service.pullPolicy | default $global.pullPolicy | default "IfNotPresent" }}
{{- $pullPolicy }}
{{- end }}

{{/*
Get security context (with global fallback)
*/}}
{{- define "cadence.securityContext" -}}
{{- $global := .Values.global.securityContext | default dict }}
{{- $service := .service }}
{{- $securityContext := $service.securityContext | default $global }}
{{- toYaml $securityContext }}
{{- end }}

{{/*
Get pod security context (with global fallback)
*/}}
{{- define "cadence.podSecurityContext" -}}
{{- $global := .Values.global.podSecurityContext | default dict }}
{{- $service := .service }}
{{- $podSecurityContext := $service.podSecurityContext | default $global }}
{{- toYaml $podSecurityContext }}
{{- end }}

{{/*
Get container security context (with global fallback)
*/}}
{{- define "cadence.containerSecurityContext" -}}
{{- $global := .Values.global.containerSecurityContext | default dict }}
{{- $service := .service }}
{{- $containerSecurityContext := $service.containerSecurityContext | default $global }}
{{- toYaml $containerSecurityContext }}
{{- end }}

{{/*
Get affinity (with global fallback)
*/}}
{{- define "cadence.affinity" -}}
{{- $global := .Values.global.affinity | default dict }}
{{- $service := .service }}
{{- $affinity := $service.affinity | default $global }}
{{- toYaml $affinity }}
{{- end }}

{{/*
Get tolerations (with global fallback)
*/}}
{{- define "cadence.tolerations" -}}
{{- $global := .Values.global.tolerations | default list }}
{{- $service := .service }}
{{- $tolerations := $service.tolerations | default $global }}
{{- toYaml $tolerations }}
{{- end }}

{{/*
Get node selector (with global fallback)
*/}}
{{- define "cadence.nodeSelector" -}}
{{- $global := .Values.global.nodeSelector | default dict }}
{{- $service := .service }}
{{- $nodeSelector := $service.nodeSelector | default $global }}
{{- toYaml $nodeSelector }}
{{- end }}

{{/*
Get image pull secrets (with global fallback)
*/}}
{{- define "cadence.imagePullSecrets" -}}
{{- $global := .Values.global.imagePullSecrets | default list }}
{{- $service := .service }}
{{- $imagePullSecrets := $service.imagePullSecrets | default $global }}
{{- toYaml $imagePullSecrets }}
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
Get priority class name (with global fallback)
*/}}
{{- define "cadence.priorityClassName" -}}
{{- $global := .Values.global.priorityClassName | default "" }}
{{- $service := .service }}
{{- $priorityClassName := $service.priorityClassName | default $global }}
{{- $priorityClassName }}
{{- end }}

{{/*
Get topology spread constraints (with global fallback)
*/}}
{{- define "cadence.topologySpreadConstraints" -}}
{{- $global := .Values.global.topologySpreadConstraints | default list }}
{{- $service := .service }}
{{- $topologySpreadConstraints := $service.topologySpreadConstraints | default $global }}
{{- toYaml $topologySpreadConstraints }}
{{- end }}

{{/*
Get environment variables (merge global and service specific)
*/}}
{{- define "cadence.env" -}}
{{- $global := .Values.global.env | default list }}
{{- $service := .service }}
{{- $serviceEnv := $service.env | default list }}
{{- $mergedEnv := concat $global $serviceEnv }}
{{- toYaml $mergedEnv }}
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
Create pod labels including service-specific labels
*/}}
{{- define "cadence.podLabels" -}}
{{- $serviceName := .serviceName }}
{{- $service := .service }}
{{ include "cadence.serviceLabels" (dict "serviceName" $serviceName "Values" .Values "Chart" .Chart "Release" .Release) }}
{{- if $service.podLabels }}
{{ toYaml $service.podLabels }}
{{- end }}
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