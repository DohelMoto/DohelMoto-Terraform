terraform {
  required_version = ">= 1.5.0"
  backend "s3" {
    bucket = "dohelmoto-state"
    region = "us-east-1"
    key = "terraform.tfstate"
    dynamodb_table = "state-locking"
  }
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2.29.0" }
    helm = { source = "hashicorp/helm", version = "= 2.13.0" }
    time = { source = "hashicorp/time", version = ">= 0.9.0" }
    null = { source = "hashicorp/null", version = ">= 3.0" }
  }
}

data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = try(data.aws_eks_cluster.this.endpoint, "")
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.this.certificate_authority[0].data), "")
  token                  = try(data.aws_eks_cluster_auth.this.token, "")
  
  config_path = null
}

provider "helm" {
  kubernetes {
    host                   = try(data.aws_eks_cluster.this.endpoint, "")
    cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.this.certificate_authority[0].data), "")
    token                  = try(data.aws_eks_cluster_auth.this.token, "")
  }
}

module "connection" {
  source = "../modules/network"
  region = var.region
  env = var.env
  cluster_name = var.cluster_name
}

module "eks" {
  source = "../modules/eks"
  cluster_name = var.cluster_name
  env = var.env
  vpc_id = module.connection.vpc_id
  subnet_ids = module.connection.private_subnets
}

# module "ecr" {
#   source    = "../modules/ecr"
#   repo_name = var.repo_name
# }

module "s3" {
  source = "../modules/s3"
  env = var.env
  bucket_name = var.bucket_name
}

resource "time_sleep" "wait_for_cluster" {
  depends_on = [module.eks]
  create_duration = "60s"
}

resource "null_resource" "wait_for_cluster_ready" {
  depends_on = [time_sleep.wait_for_cluster, data.aws_eks_cluster.this, data.aws_eks_cluster_auth.this]
  
  triggers = {
    cluster_endpoint = data.aws_eks_cluster.this.endpoint
  }
}

module "eks_addons" {
  source = "../modules/eks-addons"
  cluster_name = module.eks.cluster_name
  oidc_provider_arn = module.eks.cluster_oidc_provider_arn
  depends_on = [null_resource.wait_for_cluster_ready]
}

module "monitoring" {
  source = "../modules/monitoring"
  env = var.env
  eks_cluster_ready = null_resource.wait_for_cluster_ready.id
  depends_on = [null_resource.wait_for_cluster_ready]
}

resource "kubernetes_namespace" "ecommerce" {
  metadata {
    name = "ecommerce"
  }
  depends_on = [null_resource.wait_for_cluster_ready]
}

resource "kubernetes_service_account" "external_secrets" {
  metadata {
    name      = "external-secrets"
    namespace = kubernetes_namespace.ecommerce.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.eks_addons.external_secrets_irsa_role_arn
    }
  }
  depends_on = [module.eks_addons, kubernetes_namespace.ecommerce]
}

resource "time_sleep" "wait_for_external_secrets" {
  depends_on = [module.eks_addons]
  create_duration = "120s"
}

output "cluster_name" {
  value       = module.eks.cluster_name
}
