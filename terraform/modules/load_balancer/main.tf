# Request ACM certificate
resource "aws_acm_certificate" "certificate" {
  domain_name       = "${var.project}.${var.domain}"
  validation_method = "DNS"

  tags = {
    Name    = "${var.project}-cert"
    project = var.project
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create DNS validation records for ACM certificate
resource "aws_route53_record" "certificate_validation" {
  for_each = { for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => dvo }

  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  zone_id = var.zone_id
  records = [each.value.resource_record_value]
  ttl     = 60
}

# Validate ACM certificate
resource "aws_acm_certificate_validation" "certificate_validation" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.certificate_validation : record.fqdn]
}

# Create security group for the ALB
resource "aws_security_group" "alb_sg" {
  name        = "${var.project}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-alb-sg"
    project = var.project
  }
}

# Create the Application Load Balancer
resource "aws_lb" "application_load_balancer" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false
}

# Create DNS record for the subdomain pointing to the ALB
resource "aws_route53_record" "cluster_record" {
  depends_on = [aws_lb.application_load_balancer]

  zone_id = var.zone_id
  name    = "${var.project}.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_lb.application_load_balancer.dns_name
    zone_id                = aws_lb.application_load_balancer.zone_id
    evaluate_target_health = true
  }
}

# IAM policy for AWS Load Balancer Controller
resource "aws_iam_policy" "aws_lb_controller_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/aws_lb_controller_policy.json")
}

# IAM role for AWS Load Balancer Controller
resource "aws_iam_role" "aws_lb_controller_role" {
  name = "AWSLoadBalancerControllerIAMRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach IAM policy to IAM role
resource "aws_iam_role_policy_attachment" "aws_lb_controller_policy_attachment" {
  policy_arn = aws_iam_policy.aws_lb_controller_policy.arn
  role       = aws_iam_role.aws_lb_controller_role.name
}

# Create Kubernetes service account for AWS Load Balancer Controller
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
  }
  automount_service_account_token = true
}

# Install AWS Load Balancer Controller using Helm
resource "helm_release" "aws_load_balancer_controller" {
  depends_on = [
    kubernetes_service_account.aws_load_balancer_controller,
    aws_iam_role_policy_attachment.aws_lb_controller_policy_attachment
  ]

  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.4.0"  # Use the latest version available

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
  }

  set {
    name  = "serviceAccount.annotations.eks.amazonaws.com/role-arn"
    value = aws_iam_role.aws_lb_controller_role.arn
  }
}