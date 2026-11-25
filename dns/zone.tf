# Durable and never torn down: recreating the zone changes the nameservers, which are set by hand at DigitalPlat (no API).
resource "aws_route53_zone" "main" {
  name    = var.zone_name
  comment = "Public zone for ${var.zone_name}"

  lifecycle {
    prevent_destroy = true
  }
}
