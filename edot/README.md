**edot-values.yaml has the configuration for the below components:**

1. opentelemetry-operator
2. CRDs - Custom Resource Definitions
3. ClusterRole
4. Collectors
  - cluster : cluster is a K8s deployment EDOT collector focused on gathering telemetry at the cluster level (Kubernetes Events and cluster metrics).
  - daemon :  daemon is a K8s daemonset EDOT collector focused on gathering telemetry at node level and exposing an OTLP endpoint for data ingestion. Auto-instrumentation SDKs will use this endpoint. daemon generally forwards data to gateway
  - gateway : gateway is a K8s deployment / daemonset EDOT collector focused on processing and forwarding telemetry to an Elasticsearch endpoint.
5. Instrumentation

**Note: edot-values.yaml is kept up-to-date from source (elastic/elastic-agent/deploy/helm/edot-collector/kube-stack/values.yaml)**

Optional overlays in this directory (not merged into `edot-values.yaml`):

- **`postgresql-ram-eks-statefulset.yaml`** — single-node PostgreSQL 16 in namespace `database` (Service `postgresql.database.svc.cluster.local:5433`; user/password `postgresql` for lab use). `kubectl apply -f postgresql-ram-eks-statefulset.yaml` on your ram-eks context.
- **`edot-postgresql-receiver-values.yaml`** — Postgres on gateway when base values use **`otlphttp/motlp`** + **`batch/metrics`** (e.g. repo `edot-values.yaml`).
- **`edot-postgresql-receiver-managed-otlp-values.yaml`** — use with Elastic **`managed_otlp/values.yaml`**; keeps gateway metrics exporters **`debug`**, **`otlp/ingest_metrics_traces`** and processors **`[]`**.
- Pair either overlay with Secret **`postgresql-otel-ram-eks`** — see **`postgresql-otel-ram-eks-secret.example.yaml`** (defaults aligned with `postgresql-ram-eks-statefulset.yaml`).

## IRSA on EKS (IAM roles for service accounts)

Some Pods need **AWS API** access (for example EC2 `DescribeInstances` for OpenTelemetry **EKS resource detection** on the kube-stack **cluster-stats** Deployment). Ordinary Deployment Pods usually **cannot** use the node IMDS the same way as `hostNetwork` DaemonSets, so attach an **IAM role to the Kubernetes ServiceAccount** (IRSA) instead.

**Scripts and policy in this directory:**

| File | Purpose |
|------|--------|
| [apply-irsa-cluster-stats.sh](apply-irsa-cluster-stats.sh) | Associate OIDC (if needed), create `ec2:DescribeInstances` policy, `eksctl create iamserviceaccount` for cluster-stats SA, rollout restart |
| [irsa-cluster-stats-ec2-describe-policy.json](irsa-cluster-stats-ec2-describe-policy.json) | IAM policy JSON consumed by the script |

Example (from this `edot/` directory):

```bash
export CLUSTER_NAME=<your-eks-cluster>
export AWS_REGION=<region>
./apply-irsa-cluster-stats.sh
```

Adjust `NAMESPACE`, `SA_NAME`, and Helm-managed ServiceAccount name if your release differs. See comments in the script.

**AWS docs:** [IAM roles for service accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
