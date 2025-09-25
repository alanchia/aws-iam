# Build JSON policy dynamically
data "aws_iam_policy_document" "inline_s3_list" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::example-bucket"]
    effect    = "Allow"
  }
}

# Separate assume role policy for EC2
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


# IAM role with inline policy
resource "aws_iam_role" "inline_role" {
  name = "inline-role"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  inline_policy {
    name   = "inline-s3-list"
    policy = data.aws_iam_policy_document.inline_s3_list.json
  }
}
