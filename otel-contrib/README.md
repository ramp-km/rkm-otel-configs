Two values.yaml files are used to setup opentelemetry-collector-contrib.

1. **opentelemetry-contrib-values.yaml** - This has the default configuration for opentelemetry-collector-contrib
2. **collector-config.yaml** - This has the configuration to setup common components that are necessary to get started
  - presets: to enable logsCollection, hostMetrics, kubernetesAttributes, kubernetesEvents, clusterMetrics
  - config: commonly needed receivers, processors and exporters + pipelines.
  - extraManifests : to define instrumentation with opentelemetry-contrib SDKs
  - clusterRole
