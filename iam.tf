# 1. Create IAM Policy for External-DNS
resource "aws_iam_policy" "external_dns" {
  name        = "ExternalDNSPolicy"
  description = "Allows External-DNS to manage Route53 records"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = ["arn:aws:route53:::hostedzone/*"]
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ]
        Resource = ["*"]
      }
    ]
  })
}

# 2. Create IAM Role and attach to a K8s Service Account 
module "external_dns_irsa" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name             = "external-dns"
  attach_external_dns_policy = true
  
  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }
}

module "mountpoint_s3_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.54.1"

  role_name_prefix   = "${var.name}-s3-csi-"
  policy_name_prefix = "${var.name}-s3-csi-"

  # IAM policy to attach to driver
  attach_mountpoint_s3_csi_policy = true

  mountpoint_s3_csi_bucket_arns = [var.mountpoint_s3_csi_path_arns.0]
  mountpoint_s3_csi_path_arns   = ["${var.mountpoint_s3_csi_path_arns.0}","${var.mountpoint_s3_csi_path_arns.0}/*"]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:s3-csi-driver-*"]
    }
  }

  force_detach_policies = true
}
