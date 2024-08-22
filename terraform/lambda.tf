
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "lambda_bedrock_rag_retreival_role" {
  name = "Lambda-${var.aws_region}-BedrockRagRetreival"

  assume_role_policy = jsonencode(
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
)
}
resource "aws_iam_role_policy" "lambda_bedrock_rag_retreival_policy" {
  name        = "Lambda-${var.aws_region}-BedrockRagRetreival"
  role        = aws_iam_role.lambda_bedrock_rag_retreival_role.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
          Action = [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface"
          ],
          Effect   = "Allow",
          Resource = "*"
        },
        {
            "Sid": "Bedrock",
            "Effect": "Allow",
            "Action": [
                "bedrock:*"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "OpensearchServerless",
            "Effect": "Allow",
            "Action": [
                "aoss:*"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Opensearch",
            "Effect": "Allow",
            "Action": [
                "es:*"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "DynamoDB",
            "Effect": "Allow",
            "Action": [
                "dynamodb:*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
    })
}


resource "aws_iam_role_policy_attachment" "lambda_cloudwatch" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_bedrock_rag_retreival_role.name
}

resource "aws_lambda_function" "bedrock_rag_retreival" {

  image_uri = docker_registry_image.push-rag-image.name
  function_name = "bedrock_rag_retreival"
  role          = aws_iam_role.lambda_bedrock_rag_retreival_role.arn

  architectures = ["x86_64"]
  package_type = "Image"

  timeout = 90

  environment {
    variables = {
      aoss_host = instaclustr_opensearch_cluster_v2.example.load_balancer_connection_url
      cassandra_hosts = join(",", flatten([for dc in instaclustr_cassandra_cluster_v2.example.data_centre : [for node in dc.nodes : node.public_address]]))
      os_username = instaclustr_opensearch_cluster_v2.example.default_username
      os_password = instaclustr_opensearch_cluster_v2.example.default_user_password
    }
  }
  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0]]
    security_group_ids = [aws_security_group.fsx_sg.id]
  }
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bedrock_rag_retreival.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.bedrock_lambda.execution_arn}/*/*/${aws_api_gateway_resource.root.path_part}"
}