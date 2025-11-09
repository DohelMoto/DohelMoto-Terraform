variable "node_pools" {
  default = "general-purpose"
  type = string
}

variable "cluster_name" {
  default = "dohel-moto"
  type = string
}

variable "env" {
}

variable "vpc_id" {
}

variable "subnet_ids" {
}
