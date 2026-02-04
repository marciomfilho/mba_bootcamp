terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
module "vpc" {
  source = "../../modules/vpc"

  name                 = "tracknow-prod"
  cidr_block           = "10.0.0.0/16"
  azs                  = ["sa-east-1a", "sa-east-1b", "sa-east-1c"]
  public_subnets       = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_app_subnets  = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  private_data_subnets = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]
}

module "rds" {
  source = "../../modules/rds"

  db_name              = "tracknow"
  master_username      = "tracknow_app"
  master_password      = var.db_master_password
  vpc_id               = module.vpc.vpc_id
  private_data_subnets = module.vpc.private_data_subnets_ids
}

module "ecs_app" {
  source = "../../modules/ecs_app"

  vpc_id              = module.vpc.vpc_id
  public_subnets_ids  = module.vpc.public_subnets_ids
  private_app_subnets = module.vpc.private_app_subnets_ids

  cluster_name = "tracknow-ecs-prod"

  container_image_pedidos      = "ACCOUNT_ID.dkr.ecr.sa-east-1.amazonaws.com/pedidos:latest"
  container_image_rastreamento = "ACCOUNT_ID.dkr.ecr.sa-east-1.amazonaws.com/rastreamento:latest"

  desired_count_pedidos      = 3
  desired_count_rastreamento = 3
}

module "s3_cloudfront" {
  source = "../../modules/s3_cloudfront"

  bucket_name = "tracknow-prod-static"
  domain_name = "app.tracknow.com.br"
}
