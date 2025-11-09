module "connection" {
  source = "../modules/network"
  region = var.region
  env = var.env
  cluster_name = var.cluster_name
}

module "cluster" {
  source = "../modules/eks"
  cluster_name = var.cluster_name
  env = var.env
  vpc_id = module.connection.vpc_id
  subnet_ids = module.connection.private_subnets
}

#module "ecr" {[
# source = "../modules/ecr"
# repo_name = var.repo_name
#}

module "s3" {
  source = "../modules/s3"
  env = var.env
  bucket_name = var.bucket_name
}
