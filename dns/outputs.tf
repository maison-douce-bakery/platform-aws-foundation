output "name_servers" {
  description = "Set these at DigitalPlat for datawithme."
  value       = aws_route53_zone.main.name_servers
}

output "zone_id" {
  description = "ID of the Route 53 hosted zone."
  value       = aws_route53_zone.main.zone_id
}
