output "azs" { 
  value = data.aws_availability_zones.zones.names
}

output "pub_subnets" {
  value = local.public_subnets
}

output "pri_subnets" {
  value = local.private_subnets
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
