module "argocd" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "~> 1.0"
  chart            = "argo-cd"
  chart_version    = "9.0.4"
  repository       = "https://argoproj.github.io/argo-helm"
  namespace        = "argocd"
  create_namespace = true
  description      = "Argo CD GitOps"
  set = [
    { name = "server.service.type", value = "ClusterIP" }
  ]
  depends_on = [var.eks_cluster_ready]
  tags = { app = "argocd" }
}

module "prometheusgrafana" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "~> 1.0"
  chart            = "kube-prometheus-stack"
  chart_version    = "79.3.0"
  repository       = "https://prometheus-community.github.io/helm-charts"
  namespace        = "monitoring"
  create_namespace = true
  description      = "Prometheus and Grafana"
  set = [
    { name = "grafana.enabled", value = "true" },
    { name = "grafana.service.type", value = "ClusterIP" }
  ]
  depends_on = [var.eks_cluster_ready]
  tags = {
    app         = "kube-prometheus-stack"
    Environment = var.env
  }
}

