###############################################################################
# Cross-account S3 bucket access — Account B bucket with Account A access
#
# Purpose:
# - Create an S3 bucket in Account B and grant access to Account A
# - Configure bucket policy to allow specific actions from Account A
# - Set up necessary IAM roles and policies in both accounts
#
# Quick usage:
# - Replace placeholder account IDs (111111111111 / 222222222222)
# - Update bucket name to a globally unique name
# - Split Account A and Account B resources into separate state files
# - Adjust permissions and actions based on your security requirements
#
# Notes:
# - Ensure AWS provider and backend are configured separately
# - Follow least privilege principle in production environments
###############################################################################

locals {
  account_a_id     = "111111111111"    # caller account (Account A)
  account_b_id     = "222222222222"    # resource account (Account B)
  bucket_name      = "my-secure-b-bucket" # bucket in Account B (replace with unique name)
  role_name        = "AccountABucketAccessRole"
  account_a_user   = "some-user-name"
}

#########################
# Account B Resources
#########################

# Create the S3 bucket in Account B
resource "aws_s3_bucket" "account_b_bucket" {
  bucket = local.bucket_name
}

# Enable versioning on the bucket
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.account_b_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block all public access to the bucket
resource "aws_s3_bucket_public_access_block" "bucket_public_access_block" {
  bucket                  = aws_s3_bucket.account_b_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy allowing Account A access
data "aws_iam_policy_document" "bucket_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_a_id}:root"]
    }
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.account_b_bucket.arn,
      "${aws_s3_bucket.account_b_bucket.arn}/*"
    ]
  }
}

# Attach the bucket policy
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.account_b_bucket.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

#########################
# Account A Resources
#########################

# IAM policy document for Account A users/roles
data "aws_iam_policy_document" "account_a_s3_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${local.bucket_name}",
      "arn:aws:s3:::${local.bucket_name}/*"
    ]
  }
}

# Create IAM policy in Account A
resource "aws_iam_policy" "account_a_s3_access" {
  name        = "AccountAS3BucketAccess"
  description = "Policy allowing access to S3 bucket in Account B"
  policy      = data.aws_iam_policy_document.account_a_s3_access.json
}

# Attach the policy to a user in Account A
resource "aws_iam_user_policy_attachment" "user_bucket_access" {
  user       = local.account_a_user # replace with actual IAM user
  policy_arn = aws_iam_policy.account_a_s3_access.arn
}

# Notes:
# - Replace account IDs and bucket name before applying
# - Consider adding encryption (aws_s3_bucket_server_side_encryption_configuration)
# - Add bucket lifecycle rules if needed
# - Consider using AWS Organizations SCP for additional security
# - Use tags for better resource management
# - Consider implementing additional security measures like:
#   * VPC endpoints for S3
#   * Bucket versioning
#   * Access logging
#   * Object lifecycle management