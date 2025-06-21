data "aws_eks_addon_version" "s3_csi_driver" {
  addon_name         = "aws-mountpoint-s3-csi-driver"
  kubernetes_version = var.eks_cluster_version
}