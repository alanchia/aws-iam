

# Build JSON policy dynamically
data "aws_iam_policy_document" "managed_s3_list" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::example-bucket"]
    effect    = "Allow"
  }
}

# Create standalone managed policy
resource "aws_iam_policy" "managed_s3_list" {
  name   = "managed-s3-list"
  policy = data.aws_iam_policy_document.managed_s3_list.json
}

# IAM role
resource "aws_iam_role" "managed_role" {
  name = "managed-role"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.managed_role.name
  policy_arn = aws_iam_policy.managed_s3_list.arn
}
