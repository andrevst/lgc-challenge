#!/bin/bash

export PROJECT=$1
export REGION=$2

export BUCKET_NAME=$PROJECT-tf-be
export DYNAMODB_TABLE=$PROJECT-tf-state-lock

echo "Create the S3 bucket for $PROJECT_NAME at $REGION"
aws s3api create-bucket --bucket $BUCKET_NAME --region "$REGION" --acl private > /dev/null --create-bucket-configuration LocationConstraint

echo "Tagging it"

aws s3api put-bucket-tagging --bucket $BUCKET_NAME --tagging 'TagSet=[{Key=Project,Value='$PROJECT'}]'

echo "Enable versioning for the S3 bucket"
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled

echo "Create state lock table"
aws dynamodb create-table \
  --table-name $DYNAMODB_TABLE \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --tags Key=Project,Value=$PROJECT > /dev/null

echo "Generate backend.tf file"

cat > ./terraform/backend.tf << EOL
terraform {
  backend "s3" {
    bucket         = "${BUCKET_NAME}"
    key            = "terraform.tfstate"
    encrypt        = "false"
    region         = "${REGION}"
    session_name   = "terraform"
    dynamodb_table = "${DYNAMODB_TABLE}"
  }
}
EOL

echo "Generated backend.tf"