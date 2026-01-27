
Otel Contrib Installation in K8s
---------------------------------

High level architecture looks like this:

Instrumentation SDKs --> Otel Contrib Collector --> EDOT Gateway Collector (not required if mOLTP endpoint is available) --> Elasticsearch endpoint

1 - Install opentelemetry helm charts
---------------------------------------
```
helm repo add open-telemetry 'https://open-telemetry.github.io/opentelemetry-helm-charts' --force-update
```

2 - Create a namespace
------------------------
```
kubectl create namespace otel-contrib
```

3 - Create a secret to store elasticsearch endpoint and api key
----------------------------------------------------------------
```
kubectl create secret generic elastic-secret-otel --namespace otel-contrib --from-literal=elastic_endpoint='<ELASTICSEARCH_ENDPOINT>' --from-literal=elastic_api_key='<ELASTICSEARCH_API_KEY>'
```

Check :
```
kubectl get secret -A
```

> You should see "elastic-secret-otel" and "opentelemetry-kube-stack-opentelemetry-operator-controller-manager-service-cert"


4 - Install opentelemetry-kube-stack to install opentelemetry-operator and EDOT gateway collector, with EDOT daemon collector and EDOT cluster collector disabled
------------------------------------------------------------------------------------------------------------------------------------------------------------------
```
helm upgrade --install opentelemetry-kube-stack open-telemetry/opentelemetry-kube-stack --namespace otel-contrib --values 'https://raw.githubusercontent.com/ramp-km/rkm-otel-configs/refs/heads/main/edot/edot-values.yaml' --set collectors.daemon.enabled=false --set collectors.cluster.enabled=false
```


Check :
```
kubectl get pods -n otel-contrib
```

> You should see kube-stack-opentelemetry-operator & kube-stack-gateway-collector


5 - Install otel contrib daemon collector
------------------------------------------
Use default otel contrib values yaml and a collector config values yaml. Default otel contrib values yaml has basic config and collector config values yaml has configuration to enable commonly used receivers, processors and exporters

```
helm upgrade --install opentelemetry-collector open-telemetry/opentelemetry-collector --values 'https://raw.githubusercontent.com/ramp-km/rkm-otel-configs/refs/heads/main/otel-contrib/opentelemetry-contrib-values.yaml' --values 'https://raw.githubusercontent.com/ramp-km/rkm-otel-configs/refs/heads/main/otel-contrib/collector-config.yaml' --namespace otel-contrib
```


Check :
```
kubectl get pods -n otel-contrib
```

> You should see opentelemetry-collector-agent

6 - Validate that other things are in place
--------------------------------------------

```
kubectl get otelinst -n otel-contrib
```

> You should see elastic-instrumentation (edot) and otel-instrumentation (otel contrib)

```
kubectl get crds
```

> You should see instrumentations.opentelemetry.io, opampbridges.opentelemetry.io, opentelemetrycollectors.opentelemetry.io and targetallocators.opentelemetry.io

```
kubectl get mutatingwebhookconfiguration
```

> You should see opentelemetry-kube-stack-opentelemetry-operator-mutation
