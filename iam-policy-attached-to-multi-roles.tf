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

# Step 3: Define trust policies for multiple roles
data "aws_iam_policy_document" "assume_ec2" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "assume_lambda" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Step 4: Create multiple roles
resource "aws_iam_role" "ec2_role" {
  name               = "example-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

resource "aws_iam_role" "lambda_role" {
  name               = "example-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

# Step 5: Attach the same managed policy to both roles
resource "aws_iam_role_policy_attachment" "attach_ec2" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_list.arn
}

resource "aws_iam_role_policy_attachment" "attach_lambda" {
  policy_arn = aws_iam_policy.s3_list.arn
}
