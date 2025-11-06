module "iam" {
  source = 

module "iam_read_only_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-read-only-policy"

  name        = var.iam_name
  path        = "/"
  description = "My example read-only policy"

  allowed_services = ["rds", "dynamo", "health"]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
