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
- Terraform v1.0 or higher
- Helm v3.0 or higher
- Kubectl configured to interact with your Kubernetes clusters

## Architecture

![Architecture Diagram](path/to/architecture_diagram.png)

_Description of the architecture and components._

## Setup Instructions