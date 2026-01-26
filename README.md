EDOT Installation
------------------
Follow guided instructions in Kibana



Otel Contrib Installation in K8s
---------------------------------

High level architecture looks like this:

Instrumentation SDKs --> Otel Contrib Collector --> EDOT Gateway Collector (not required if mOLTP endpoint is available) --> Elasticsearch endpoint

1 - Install opentelemetry helm charts
---------------------------------------
helm repo add open-telemetry 'https://open-telemetry.github.io/opentelemetry-helm-charts' --force-update

2 - Create a namespace
------------------------
kubectl create namespace otel-contrib

3 - Create a secret to store elasticsearch endpoint and api key
----------------------------------------------------------------
kubectl create secret generic elastic-secret-otel \
  --namespace otel-contrib \
  --from-literal=elastic_endpoint='<ELASTICSEARCH_ENDPOINT>' \
  --from-literal=elastic_api_key='<ELASTICSEARCH_API_KEY>'
    
kubectl get secret -A
NAMESPACE      NAME                                                                              TYPE                 DATA   AGE
otel-contrib   elastic-secret-otel                                                               Opaque               2      2m45s
otel-contrib   opentelemetry-kube-stack-opentelemetry-operator-controller-manager-service-cert   kubernetes.io/tls    3      2m17s
otel-contrib   sh.helm.release.v1.opentelemetry-kube-stack.v1                                    helm.sh/release.v1   1      2m17s

4 - Install opentelemetry-kube-stack to install opentelemetry-operator and EDOT gateway collector, with EDOT daemon collector and EDOT cluster collector disabled
------------------------------------------------------------------------------------------------------------------------------------------------------------------
helm upgrade --install opentelemetry-kube-stack open-telemetry/opentelemetry-kube-stack \
  --namespace otel-contrib \
  --values 'https://raw.githubusercontent.com/ramp-km/rkm-otel-configs/refs/heads/main/edot/edot-values.yaml' \
  --set collectors.daemon.enabled=false --set collectors.cluster.enabled=false

kubectl get pods -n otel-contrib
NAME                                                              READY   STATUS    RESTARTS   AGE
opentelemetry-kube-stack-gateway-collector-84d64bf45b-fdg2n       1/1     Running   0          5m50s
opentelemetry-kube-stack-gateway-collector-84d64bf45b-s57v4       1/1     Running   0          5m51s
opentelemetry-kube-stack-opentelemetry-operator-54b96976f5w6grt   2/2     Running   0          5m52s

5 - Install otel contrib daemon collector
------------------------------------------
Use default otel contrib values yaml and a collector config values yaml. Default otel contrib values yaml has basic config and collector config values yaml has configuration to enable commonly used receivers, processors and exporters

helm upgrade --install opentelemetry-collector open-telemetry/opentelemetry-collector \
     --values 'https://raw.githubusercontent.com/ramp-km/rkm-otel-configs/refs/heads/main/otel-contrib/opentelemetry-contrib-values.yaml' \
     --values 'https://raw.githubusercontent.com/ramp-km/rkm-otel-configs/refs/heads/main/otel-contrib/collector-config.yaml' \
     --namespace otel-contrib

kubectl get pods -n otel-contrib
NAME                                                              READY   STATUS    RESTARTS   AGE
opentelemetry-collector-agent-4d9p7                               1/1     Running   0          40s
opentelemetry-collector-agent-nflsk                               1/1     Running   0          40s
opentelemetry-kube-stack-gateway-collector-84d64bf45b-fdg2n       1/1     Running   0          7m49s
opentelemetry-kube-stack-gateway-collector-84d64bf45b-s57v4       1/1     Running   0          7m50s
opentelemetry-kube-stack-opentelemetry-operator-54b96976f5w6grt   2/2     Running   0          7m51s

6 - Other things that need to be in place
------------------------------------------
kubectl get otelinst -n otel-contrib
NAME                      AGE     ENDPOINT                                                                                                SAMPLER                    SAMPLER ARG
elastic-instrumentation   14m     http://opentelemetry-kube-stack-daemon-collector.opentelemetry-operator-system.svc.cluster.local:4318   parentbased_traceidratio   1.0
otel-instrumentation      7m46s   http://opentelemetry-collector:4318                                                                     parentbased_traceidratio   1

kubectl get crds
NAME                                            CREATED AT
applicationnetworkpolicies.networking.k8s.aws   2026-01-26T09:14:15Z
clusternetworkpolicies.networking.k8s.aws       2026-01-26T09:14:16Z
clusterpolicyendpoints.networking.k8s.aws       2026-01-26T09:14:16Z
cninodes.vpcresources.k8s.aws                   2026-01-26T09:14:16Z
eniconfigs.crd.k8s.amazonaws.com                2026-01-26T09:15:19Z
instrumentations.opentelemetry.io               2026-01-26T17:20:56Z
opampbridges.opentelemetry.io                   2026-01-26T17:20:57Z
opentelemetrycollectors.opentelemetry.io        2026-01-26T17:20:57Z
podmonitors.monitoring.coreos.com               2026-01-26T09:40:08Z
policyendpoints.networking.k8s.aws              2026-01-26T09:14:15Z
probes.monitoring.coreos.com                    2026-01-26T09:40:08Z
scrapeconfigs.monitoring.coreos.com             2026-01-26T09:40:09Z
securitygrouppolicies.vpcresources.k8s.aws      2026-01-26T09:14:16Z
servicemonitors.monitoring.coreos.com           2026-01-26T09:40:09Z
targetallocators.opentelemetry.io               2026-01-26T17:20:57Z

kubectl get mutatingwebhookconfiguration
NAME                                                       WEBHOOKS   AGE
opentelemetry-kube-stack-opentelemetry-operator-mutation   3          15m
pod-identity-webhook                                       1          8h
vpc-resource-mutating-webhook                              1          8h
