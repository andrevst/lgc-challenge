output "ecr_repository_url" {
    value = module.host.aws_ecr_repository_url
}

output "app_url" {
    value = module.load_balancer.domain_name
}