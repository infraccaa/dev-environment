resource "aws_route53_record" "dev_dns" {
  zone_id = var.hosted_zone_id
  name    = var.record_name
  type    = "A"
  ttl     = 300
  records = [var.fortinet_external_ip]
}
