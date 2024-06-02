# variables.tf

variable "instance_profile_name" {
  description = "The name of the IAM instance profile"
  type        = string
  default     = "ecr-access-instance-profile"
}


# ecr.tf
resource "aws_ecr_repository" "frontend" {
  name = var.client_registry
}

resource "aws_ecr_repository" "backend" {
  name = var.server_registry
}


# iam.tf
resource "aws_iam_role" "ecr_access_role" {
  name = "ecr-access-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecr_access_policy" {
  name   = "ecr-access-policy"
  role   = aws_iam_role.ecr_access_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ecr_access_instance_profile" {
  name = var.instance_profile_name
  role = aws_iam_role.ecr_access_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role       = aws_iam_role.ecr_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "lambda_full_access" {
  role       = aws_iam_role.ecr_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}



