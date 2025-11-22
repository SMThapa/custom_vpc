output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = "http://${aws_lb.alb.dns_name}"
}