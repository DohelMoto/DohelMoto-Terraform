data "aws_availability_zones" "zones" {
  region = var.region
  state = "available"
}

locals {
  eks_supported_azs = [
    for az in data.aws_availability_zones.zones.names :
    az if !contains(["us-east-1e"], az)
  ]
  public_subnets  = [for i in range(length(local.eks_supported_azs)) : cidrsubnet(var.cidr, 8, i)]
  private_subnets = [for i in range(length(local.eks_supported_azs)) : cidrsubnet(var.cidr, 8, i + 100)]
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = var.vpc-name
  cidr = var.cidr
  azs             = local.eks_supported_azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
  enable_nat_gateway = true
  single_nat_gateway = true
  
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  tags = {
    Terraform = "true"
    Environment = var.env
  }
}
