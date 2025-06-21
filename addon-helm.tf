################################################################################
# ArgoCD Installation
################################################################################

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "8.0.1"

  values = [
    file("${path.module}/helm-valuesFiles/argocd.yaml")
  ]

  depends_on = [
    module.eks,
    null_resource.apply_nodeclass
  ]
}

resource "helm_release" "metrics_server" {
  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  namespace        = "kube-system"
  create_namespace = false
  version          = "3.12.2"

  values = [
    <<-EOT
    resources:
      limits:
        cpu: 100m
        memory: 200Mi
      requests:
        cpu: 50m
        memory: 100Mi
    EOT
  ]

  depends_on = [
    module.eks,
    null_resource.apply_nodeclass
  ]
}

resource "helm_release" "eks_s3_csi" {
  name             = "aws-mountpoint-s3-csi-driver"
  repository       = "https://awslabs.github.io/mountpoint-s3-csi-driver"
  chart            = "aws-mountpoint-s3-csi-driver"
  namespace        = "kube-system"
  create_namespace = false
  version          = "1.14.1"

  values = [
    <<-EOT
    node:
      serviceAccount:
        create: true
        name: s3-csi-driver-sa
        annotations:
          "eks.amazonaws.com/role-arn": ${module.mountpoint_s3_csi_driver_irsa.iam_role_arn}
      tolerateAllTaints: true
      resources:
        limits:
          cpu: 100m
          memory: 256Mi
        requests:
          cpu: 50m
          memory: 40Mi
    EOT
  ]

  depends_on = [
    module.eks,
    null_resource.apply_nodeclass
  ]
}

resource "helm_release" "externalDNS" {
  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  namespace        = "kube-system"
  create_namespace = false
  version          = "1.16.1"

  values = [
    <<-EOT
    serviceAccount:
      create: true
      name: external-dns
      annotations:
        eks.amazonaws.com/role-arn: ${module.external_dns_irsa.iam_role_arn}
    
    provider: aws

    sources:
     - ingress
    managedRecordTypes: ["CNAME"]
    
    policy: sync
    
    txtOwnerId: "${var.cluster_name}"
    
    resources:
      limits:
        cpu: 100m
        memory: 200Mi
      requests:
        cpu: 50m
        memory: 100Mi
    EOT
  ]

  depends_on = [
    module.eks,
    null_resource.apply_nodeclass,
    module.external_dns_irsa
  ]
}

# resource "aws_eks_addon" "eks_s3_csi" {
#   cluster_name                = module.eks.cluster_name
#   addon_name                  = "aws-mountpoint-s3-csi-driver"
#   addon_version               = data.aws_eks_addon_version.s3_csi_driver.version
#   resolve_conflicts_on_create = "OVERWRITE"
#   service_account_role_arn    = module.mountpoint_s3_csi_driver_irsa.iam_role_arn
# }