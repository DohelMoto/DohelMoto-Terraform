module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = var.vpc-name
  cidr = var.cidr
  azs             = data.aws_availability_zones.zones.names
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
