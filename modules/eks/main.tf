module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = "1.33"

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    spot_small = {
      instance_types = [var.instance_type]
      capacity_type  = var.capacity_type
      min_size     = var.min_size
      desired_size = var.desired_size
      max_size     = var.max_size
      disk_size = var.disk_size
    }
  }
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  tags = {
    Environment = var.env
    Terraform   = "true"
  }
}

