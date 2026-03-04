# ---------------------------------------------------------------------------
# CloudWatch Alarm — Controller CPU threshold
# ---------------------------------------------------------------------------
variable "cpu_alarm_threshold" {
  description = "CPU utilization percentage to trigger alarm"
  type        = number
  default     = 80
}

variable "cpu_alarm_sns_topic_arn" {
  description = "SNS topic ARN for CPU alarm notifications (optional)"
  type        = string
  default     = ""
}

resource "aws_cloudwatch_metric_alarm" "controller_cpu" {
  alarm_name          = "${var.project_name}-controller-cpu-high"
  alarm_description   = "Jenkins controller CPU utilization > ${var.cpu_alarm_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold

  dimensions = {
    InstanceId = aws_instance.jenkins_controller.id
  }

  actions_enabled = var.cpu_alarm_sns_topic_arn != ""
  alarm_actions   = var.cpu_alarm_sns_topic_arn != "" ? [var.cpu_alarm_sns_topic_arn] : []
  ok_actions      = var.cpu_alarm_sns_topic_arn != "" ? [var.cpu_alarm_sns_topic_arn] : []

  tags = { Name = "${var.project_name}-controller-cpu-high" }
}
