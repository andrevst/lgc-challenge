variable "region" {
  description = "AWS region"
}

variable "project" {
  description = "Project name"
}

variable "zone_id" {
  description = "Route 53 Hosted Zone ID"
  type        = string
}

variable "domain" {
  description = "Base domain name"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
}

variable "retention_days" {
  description = "Cloudwatch log retention in days"
  default     = 7
}

variable "desired_size" {
  description = "Desired number of worker nodes"
}

variable "max_size" {
  description = "Maximum number of worker nodes"
}

variable "min_size" {
  description = "Minimum number of worker nodes"
}

variable "instance_type" {
  description = "Instance type for worker nodes"
}

variable "capacity_type" {
  description = "Capacity type for worker nodes"
  default     = "ON_DEMAND"
}
