# ---------------------------------------------------------------------------
# Scale-to-Zero — Lambda + EventBridge schedule
# Stops the controller outside business hours to save ~65% on EC2.
# ---------------------------------------------------------------------------

variable "enable_scale_to_zero" {
  description = "Enable automatic start/stop of Jenkins controller outside business hours"
  type        = bool
  default     = true
}

variable "schedule_start_cron" {
  description = "Cron expression (UTC) to start the controller (default: Mon–Fri 07:00 UTC)"
  type        = string
  default     = "cron(0 7 ? * MON-FRI *)"
}

variable "schedule_stop_cron" {
  description = "Cron expression (UTC) to stop the controller (default: Mon–Fri 19:00 UTC)"
  type        = string
  default     = "cron(0 19 ? * MON-FRI *)"
}

# --- Lambda function ---
data "archive_file" "scale_to_zero" {
  count       = var.enable_scale_to_zero ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/lambda/scale_to_zero.py"
  output_path = "${path.module}/lambda/scale_to_zero.zip"
}

resource "aws_lambda_function" "scale_to_zero" {
  count            = var.enable_scale_to_zero ? 1 : 0
  function_name    = "${var.project_name}-scale-to-zero"
  runtime          = "python3.12"
  handler          = "scale_to_zero.handler"
  role             = aws_iam_role.scale_to_zero[0].arn
  filename         = data.archive_file.scale_to_zero[0].output_path
  source_code_hash = data.archive_file.scale_to_zero[0].output_base64sha256
  timeout          = 30

  environment {
    variables = {
      INSTANCE_ID  = aws_instance.jenkins_controller.id
      TARGET_REGION = var.aws_region
    }
  }

  tags = { Name = "${var.project_name}-scale-to-zero" }
}

# --- IAM for Lambda ---
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "scale_to_zero" {
  count              = var.enable_scale_to_zero ? 1 : 0
  name               = "${var.project_name}-scale-to-zero"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "scale_to_zero" {
  statement {
    actions   = ["ec2:StartInstances", "ec2:StopInstances"]
    resources = [aws_instance.jenkins_controller.arn]
  }
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "scale_to_zero" {
  count  = var.enable_scale_to_zero ? 1 : 0
  name   = "ec2-start-stop"
  role   = aws_iam_role.scale_to_zero[0].id
  policy = data.aws_iam_policy_document.scale_to_zero.json
}

# --- EventBridge schedules ---
resource "aws_cloudwatch_event_rule" "start_controller" {
  count               = var.enable_scale_to_zero ? 1 : 0
  name                = "${var.project_name}-start-controller"
  description         = "Start Jenkins controller on weekday mornings"
  schedule_expression = var.schedule_start_cron
  tags                = { Name = "${var.project_name}-start-controller" }
}

resource "aws_cloudwatch_event_rule" "stop_controller" {
  count               = var.enable_scale_to_zero ? 1 : 0
  name                = "${var.project_name}-stop-controller"
  description         = "Stop Jenkins controller on weekday evenings"
  schedule_expression = var.schedule_stop_cron
  tags                = { Name = "${var.project_name}-stop-controller" }
}

resource "aws_cloudwatch_event_target" "start" {
  count     = var.enable_scale_to_zero ? 1 : 0
  rule      = aws_cloudwatch_event_rule.start_controller[0].name
  target_id = "start"
  arn       = aws_lambda_function.scale_to_zero[0].arn
  input     = jsonencode({ action = "start" })
}

resource "aws_cloudwatch_event_target" "stop" {
  count     = var.enable_scale_to_zero ? 1 : 0
  rule      = aws_cloudwatch_event_rule.stop_controller[0].name
  target_id = "stop"
  arn       = aws_lambda_function.scale_to_zero[0].arn
  input     = jsonencode({ action = "stop" })
}

resource "aws_lambda_permission" "start" {
  count         = var.enable_scale_to_zero ? 1 : 0
  statement_id  = "AllowEventBridgeStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scale_to_zero[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_controller[0].arn
}

resource "aws_lambda_permission" "stop" {
  count         = var.enable_scale_to_zero ? 1 : 0
  statement_id  = "AllowEventBridgeStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scale_to_zero[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_controller[0].arn
}
