terraform {
  backend "s3" {
    bucket         = "interviewlgc-tf-be"
    key            = "terraform.tfstate"
    encrypt        = "false"
    region         = "eu-west-1"
    session_name   = "terraform"
    dynamodb_table = "interviewlgc-tf-state-lock"
  }
}
