resource "aws_s3_bucket" "actividad3" {
  bucket = "actividad3-seguro-local"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "actividad3_sse" {
  bucket = aws_s3_bucket.actividad3.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "actividad3_block" {
  bucket = aws_s3_bucket.actividad3.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
