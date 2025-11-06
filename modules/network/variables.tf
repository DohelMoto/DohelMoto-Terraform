variable "region" {
}

variable "cidr" {
  default = "10.0.0.0/16"
  type = string
}

variable "vpc-name" {
  default = "my-vpc"
}

variable "env" {
}
