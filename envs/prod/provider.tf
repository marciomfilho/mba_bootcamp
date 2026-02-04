provider "aws" {
  region = var.region

  assume_role {
    role_arn = var.lab_role_arn
  }
}
