# Learns normal daily spend per service and flags unusual spikes.
# Complements the monthly budget: the budget catches totals, this catches sudden changes.
resource "aws_ce_anomaly_monitor" "services" {
  name              = "${local.name_prefix}-services"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "daily" {
  name             = "${local.name_prefix}-anomaly-daily"
  frequency        = "DAILY"
  monitor_arn_list = [aws_ce_anomaly_monitor.services.arn]

  # alert_emails is sensitive and can't drive for_each directly. Only the count is made
  # non-sensitive. Each address stays hidden in plan output.
  dynamic "subscriber" {
    for_each = range(length(nonsensitive(var.alert_emails)))

    content {
      type    = "EMAIL"
      address = var.alert_emails[subscriber.value]
    }
  }

  # Alert when an anomaly's total impact reaches $5 (25% of the monthly budget).
  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["5"]
    }
  }
}
