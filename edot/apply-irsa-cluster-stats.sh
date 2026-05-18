#!/usr/bin/env bash
# Attach IRSA to the opentelemetry-kube-stack *cluster-stats* ServiceAccount so the
# EKS resource-detection processor can call EC2 DescribeInstances from a Deployment
# Pod (no IMDS). Requires: aws CLI, eksctl, kubectl; AWS credentials for your account.
#
# Usage:
#   export CLUSTER_NAME=my-eks
#   export AWS_REGION=ap-south-1
#   ./apply-irsa-cluster-stats.sh
#
# Optional:
#   export NAMESPACE=opentelemetry-operator-system
#   export SA_NAME=opentelemetry-kube-stack-cluster-stats-collector
#   export ROLE_NAME=edot-cluster-stats-eks-detector
#   export POLICY_NAME=EDOTClusterStatsEC2DescribeInstances

set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:?set CLUSTER_NAME (EKS cluster)}"
AWS_REGION="${AWS_REGION:?set AWS_REGION}"
NAMESPACE="${NAMESPACE:-opentelemetry-operator-system}"
SA_NAME="${SA_NAME:-opentelemetry-kube-stack-cluster-stats-collector}"
ROLE_NAME="${ROLE_NAME:-edot-cluster-stats-eks-detector}"
POLICY_NAME="${POLICY_NAME:-EDOTClusterStatsEC2DescribeInstances}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICY_DOC="${SCRIPT_DIR}/irsa-cluster-stats-ec2-describe-policy.json"

if [[ ! -f "$POLICY_DOC" ]]; then
  echo "Missing policy file: $POLICY_DOC" >&2
  exit 1
fi

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"

echo "Ensuring IAM policy exists: ${POLICY_ARN}"
if aws iam get-policy --policy-arn "$POLICY_ARN" &>/dev/null; then
  echo "Policy already exists."
else
  aws iam create-policy \
    --policy-name "$POLICY_NAME" \
    --policy-document "file://${POLICY_DOC}" \
    --description "ec2:DescribeInstances for EDOT cluster-stats EKS resource detection"
fi

echo "Ensuring OIDC provider is associated (idempotent)."
eksctl utils associate-iam-oidc-provider --cluster "$CLUSTER_NAME" --region "$AWS_REGION" --approve

echo "Creating/updating IRSA and annotating ServiceAccount ${NAMESPACE}/${SA_NAME}"
eksctl create iamserviceaccount \
  --cluster="$CLUSTER_NAME" \
  --region="$AWS_REGION" \
  --namespace="$NAMESPACE" \
  --name="$SA_NAME" \
  --role-name="$ROLE_NAME" \
  --attach-policy-arn="$POLICY_ARN" \
  --override-existing-serviceaccounts \
  --approve

echo "Restart cluster-stats collector so Pods refresh projected token (if deployment exists)."
if kubectl get deployment -n "$NAMESPACE" opentelemetry-kube-stack-cluster-stats-collector &>/dev/null; then
  kubectl rollout restart deployment -n "$NAMESPACE" opentelemetry-kube-stack-cluster-stats-collector
  kubectl rollout status deployment -n "$NAMESPACE" opentelemetry-kube-stack-cluster-stats-collector --timeout=180s
fi

echo "Verify inside a Pod:"
echo "  kubectl exec -n $NAMESPACE deploy/opentelemetry-kube-stack-cluster-stats-collector -- printenv AWS_ROLE_ARN"
