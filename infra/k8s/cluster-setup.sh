#!/bin/bash

# Default values for variables (can be overridden by environment variables)
PROJECT=${PROJECT:-""}
DOMAIN=${DOMAIN:-""}
HOSTED_ZONE_ID=${HOSTED_ZONE_ID:-""}
LB_HOSTED_ZONE_ID=${LB_HOSTED_ZONE_ID:-""}
NAMESPACE=${NAMESPACE:-"default"}

# Issuer and Ingress manifest files (hardcoded)
ISSUER_MANIFEST="./cert-manager/issuer.yaml"
INGRESS_MANIFEST="./ingress/ingress.yaml"

# Function to prompt for a variable if not already set
prompt_for_variable() {
  local var_name=$1
  local prompt_message=$2
  local current_value=$(eval echo \$$var_name)
  if [ -z "$current_value" ]; then
    read -p "$prompt_message: " input_value
    eval $var_name="'$input_value'"
  fi
}
prompt_for_variable PROJECT "Enter your project name"
prompt_for_variable DOMAIN "Enter your domain"
prompt_for_variable HOSTED_ZONE_ID "Enter your hosted zone ID"

set -e

# Step 1: Install NGINX Ingress Controller
echo "Installing NGINX Ingress Controller..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace

# Step 2: Install Cert Manager
echo "Installing Cert Manager..."
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.11.0 --set installCRDs=true

echo "Waiting for Cert Manager to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/cert-manager-webhook -n cert-manager

# Step 3: Apply the Issuer manifest
echo "Applying the Issuer manifest..."
kubectl apply -f "$ISSUER_MANIFEST"

# Step 4: Apply the Ingress manifest and get the external IP
echo "Applying the Ingress manifest..."
kubectl apply -f "$INGRESS_MANIFEST"

echo "Waiting for the Ingress to get an external IP..."
for i in {1..30}; do
  INGRESS_IP=$(kubectl get ingress ingress-host -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  if [ -n "$INGRESS_IP" ]; then
    echo "Ingress IP found: $INGRESS_IP"
    break
  fi
  echo "Waiting for Ingress IP..."
  sleep 10
done

if [ -z "$INGRESS_IP" ]; then
  echo "Ingress IP not found!"
  exit 1
fi

# Step 5: Create Route 53 DNS record with the Ingress IP
echo "Creating Route 53 DNS record..."
aws route53 change-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" --change-batch '{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "'"${PROJECT}.${DOMAIN}"'",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "'"${LB_HOSTED_ZONE_ID}"'",
          "DNSName": "'"dualstack.${INGRESS_IP}"'",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}'

echo "DNS record created successfully! check https://${PROJECT}.${DOMAIN}."
