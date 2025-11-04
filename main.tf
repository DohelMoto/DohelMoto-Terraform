resource "aws_s3_bucket" "state" { 
  bucket = "state-dohelmoto"
  region = "us-east-1"
  force_destroy = true
}

resource "aws_dynamodb_table" "state-locking" {
  name = "state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
  
