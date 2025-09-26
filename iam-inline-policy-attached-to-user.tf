# This example demonstrates an inline IAM policy attached directly to a user
# Inline policies are:
# - Embedded directly within the user, group, or role
# - Unique to the entity they're attached to
# - Automatically deleted when the entity is deleted
# - Best used for one-off, unique permissions specific to a single entity

# Create an IAM user that will receive the inline policy
resource "aws_iam_user" "example" {
  name = "example-user"
}

# Create an inline policy and attach it to the IAM user
# This policy grants specific S3 permissions to the user
resource "aws_iam_user_policy" "inline" {
  # Name of the inline policy
  name = "inline-s3-access"
  # Reference to the IAM user this policy will be attached to
  user = aws_iam_user.example.name

  # Define the policy document using jsonencode for proper JSON formatting
  policy = jsonencode({
    Version = "2012-10-17" # AWS IAM policy version
    Statement = [{
      Effect   = "Allow"                       # Allow these actions (as opposed to Deny)
      Action   = ["s3:ListBucket"]             # Permission to list contents of an S3 bucket
      Resource = "arn:aws:s3:::example-bucket" # ARN of the specific bucket this applies to
    }]
  })
}
