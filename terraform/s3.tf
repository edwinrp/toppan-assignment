resource "aws_s3_bucket" "toppan_S3" {
    bucket =  "toppans3edwin"  
    
    tags = {
        Name = "Toppans3edwin"
    }
} 

resource "aws_s3_bucket_acl" "aclprivate" {

  bucket = aws_s3_bucket.toppan_S3.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "publicblock" {
  bucket = aws_s3_bucket.toppan_S3.bucket

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}