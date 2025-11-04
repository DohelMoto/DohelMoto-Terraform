terraform {
  backend "s3" {
    bucket = "state-tf-dohelmoto"
    key = "terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "state-locking"
  }
}
