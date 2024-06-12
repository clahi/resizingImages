resource "aws_iam_role" "lambdaRole" {
  name = "lambdaRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Effect" : "Allow"
        "Action" : [
          "sts:AssumeRole"
        ]
        "Principal" : {
          "Service" : [
            "lambda.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambdaS3Policy" {
  name = "lambdaS3Policy"
  policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        Effect : "Allow"
        Action : [
          "s3:*"
        ]
        Resource : "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambdaRolePolicyAttachment" {
  policy_arn = aws_iam_policy.lambdaS3Policy.arn
  roles      = [aws_iam_role.lambdaRole.name]
  name       = "lambdaRolePolicyAttachment"
}

data "archive_file" "lambdaFile" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "resizeImagesLambda" {
  role             = aws_iam_role.lambdaRole.arn
  filename         = data.archive_file.lambdaFile.output_path
  source_code_hash = data.archive_file.lambdaFile.output_base64sha256
  function_name    = "resizeImagesLambda"
  timeout          = 60
  runtime          = "python3.9"
  handler          = "lambda.lambda_handler"
}

# resource "aws_cloudwatch_event_rule" "resizeEventRule" {
#   name        = "resizeEventRule"
#   description = "Rule to trigger lambda to resize any image uploaded to S3"

# }

# resource "aws_cloudwatch_event_target" "resizeEventRuleTarget" {
#   rule      = aws_cloudwatch_event_rule.resizeEventRule.name
#   arn       = aws_lambda_function.resizeImagesLambda.arn
#   target_id = "resizeEventRuleTarget"
# }

# resource "aws_lambda_permission" "resizeImagePermission" {
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.resizeImagesLambda.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.resizeEventRule.arn
# }