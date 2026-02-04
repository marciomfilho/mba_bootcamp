terraform {
  backend "s3" {
    bucket         = "tracknow-tf-state-lab"
    key            = "prod/terraform.tfstate"
    region         = "ua-east-1"
    dynamodb_table = "tracknow-tf-lock-lab"
    encrypt        = true
  }
}
