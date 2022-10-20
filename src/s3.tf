resource "aws_s3_bucket" "irsa" {
  bucket        = "bijubayarea-s3-test"
  force_destroy = true

  tags = {
    Name = "s3 irsa test bucket"
    env  = "test"
  }
}

resource "aws_s3_bucket_acl" "irsa_bucket_acl" {
  bucket = aws_s3_bucket.irsa.id
  acl    = "private"
}