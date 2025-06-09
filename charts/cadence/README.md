# cadence

![Version: 0.1.7](https://img.shields.io/badge/Version-0.1.7-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.2.16](https://img.shields.io/badge/AppVersion-1.2.16-informational?style=flat-square)

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
| cassandra.deployment.cpu.limit | string | `"500m"` |  |
| cassandra.deployment.cpu.request | string | `"500m"` |  |
| cassandra.deployment.enabled | bool | `true` | When disabled, the Cassandra deployment is expected to be provided externally. For production use cases, it is recommended to use an external Cassandra deployment. |
| cassandra.deployment.image.repository | string | `"cassandra"` |  |
| cassandra.deployment.image.tag | string | `"4.1.1"` |  |
| cassandra.deployment.memory.limit | string | `"1Gi"` |  |
| cassandra.deployment.memory.request | string | `"1Gi"` |  |
| cassandra.endpoint | string | `""` | External Cassandra endpoint to connect to. Required when cassandra.deployment.enabled is set to false |
| cassandra.schema.version | string | `"0.40"` | Cassandra schema version of the Cadence keyspace to use. Latest value can be found at https://github.com/uber/cadence/blob/master/schema/cassandra/version.go |
| cassandra.schema.visibility_version | string | `"0.9"` | Cassandra schema version of the Cadence visibility keyspace to use. Latest value can be found at https://github.com/uber/cadence/blob/master/schema/cassandra/version.go |
| dynamicConfig | object | `{"values":{"history.workflowIDExternalRateLimitEnabled":[{"value":true}]}}` | Dynamic config values to be set in the Cadence server. List of keys can be found at https://github.com/uber/cadence/blob/master/common/dynamicconfig/constants.go |
| frontend.cpu.limit | string | `"500m"` |  |
| frontend.cpu.request | string | `"500m"` |  |
| frontend.grpcPort | int | `7833` | GRPC port of cadence frontend service. DO NOT CHANGE |
| frontend.image.repository | string | `"docker.io/ubercadence/server"` | Docker image repository to use for the Cadence server |
| frontend.image.tag | string | `"v1.2.16-auto-setup"` | Docker image tag to use for the Cadence server |
| frontend.memory.limit | string | `"1Gi"` |  |
| frontend.memory.request | string | `"1Gi"` |  |
| frontend.port | int | `7933` | Tchannel port of cadence frontend service. DO NOT CHANGE |
| frontend.replicas | int | `2` | Number of frontend replicas to deploy |
| history.cpu.limit | string | `"500m"` |  |
| history.cpu.request | string | `"500m"` |  |
| history.grpcPort | int | `7834` | GRPC port of cadence history service. DO NOT CHANGE |
| history.image.repository | string | `"docker.io/ubercadence/server"` | Docker image repository to use for the Cadence server |
| history.image.tag | string | `"v1.2.16-auto-setup"` | Docker image tag to use for the Cadence server |
| history.memory.limit | string | `"1Gi"` |  |
| history.memory.request | string | `"1Gi"` |  |
| history.port | int | `7934` | Tchannel port of cadence history service. DO NOT CHANGE |
| history.replicas | int | `3` | Number of history replicas to deploy |
| log.level | string | `"debug"` |  |
| log.stdout | bool | `true` |  |
| matching.cpu.limit | string | `"500m"` |  |
| matching.cpu.request | string | `"500m"` |  |
| matching.grpcPort | int | `7835` | GRPC port of cadence matching service. DO NOT CHANGE |
| matching.image.repository | string | `"docker.io/ubercadence/server"` | Docker image repository to use for the Cadence server |
| matching.image.tag | string | `"v1.2.16-auto-setup"` | Docker image tag to use for the Cadence server |
| matching.memory.limit | string | `"1Gi"` |  |
| matching.memory.request | string | `"1Gi"` |  |
| matching.port | int | `7935` | Tchannel port of cadence matching service. DO NOT CHANGE |
| matching.replicas | int | `3` | Number of matching replicas to deploy |
| metrics.enabled | bool | `true` |  |
| metrics.port | int | `9090` |  |
| metrics.portName | string | `"metrics"` |  |
| metrics.serviceMonitor.additionalLabels | object | `{}` |  |
| metrics.serviceMonitor.annotations | object | `{}` | Annotations to be added to the ServiceMonitor. |
| metrics.serviceMonitor.enabled | bool | `false` |  |
| metrics.serviceMonitor.metricRelabelings | list | `[]` |  |
| metrics.serviceMonitor.namespace | string | `""` |  |
| metrics.serviceMonitor.namespaceSelector | object | `{}` |  |
| metrics.serviceMonitor.relabelings | list | `[]` |  |
| metrics.serviceMonitor.scrapeInterval | string | `"15s"` |  |
| metrics.serviceMonitor.targetLabels | list | `[]` |  |
| web.cpu.limit | string | `"500m"` |  |
| web.cpu.request | string | `"500m"` |  |
| web.image.repository | string | `"docker.io/ubercadence/web"` | Docker image repository to use for the Cadence Web UI |
| web.image.tag | string | `"v4.0.3"` | Docker image tag to use for the Cadence Web UI |
| web.memory.limit | string | `"1Gi"` |  |
| web.memory.request | string | `"1Gi"` |  |
| web.replicas | int | `1` |  |
| worker.cpu.limit | string | `"500m"` |  |
| worker.cpu.request | string | `"500m"` |  |
| worker.image.repository | string | `"docker.io/ubercadence/server"` | Docker image repository to use for the Cadence server |
| worker.image.tag | string | `"v1.2.16-auto-setup"` | Docker image tag to use for the Cadence server |
| worker.memory.limit | string | `"1Gi"` |  |
| worker.memory.request | string | `"1Gi"` |  |
| worker.port | int | `7939` | Tchannel port of cadence worker service. DO NOT CHANGE |
| worker.replicas | int | `1` | Number of worker replicas to deploy |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
