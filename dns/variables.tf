variable "region" {
  description = "Primary AWS region."
  type        = string
  default     = "ap-southeast-2"
}

variable "zone_name" {
  description = "DNS zone to host in Route 53."
  type        = string
  default     = "datawithme.qd.je"
}
