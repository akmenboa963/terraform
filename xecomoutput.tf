# Output the public DNS name of the Application Load Balancer
output "alb-dns" {
  value = aws_lb.alb.dns_name
}
