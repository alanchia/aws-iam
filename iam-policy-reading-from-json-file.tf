# If we want to keep an external .json file 

# Create a file named policies/s3_list.json 
/*
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::example-bucket"
    }
  ]
}
*/

# Step 1: Load JSON policy from external file
resource "aws_iam_policy" "s3_list" {
  name   = "managed-s3-list"
  policy = file("policies/s3_list.json")
}

# Step 2: Define multiple roles dynamically
locals {
  roles = {
    ec2    = "ec2.amazonaws.com"
    lambda = "lambda.amazonaws.com"
    batch  = "batch.amazonaws.com"
  }
}

# Create assume-role trust policies dynamically
data "aws_iam_policy_document" "assume_role" {
  for_each = local.roles

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = [each.value]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Create IAM roles for each service
resource "aws_iam_role" "roles" {
  for_each = local.roles

  name               = "example-${each.key}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role[each.key].json
}

# Step 3: Attach the same managed policy to all roles
resource "aws_iam_role_policy_attachment" "attach" {
  for_each = aws_iam_role.roles

  role       = each.value.name
  policy_arn = aws_iam_policy.s3_list.arn
}
