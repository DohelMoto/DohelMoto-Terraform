module "connection" {
  source = "../modules/network"
  region = var.region
  env = var.env
}
