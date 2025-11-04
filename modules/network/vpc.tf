module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = var.vpc-name
  cidr = var.cidr
  azs             = data.aws_availability_zones.zones.names
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
  enable_nat_gateway = true
  enable_vpn_gateway = true
  single_nat_gateway = true
  tags = {
    Terraform = "true"
    Environment = var.env
  }
}
