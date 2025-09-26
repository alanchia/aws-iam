# This example demonstrates using a data resource to create a standalone policy
# that can be attached to users, groups, or roles
# The policy is defined using a data resource for better readability and maintainability

# Create an IAM user that will receive the policy
resource "aws_iam_user" "example_data" {
  name = "example-data-user"
}

# Create the policy document using AWS's policy document data source
# This allows for a more structured way to define the policy
data "aws_iam_policy_document" "s3_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::example-bucket",
      "arn:aws:s3:::example-bucket/*"
    ]
  }
}

# Create the IAM policy resource using the data source
# This creates a standalone policy that can be reused
resource "aws_iam_policy" "s3_access" {
  name        = "s3-access-from-data"
  description = "S3 access policy created from data resource"
  policy      = data.aws_iam_policy_document.s3_access.json # Use the JSON from the data source directly
}

# Attach the policy to the IAM user
resource "aws_iam_user_policy_attachment" "user_s3_access" {
  user       = aws_iam_user.example_data.name
  policy_arn = aws_iam_policy.s3_access.arn
}