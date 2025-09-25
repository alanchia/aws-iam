
# Step 1: Build JSON policy using data resource
data "aws_iam_policy_document" "s3_list" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::example-bucket"]
  }
}

# Step 2: Create a standalone managed policy
resource "aws_iam_policy" "s3_list" {
  name   = "managed-s3-list"
  policy = data.aws_iam_policy_document.s3_list.json
}

# Step 3: Define the IAM role (assume role trust policy)
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

# Step 4: Create the IAM role 
resource "aws_iam_role" "example" {
  name               = "example-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Step 5: Attach the managed policy to the role
resource "aws_iam_role_policy_attachment" "example_attach" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.s3_list.arn
}
