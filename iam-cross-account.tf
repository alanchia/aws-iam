###############################################################################
# Cross-account S3 access — concise reference
#
# Purpose:
# - Show how to grant cross-account access from Account A to an S3 bucket in Account B
#   using an IAM role in Account B that trusts principals from Account A.
# - Provide an example local S3 bucket and IAM policy in Account A for comparison.
#
# Quick usage:
# - Replace placeholder account IDs (111111111111 / 222222222222), role/user ARNs,
#   and bucket names with real values before applying.
# - Split the Account A and Account B resources into separate state/workspaces when
#   deploying across real accounts.
# - Prefer least-privilege principals and actions in production.
#
# Notes:
# - This file is a reference only; ensure the AWS provider and backend are configured
#   elsewhere in your Terraform project before applying.
###############################################################################

# Account map (replace these example IDs with your real account IDs):
# - Account A (caller): local.account_a_id
# - Account B (resource owner): local.account_b_id
#
# The `locals` block below centralizes key values used in this file so it's
# easier to scan on GitHub. Replace the local values as needed.

locals {
  account_a_id       = "111111111111"     # caller account (Account A)
  account_b_id       = "222222222222"     # resource account (Account B)
  account_b_bucket   = "account-b-bucket" # example bucket in Account B
  account_a_bucket   = "my-account-a-bucket" # example bucket in Account A
  role_name          = "CrossAccountAccessRole"
  account_a_user     = "some-user-name"
}

# Account B (Account ID: ${local.account_b_id})

#########################
# Account B: role that Account A will assume
#########################

# Trust policy: allows the Account A principal (root or a specific role/user) to assume this role.
data "aws_iam_policy_document" "account_b_assume_role_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
        # Replace with the actual Account A principal (root or role/user ARN)
        identifiers = ["arn:aws:iam::${local.account_a_id}:root"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Role that lives in Account B and is assumed by Account A principals.
resource "aws_iam_role" "account_b_cross_account_role" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.account_b_assume_role_trust.json
  # Optionally set path, description, or permissions boundary here.
}

# Permissions policy document (grants S3 read to the role in Account B).
# This data block builds the permission statements; it is attached to the
# role below using resource.aws_iam_role_policy.account_b_role_policy.
data "aws_iam_policy_document" "account_b_s3_read_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.account_b_bucket}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${local.account_b_bucket}/*"]
  }
}

# Inline role policy resource that attaches the above permissions policy to
# the role in Account B. (This is the actual permissions policy attachment.)
resource "aws_iam_role_policy" "account_b_role_policy" {
  name   = "AccountBAllowS3Read"
  role   = aws_iam_role.account_b_cross_account_role.id
  policy = data.aws_iam_policy_document.account_b_s3_read_policy.json
}

#########################
# Account A: principals and local S3 example
#########################

# Example: create a local S3 bucket in Account A for testing and local access.
resource "aws_s3_bucket" "account_a_bucket" {
  bucket = local.account_a_bucket # example - pick a globally unique name
}

# Recommended public access block to prevent accidental public exposure.
resource "aws_s3_bucket_public_access_block" "account_a_bucket_block" {
  bucket                  = aws_s3_bucket.account_a_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Permissions policy document for Account A callers.
# - Allows sts:AssumeRole on the role in Account B.
# - Allows s3 operations on the local Account A bucket.
# This data block is later converted into an IAM policy resource
# (resource.aws_iam_policy.account_a_caller_policy) and can be attached
# to users or roles.
data "aws_iam_policy_document" "account_a_caller_policy" {
  # Allow principals in Account A to assume the cross-account role in Account B.
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    # Replace with the actual role ARN in Account B
    resources = ["arn:aws:iam::${local.account_b_id}:role/${local.role_name}"]
  }

  # Allow listing the local bucket in Account A.
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.account_a_bucket.bucket}"]
  }

  # Allow get/put object operations in the local bucket.
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.account_a_bucket.bucket}/*"]
  }
}

# Create an IAM policy resource in Account A from the above policy document.
# This is the actual permissions policy (policy ARN) you attach to users/roles.
resource "aws_iam_policy" "account_a_caller_policy" {
  name   = "AccountACallerPolicy"
  policy = data.aws_iam_policy_document.account_a_caller_policy.json
}

# Attach the policy to a specific user in Account A (replace user name as needed).
resource "aws_iam_user_policy_attachment" "user_attachment" {
  user       = local.account_a_user # replace with actual IAM user
  policy_arn = aws_iam_policy.account_a_caller_policy.arn
}

# Notes:
# - Ensure both account IDs and ARNs are replaced with real values before applying.
# - For production, prefer granting least privilege: restrict principal ARNs, action lists, and resource ARNs.
# - Consider using separate roles in Account A (instead of attaching to a user) for automation or services.