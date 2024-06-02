resource "aws_iam_role" "lambda_role" {
  name = "lambdaExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambdaPolicy"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow",
        Action = "ec2:*",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_ssm_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_ec2_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_ssm_full_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_lambda_function" "git_clone_and_docker_compose" {
  function_name  = "gitCloneAndDockerCompose"
  role           = aws_iam_role.lambda_role.arn
  handler        = "lambda_function.lambda_handler"
  runtime        = "python3.8"
  source_code_hash =  data.archive_file.lambda.output_base64sha256
  filename = "./deploy.zip"
  timeout = 300
  environment {
    variables = {
      EC2_INSTANCE_ID = aws_instance.main.id
    }
  }
}

data "archive_file" "lambda" {
    type = "zip"
    source_dir = "./deploy"
    output_path = "./deploy.zip"
  
}
