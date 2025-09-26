# This example demonstrates creating an inline policy using ARNs
# This is useful for:
# - Cross-account access
# - Specific resource access
# - Multiple resource type access

# Create the assume role policy document
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Create policy document with specific ARN-based permissions
data "aws_iam_policy_document" "cross_account_access" {
  # S3 bucket access statement
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::production-data-bucket",
      "arn:aws:s3:::production-data-bucket/*"
    ]
  }

  # Cross-account role assumption
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [
      "arn:aws:iam::123456789012:role/cross-account-admin",
      "arn:aws:iam::987654321098:role/readonly-role"
    ]
  }

  # SNS topic access
  statement {
    effect = "Allow"
    actions = [
      "sns:Publish",
      "sns:Subscribe"
    ]
    resources = [
      "arn:aws:sns:us-west-2:123456789012:important-notifications",
      "arn:aws:sns:us-east-1:123456789012:alerts"
    ]
  }

  # KMS key access
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      "arn:aws:kms:us-west-2:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    ]
  }
}

# Create IAM role with the inline policies
resource "aws_iam_role" "multi_service_role" {
  name = "multi-service-role"

  # Attach the assume role policy
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  # Attach the inline policy with ARN-based permissions
  inline_policy {
    name   = "cross-account-and-service-access"
    policy = data.aws_iam_policy_document.cross_account_access.json
  }
}