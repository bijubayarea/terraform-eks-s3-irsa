resource "aws_s3_bucket" "irsa_owner" {
  bucket        = "bijubayarea-s3-test-owner"
  force_destroy = true

  tags = {
    Name = "s3 irsa test bucket owner"
    env  = "test"
  }
}

resource "aws_s3_bucket_acl" "irsa_bucket_owner_acl" {
  bucket = aws_s3_bucket.irsa_owner.id
  acl    = "private"
}

resource "aws_s3_bucket" "irsa_non_owner" {
  bucket        = "bijubayarea-s3-test-non-owner"
  force_destroy = true

  tags = {
    Name = "s3 irsa test bucket non-owner"
    env  = "test"
  }
}

resource "aws_s3_bucket_acl" "irsa_bucket_non_owner_acl" {
  bucket = aws_s3_bucket.irsa_non_owner.id
  acl    = "private"
}