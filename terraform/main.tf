terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Dev EKS Cluster
module "eks_dev" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "dev-cluster"
  cluster_version = var.k8s_version

  vpc_id     = module.vpc_dev.vpc_id
  subnet_ids = module.vpc_dev.private_subnets

  eks_managed_node_groups = {
    default = {
      min_size     = 2
      max_size     = 4
      desired_size = 2
      instance_types = ["t3.medium"]
    }
  }

  tags = {
    Environment = "dev"
  }
}

# Prod EKS Cluster
module "eks_prod" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "prod-cluster"
  cluster_version = var.k8s_version

  vpc_id     = module.vpc_prod.vpc_id
  subnet_ids = module.vpc_prod.private_subnets

  eks_managed_node_groups = {
    default = {
      min_size     = 3
      max_size     = 10
      desired_size = 3
      instance_types = ["t3.large"]
    }
  }

  tags = {
    Environment = "prod"
  }
}

# VPC for Dev
module "vpc_dev" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "dev-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = "dev"
  }
}

# VPC for Prod
module "vpc_prod" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "prod-vpc"
  cidr = "10.1.0.0/16"

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnets  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false

  tags = {
    Environment = "prod"
  }
}
