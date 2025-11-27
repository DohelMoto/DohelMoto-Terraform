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

variable "instance_type" {
  default = "t3.small"
  type = string
}

variable "capacity_type" {
  default = "SPOT"
  type = string
}

variable "min_size" {
  default = 0
}

variable "desired_size" {
  default = 1
}

variable "max_size" {
  default = 2
}

variable "disk_size" {
  default = 20
}
