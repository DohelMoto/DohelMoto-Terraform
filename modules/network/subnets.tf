data "aws_availability_zones" "zones" {
  region = var.region
}

locals {
  public_subnets = [ for i in range (length(data.aws_availability_zones.zones)) : cidrsubnet(var.cidr, 8, i)]
  private_subnets = [ for i in range (length(data.aws_availability_zones.zones)) : cidrsubnet(var.cidr, 8, i +100)]
}
