output "azs" { 
  value = data.aws_availability_zones.zones.names
}

output "public_subnets" {
  value = local.public_subnets
}

output "private_subnets" {
  value = local.private_subnets
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

