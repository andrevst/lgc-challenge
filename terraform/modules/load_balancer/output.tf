output "app_dns" {
  description = "The DNS name for the application"
  value       = aws_route53_record.cluster_record.fqdn
}

output "acm_certificate_arn" {
  description = "The ARN of the ACM certificate"
  value       = aws_acm_certificate.certificate.arn
}

output "alb_arn" {
  description = "The ARN of the ALB"
  value       = aws_lb.application_load_balancer.arn
}

output "domain_name" {
  value = aws_route53_record.cluster_record.name
}