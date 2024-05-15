terraform {
  required_version = ">=0.13.1"
  required_providers {
    aws   = ">= 5.0"
    local = ">=2.5.1"
  }
}

provider "aws" {
  region = var.region
}