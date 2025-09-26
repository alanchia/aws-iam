# This example demonstrates setting up EC2 instance permissions using:
# 1. An IAM role with specific permissions (S3, cross-account access)
# 2. An instance profile (required for EC2 instances to assume IAM roles)
# 3. A trust policy allowing EC2 service to assume the role
# 4. A user with permissions to work with the EC2 instance and its role
#
# Note: Instance profiles are ONLY used with EC2 instances. They are the mechanism
# that allows EC2 instances to assume IAM roles and access AWS services securely.

# Create an IAM user (e.g., DevOps engineer who manages EC2 instances)
resource "aws_iam_user" "example_user" {
  name = "example-user"
}

# Create the trust policy (assume role policy) document
# This is a special policy that defines which service can assume this role
# In this case, we're creating it specifically for EC2 instances
data "aws_iam_policy_document" "trust_policy" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"] # Only EC2 service can assume this role
    }
  }
}

# Create the policy document that allows specific users to assume this role
data "aws_iam_policy_document" "assume_role_policy" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [
      "arn:aws:iam::*:role/${aws_iam_role.multi_service_role_separate.name}"
    ]
  }
}

# Create policy document that allows the user to use instance profile
data "aws_iam_policy_document" "allow_instance_profile" {
  statement {
    effect = "Allow"
    actions = [
      "iam:GetInstanceProfile",
      "iam:PassRole"
    ]
    resources = ["*"]
  }
}

# Attach instance profile and assume role permissions to user
resource "aws_iam_user_policy" "user_permissions" {
  name   = "allow-instance-profile-and-assume-role"
  user   = aws_iam_user.example_user.name
  policy = data.aws_iam_policy_document.assume_role_policy.json
}

# S3 specific policy document
data "aws_iam_policy_document" "s3_access_separate" {
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
}

# Cross-account access policy document
data "aws_iam_policy_document" "cross_account_separate" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [
      "arn:aws:iam::123456789012:role/cross-account-admin",
      "arn:aws:iam::987654321098:role/readonly-role"
    ]
  }
}

# Create the IAM role with the trust policy
resource "aws_iam_role" "multi_service_role_separate" {
  name               = "multi-service-role-separate"
  assume_role_policy = data.aws_iam_policy_document.trust_policy.json # This defines who can assume the role
}

# Create an instance profile - this is required for EC2 instances
# Instance profiles are the container for an IAM role that you can attach to an EC2 instance
# You cannot attach an IAM role directly to an EC2 instance; you must use an instance profile
resource "aws_iam_instance_profile" "example_profile" {
  name = "example-profile"
  role = aws_iam_role.multi_service_role_separate.name
}

# Attach S3 policy to the role
resource "aws_iam_role_policy" "s3_access" {
  name   = "s3-access"
  role   = aws_iam_role.multi_service_role_separate.id
  policy = data.aws_iam_policy_document.s3_access_separate.json
}

# Attach cross-account policy to the role
resource "aws_iam_role_policy" "cross_account" {
  name   = "cross-account-access"
  role   = aws_iam_role.multi_service_role_separate.id
  policy = data.aws_iam_policy_document.cross_account_separate.json
}