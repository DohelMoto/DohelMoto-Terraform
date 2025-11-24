variable "env" {
  description = "Environment name"
  type        = string
}

variable "eks_cluster_ready" {
  description = "Dummy variable to ensure EKS cluster is ready before deploying Helm charts"
  type        = any
  default     = null
}

