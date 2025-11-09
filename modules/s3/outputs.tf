output "bucket_id" {
  value = module.s3_bucket.s3_bucket_id
}

output "bucket_arn" {
  value = module.s3_bucket.s3_bucket_arn
}

output "bucket_versioning_status" {
  value = module.s3_bucket.aws_s3_bucket_versioning_status
}
