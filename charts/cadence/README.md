# cadence

![Version: 0.1.8](https://img.shields.io/badge/Version-0.1.8-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.2.16](https://img.shields.io/badge/AppVersion-1.2.16-informational?style=flat-square)

Cadence is a distributed, scalable, durable, and highly available orchestration engine
to execute asynchronous long-running business logic in a scalable and resilient way.
This chart deploys Uber Cadence server components and web UI.

**Homepage:** <https://cadenceworkflow.io/>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Cadence Community |  | <https://github.com/cadence-workflow/cadence-charts> |

## Source Code

* <https://github.com/cadence-workflow/cadence>
* <https://github.com/cadence-workflow/cadence-web>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| autoscaling.frontend | object | `{"enabled":false,"maxReplicas":10,"minReplicas":2,"targetCPUUtilizationPercentage":70,"targetMemoryUtilizationPercentage":80}` | Enable HPA for frontend service |
| autoscaling.history | object | `{"enabled":false,"maxReplicas":15,"minReplicas":3,"targetCPUUtilizationPercentage":70,"targetMemoryUtilizationPercentage":80}` | Enable HPA for history service |
| autoscaling.matching | object | `{"enabled":false,"maxReplicas":15,"minReplicas":3,"targetCPUUtilizationPercentage":70,"targetMemoryUtilizationPercentage":80}` | Enable HPA for matching service |
| autoscaling.worker | object | `{"enabled":false,"maxReplicas":15,"minReplicas":3,"targetCPUUtilizationPercentage":70,"targetMemoryUtilizationPercentage":80}` | Enable HPA for worker service |
| cassandra.deployment.enabled | bool | `true` | When disabled, the Cassandra deployment is expected to be provided externally |
| cassandra.deployment.image.pullPolicy | string | `"IfNotPresent"` |  |
| cassandra.deployment.image.repository | string | `"cassandra"` |  |
| cassandra.deployment.image.tag | string | `"4.1.1"` |  |
| cassandra.deployment.resources | object | `{"limits":{"cpu":1,"memory":"2Gi"},"requests":{"cpu":"500m","memory":"1Gi"}}` | Resource limits and requests for Cassandra |
| cassandra.endpoint | string | `""` | External Cassandra endpoint to connect to. Required when cassandra.deployment.enabled is set to false |
| cassandra.schema.version | string | `"0.40"` | Cassandra schema version of the Cadence keyspace to use |
| cassandra.schema.visibility_version | string | `"0.9"` | Cassandra schema version of the Cadence visibility keyspace to use |
| dynamicConfig.values | object | `{"history.workflowIDExternalRateLimitEnabled":[{"value":true}]}` | Dynamic config values to be set in the Cadence server List of keys can be found at https://pkg.go.dev/github.com/uber/cadence@v1.3.0/common/dynamicconfig/dynamicproperties |
| frontend.affinity | object | `{}` | Affinity rules (inherits from global if not specified) |
| frontend.containerSecurityContext | object | `{}` | Container security context (inherits from global if not specified) |
| frontend.env | list | `[]` | Environment variables for frontend service |
| frontend.grpcPort | int | `7833` | GRPC port of cadence frontend service. DO NOT CHANGE |
| frontend.image | object | `{}` | Image configuration (inherits from global if not specified) |
| frontend.log | object | `{}` | Logging configuration (inherits from global log if not specified) |
| frontend.nodeSelector | object | `{}` | Node selector (inherits from global if not specified) |
| frontend.podAnnotations | object | `{}` | Additional pod annotations |
| frontend.podDisruptionBudget | object | `{"enabled":false,"minAvailable":1}` | Pod Disruption Budget |
| frontend.podLabels | object | `{}` | Additional pod labels |
| frontend.podSecurityContext | object | `{}` | Pod security context (inherits from global if not specified) |
| frontend.port | int | `7933` | Tchannel port of cadence frontend service. DO NOT CHANGE |
| frontend.priorityClassName | string | `""` | Priority class name for pod scheduling (inherits from global if not specified) |
| frontend.replicas | int | `1` | Number of frontend replicas to deploy |
| frontend.resources | object | `{}` | Resource limits and requests |
| frontend.secretEnv | list | `[]` | Secret environment variables for frontend service |
| frontend.strategy | object | `{"type":"RollingUpdate"}` | Deployment strategy for frontend service |
| frontend.tolerations | list | `[]` | Tolerations (inherits from global if not specified) |
| frontend.topologySpreadConstraints | list | `[]` | Topology spread constraints (inherits from global if not specified) |
| fullnameOverride | string | `nil` | Provide a name to override the full names of resources |
| global.affinity | object | `{}` | Global affinity rules |
| global.containerSecurityContext | object | `{}` | Global container security context |
| global.env | list | `[{"name":"ENABLE_ES","value":"false"},{"name":"SKIP_SCHEMA_SETUP","value":"true"},{"name":"RINGPOP_BOOTSTRAP_MODE","value":"dns"}]` | Global environment variables (shared only by Cadence Server services [frontend, worker, matching and history]) |
| global.image | object | `{"pullPolicy":"IfNotPresent","repository":"docker.io/ubercadence/server","tag":"v1.2.16-auto-setup"}` | Global image configuration (shared only by Cadence Server services [frontend, worker, matching and history]) |
| global.imagePullSecrets | list | `[]` | Image pull secrets for private registries |
| global.log | object | `{"level":"info","stdout":true}` | Global logging configuration (shared only by Cadence Server services [frontend, worker, matching and history]) |
| global.log.level | string | `"info"` | Logging level (debug, info, warn, error) |
| global.log.stdout | bool | `true` | Enable stdout logging |
| global.nodeSelector | object | `{}` | Global node selector |
| global.podSecurityContext | object | `{}` | Global pod security context |
| global.priorityClassName | string | `""` | Global priority class name for pod scheduling |
| global.secretEnv | list | `[]` | Global secret environment variables (shared only by Cadence Server services [frontend, worker, matching and history]) |
| global.tolerations | list | `[]` | Global tolerations |
| global.topologySpreadConstraints | list | `[]` | Global topology spread constraints |
| history.affinity | object | `{}` | Affinity rules (inherits from global if not specified) |
| history.containerSecurityContext | object | `{}` | Container security context (inherits from global if not specified) |
| history.env | list | `[]` | Environment variables for history service |
| history.grpcPort | int | `7834` | GRPC port of cadence history service. DO NOT CHANGE |
| history.image | object | `{}` | Image configuration (inherits from global if not specified) |
| history.log | object | `{}` | Logging configuration (inherits from global log if not specified) |
| history.nodeSelector | object | `{}` | Node selector (inherits from global if not specified) |
| history.podAnnotations | object | `{}` | Additional pod annotations |
| history.podDisruptionBudget | object | `{"enabled":false,"minAvailable":2}` | Pod Disruption Budget |
| history.podLabels | object | `{}` | Additional pod labels |
| history.podSecurityContext | object | `{}` | Pod security context (inherits from global if not specified) |
| history.port | int | `7934` | Tchannel port of cadence history service. DO NOT CHANGE |
| history.priorityClassName | string | `""` | Priority class name for pod scheduling (inherits from global if not specified) |
| history.replicas | int | `1` | Number of history replicas to deploy |
| history.resources | object | `{}` | Resource limits and requests |
| history.secretEnv | list | `[]` | Secret environment variables for history service |
| history.strategy | object | `{"type":"RollingUpdate"}` | Deployment strategy for history service |
| history.tolerations | list | `[]` | Tolerations (inherits from global if not specified) |
| history.topologySpreadConstraints | list | `[]` | Topology spread constraints (inherits from global if not specified) |
| matching.affinity | object | `{}` | Affinity rules (inherits from global if not specified) |
| matching.containerSecurityContext | object | `{}` | Container security context (inherits from global if not specified) |
| matching.env | list | `[]` | Environment variables for matching service |
| matching.grpcPort | int | `7835` | GRPC port of cadence matching service. DO NOT CHANGE |
| matching.image | object | `{}` | Image configuration (inherits from global if not specified) |
| matching.log | object | `{}` | Logging configuration (inherits from global log if not specified) |
| matching.nodeSelector | object | `{}` | Node selector (inherits from global if not specified) |
| matching.podAnnotations | object | `{}` | Additional pod annotations |
| matching.podDisruptionBudget | object | `{"enabled":false,"minAvailable":2}` | Pod Disruption Budget |
| matching.podLabels | object | `{}` | Additional pod labels |
| matching.podSecurityContext | object | `{}` | Pod security context (inherits from global if not specified) |
| matching.port | int | `7935` | Tchannel port of cadence matching service. DO NOT CHANGE |
| matching.priorityClassName | string | `""` | Priority class name for pod scheduling (inherits from global if not specified) |
| matching.replicas | int | `1` | Number of matching replicas to deploy |
| matching.resources | object | `{}` | Resource limits and requests |
| matching.secretEnv | list | `[]` | Secret environment variables for matching service |
| matching.strategy | object | `{"type":"RollingUpdate"}` | Deployment strategy for matching service |
| matching.tolerations | list | `[]` | Tolerations (inherits from global if not specified) |
| matching.topologySpreadConstraints | list | `[]` | Topology spread constraints (inherits from global if not specified) |
| metrics.enabled | bool | `true` | Enable metrics collection |
| metrics.port | int | `9090` | Metrics port |
| metrics.portName | string | `"metrics"` | Metrics port name |
| metrics.serviceMonitor.additionalLabels | object | `{}` | Additional labels for ServiceMonitor |
| metrics.serviceMonitor.annotations | object | `{}` | Annotations for ServiceMonitor |
| metrics.serviceMonitor.enabled | bool | `false` | Enable ServiceMonitor creation |
| metrics.serviceMonitor.jobLabel | string | `""` | Joblabel for ServiceMonitor |
| metrics.serviceMonitor.metricRelabelings | list | `[]` | Metric relabeling configs |
| metrics.serviceMonitor.namespace | string | `""` | Namespace for ServiceMonitor (defaults to release namespace) |
| metrics.serviceMonitor.namespaceSelector | list | `[]` | Namespace selector for ServiceMonitor |
| metrics.serviceMonitor.relabelings | list | `[]` | Relabeling configs |
| metrics.serviceMonitor.scrapeInterval | string | `"15s"` | Scrape interval |
| metrics.serviceMonitor.targetLabels | list | `[]` | Target labels to be added |
| nameOverride | string | `nil` | Provide a name to override the name of the chart |
| networkPolicy.egress | list | `[]` | Egress rules |
| networkPolicy.enabled | bool | `false` | Enable network policies |
| networkPolicy.ingress | list | `[]` | Ingress rules |
| rbac.create | bool | `false` | Enable RBAC creation |
| serviceAccount.annotations | object | `{}` | Annotations for service account |
| serviceAccount.automountServiceAccountToken | bool | `true` | Automatically mount service account token |
| serviceAccount.create | bool | `true` | Enable service account creation |
| serviceAccount.name | string | `""` | Service account name (generated if not set) |
| web.affinity | object | `{}` | Affinity rules (inherits from global if not specified) |
| web.containerSecurityContext | object | `{}` | Container security context (inherits from global if not specified) |
| web.env | list | `[{"name":"CADENCE_WEB_PORT","value":"8088"}]` | Environment variables for web UI |
| web.image | object | `{"imagePullSecrets":[],"pullPolicy":"IfNotPresent","repository":"docker.io/ubercadence/web","tag":"v4.0.3"}` | Image configuration for Web UI |
| web.ingress.annotations | object | `{}` | Ingress annotations |
| web.ingress.className | string | `""` | Ingress class name |
| web.ingress.enabled | bool | `false` | Enable ingress |
| web.ingress.hosts | list | `[]` | Ingress hosts configuration |
| web.ingress.tls | list | `[]` | TLS configuration |
| web.nodeSelector | object | `{}` | Node selector (inherits from global if not specified) |
| web.podAnnotations | object | `{}` | Additional pod annotations |
| web.podDisruptionBudget | object | `{"enabled":false,"minAvailable":1}` | Pod Disruption Budget |
| web.podLabels | object | `{}` | Additional pod labels |
| web.podSecurityContext | object | `{}` | Pod security context (inherits from global if not specified) |
| web.priorityClassName | string | `""` | Priority class name for pod scheduling (inherits from global if not specified) |
| web.replicas | int | `1` | Number of web UI replicas to deploy |
| web.resources | object | `{}` | Resource limits and requests |
| web.secretEnv | list | `[]` | Secret environment variables for web UI |
| web.service.annotations | object | `{}` | Service annotations |
| web.service.loadBalancerIP | string | `nil` | LoadBalancer IP (only if type is LoadBalancer) |
| web.service.loadBalancerSourceRanges | list | `[]` | LoadBalancer source ranges (only if type is LoadBalancer) |
| web.service.nodePort | string | `nil` | NodePort (only if type is NodePort) |
| web.service.port | int | `8088` | Service port |
| web.service.type | string | `"ClusterIP"` | Service type (ClusterIP, NodePort, LoadBalancer) |
| web.strategy | object | `{"type":"RollingUpdate"}` | Deployment strategy for web UI |
| web.tolerations | list | `[]` | Tolerations (inherits from global if not specified) |
| web.topologySpreadConstraints | list | `[]` | Topology spread constraints (inherits from global if not specified) |
| worker.affinity | object | `{}` | Affinity rules (inherits from global if not specified) |
| worker.containerSecurityContext | object | `{}` | Container security context (inherits from global if not specified) |
| worker.env | list | `[]` | Environment variables for worker service |
| worker.image | object | `{}` | Image configuration (inherits from global if not specified) |
| worker.log | object | `{}` | Logging configuration (inherits from global log if not specified) |
| worker.nodeSelector | object | `{}` | Node selector (inherits from global if not specified) |
| worker.podAnnotations | object | `{}` | Additional pod annotations |
| worker.podDisruptionBudget | object | `{"enabled":false,"minAvailable":1}` | Pod Disruption Budget |
| worker.podLabels | object | `{}` | Additional pod labels |
| worker.podSecurityContext | object | `{}` | Pod security context (inherits from global if not specified) |
| worker.port | int | `7939` | Tchannel port of cadence worker service. DO NOT CHANGE |
| worker.priorityClassName | string | `""` | Priority class name for pod scheduling (inherits from global if not specified) |
| worker.replicas | int | `1` | Number of worker replicas to deploy |
| worker.resources | object | `{}` | Resource limits and requests |
| worker.secretEnv | list | `[]` | Secret environment variables for worker service |
| worker.strategy | object | `{"type":"RollingUpdate"}` | Deployment strategy for worker service |
| worker.tolerations | list | `[]` | Tolerations (inherits from global if not specified) |
| worker.topologySpreadConstraints | list | `[]` | Topology spread constraints (inherits from global if not specified) |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
