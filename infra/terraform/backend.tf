terraform {
  backend "s3" {
    bucket         = "interviewlgc-tf-state"
    key            = "terraform.tfstate"
    encrypt        = "false"
    region         = "eu-west-2"
    session_name   = "terraform"
    dynamodb_table = "interviewlgc-tf-locktable"
  }
}
