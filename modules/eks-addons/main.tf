module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.41"

  role_name_prefix = "ebs-csi-driver-"

  attach_ebs_csi_policy = true
  ebs_csi_kms_cmk_ids   = []

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  lifecycle {
    create_before_destroy = false
  }
}

resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "false"
    }
  }
  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  parameters = {
    type   = "gp3"
    fsType = "ext4"
  }
  depends_on = [aws_eks_addon.ebs_csi]

  lifecycle {
    create_before_destroy = false
  }
}

module "ingress_nginx" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "~> 1.0"

  chart            = "ingress-nginx"
  chart_version    = "4.11.3"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  description      = "NGINX Ingress Controller"

  set = [
    { name = "controller.service.type", value = "LoadBalancer" },
    { name = "controller.ingressClassResource.default", value = "true" }
  ]

  depends_on = [aws_eks_addon.ebs_csi]
  tags = { app = "ingress-nginx" }
}

module "cert_manager" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "~> 1.0"

  chart            = "cert-manager"
  chart_version    = "v1.15.3"
  repository       = "https://charts.jetstack.io"
  namespace        = "cert-manager"
  create_namespace = true
  description      = "cert-manager for Let's Encrypt"
  set = [
    { name = "installCRDs", value = "true" }
  ]

  depends_on = [module.ingress_nginx]
  tags = { app = "cert-manager" }
}

resource "aws_iam_policy" "external_secrets" {
  name        = "external-secrets-secrets-manager"
  description = "Policy for External Secrets Operator to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = "*"
      }
    ]
  })
}

module "external_secrets_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.41"

  role_name_prefix = "external-secrets-"

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets", "ecommerce:external-secrets"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  role       = module.external_secrets_irsa.iam_role_name
  policy_arn = aws_iam_policy.external_secrets.arn
}

module "external_secrets" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "~> 1.0"

  chart            = "external-secrets"
  chart_version    = "0.10.7"
  repository       = "https://charts.external-secrets.io"
  namespace        = "external-secrets"
  create_namespace = true
  description      = "External Secrets Operator"

  set = [
    { name = "installCRDs", value = "true" },
    { name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn", value = module.external_secrets_irsa.iam_role_arn }
  ]

  depends_on = [aws_eks_addon.ebs_csi, module.external_secrets_irsa]
  tags = { app = "external-secrets" }
}

