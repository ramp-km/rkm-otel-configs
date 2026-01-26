**edot-values.yaml has the configuration for the below components:**

1. opentelemetry-operator
2. CRDs - Custom Resource Definitions
3. ClusterRole
4. Collectors
  - cluster : cluster is a K8s deployment EDOT collector focused on gathering telemetry at the cluster level (Kubernetes Events and cluster metrics).
  - daemon :  daemon is a K8s daemonset EDOT collector focused on gathering telemetry at node level and exposing an OTLP endpoint for data ingestion. Auto-instrumentation SDKs will use this endpoint. daemon generally forwards data to gateway
  - gateway : gateway is a K8s deployment / daemonset EDOT collector focused on processing and forwarding telemetry to an Elasticsearch endpoint.
5. Instrumentation
