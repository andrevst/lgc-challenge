# lgc-challenge - AWS EKS Cluster Deployment with Terraform and Helm

> This repository contains the infrastructure code and application deployment for setting up an AWS EKS Cluster using Terraform, Helm, and Kubectl. The goal is to create a scalable, secure Kubernetes cluster with a simple web application deployed, accessible via a public endpoint.

## Overview

This project sets up the following components:
- **AWS VPC** with public and private subnets, an internet gateway, and route tables.
- **EKS Cluster:** A managed Kubernetes service running within the AWS cloud environment.
- **Node Groups:** Auto-scaling groups for managing the lifecycle of worker nodes.
- **Core Kubernetes Add-ons:** Including CoreDNS, the Kubernetes CNI, and a load balancer controller.
- **Sample Web Application:** A basic application deployed using Helm to demonstrate the cluster's functionality.

## Prerequisites

- AWS Account
- AWS CLI configured with administrator access
    - [AWM IAM Authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator)
- Terraform v1.0 or higher
- Helm v3.0 or higher
- Kubectl configured to interact with your Kubernetes clusters

## Setup Instructions

### Configure Environment Variables

Before running the Terraform scripts, set up your environment variables. Uses [direnv]() and create a .envrc file based on the [example file](.envrc.example) or export the variables directly in your shell:

```shell
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export KUBECONFIG=./kubeconfig.yaml
export REGION=""
export PROJECT=""
export DOMAIN=""
export HOSTED_ZONE_ID=""
```

### Provision core infrastructure with terraform

We will use terraform to provision the base infrastructure for our solution. The code is at [infra -> terraform](infra/terraform/). We have 2 modules in our infrastructure, [Network](infra/terraform/modules/network/) [host](infra/terraform/modules/host). Variables are set in the [terraform.tfvar file](infra/terraform/terraform.tfvars). For this challenge we will use, 1 VPC, 2 Public Subnets, 2 Private Subnets in different AZ for availability. Also, since we will have simple resources in ou cluster we will use t2.small instances.

> ! Check AWS account for hosted zone id and domain to fill it in the tfvars and envrc or environment variables.


#### Initialize and Apply Terraform Configuration

> For this challenge we will not break the folder into environments or use workspaces for it since we will not have other environments.

Navigate to the infra/terraform directory and initialize the Terraform configuration:

```shell
cd infra/terraform
terraform init
terraform plan
terraform apply
```

kubeconfig.yaml will be created at [k8s folder](infra/k8s/). You can use it from there or move it.

To retrieve the file run: `aws eks --region $REGION update-kubeconfig --name interviewlgc-cluster`


### Cluster Setup

We will use [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/deploy/) and [Cert-Manager](https://cert-manager.io/docs/installation/helm/) in this cluster. We will use helm to install both.

After install them, we will configure with the manifestos in the [k8s folder](infra/k8s/).

Finally, we will retrieve the public IP adress create for the Ingress and use AWS Route53 to add a subdomain in our project hosted zone. ***For this step we need the region Hosted Zone ID for loadbalancers. for Ireland (`eu-west-2`) it is `Z3GKZC51ZF0DB4`

This entire process can be accomplished running the [cluster_setup.sh script](infra/k8s/cluster-setup.sh) or doing manually the following steps:

#### 1. Install Ingress Controler

```shell
cd infra/k8s
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

#### 2. Install Cert-Manager & apply its issuer

```shell
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.11.0 --set installCRDs=true

# Apply the issuer
kubectl apply -f ./cert-manager/issuer.yaml
```

#### 3. Create the ingress

```shell
kubectl apply -f ./ingress/ingress.yaml

# Wait some time and query the ip address
kubectl get ingress ingress-host -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

#### 4. Setup Route53 to create subdomain

Go to AWS Portal and configure the Route53 Zone OR use the command bellow

>You need to know the AWS Hosted Zone for the load balancers in your region. for eu-west-2 : Z3GKZC51ZF0DB4

```shell
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
```

### Install Sample App

> it is a simple go app with 3 endpoints, / , /secrets and /healthz

- The image is public at Dockerhub

```shell
cd app/goserver
helm install goserver . -f ./values.yaml
```

## Validation

- With AWS credentials, aws cli and [AWM IAM Authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator). Use the kubectl to navigate in the cluster

### Addons requested

We are using AWS Load Balancer Controller.
You can check CoreDNS, the Kubernetes CNI and AWS Load Balancer Controller are installed using:

- **CoreDNS**: It’s installed by default with the cluster,  you can verify its configuration:
    
    ```
    kubectl get deployments -n kube-system coredns
    ```
    
- **VPC CNI Plugin**:  It’s installed by default with the cluster. Verify and configure via the ConfigMap if needed:
    
    ```
    kubectl get daemonset aws-node -n kube-system
    ```

- **Public app**: check the app at [interviewlgc.sandbox.letsgetchecked-dev1.com](https://interviewlgc.sandbox.letsgetchecked-dev1.com)
