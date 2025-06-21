variable "cluster_name" {
  description = "Name of the VPC and EKS Cluster"
  default     = "limanEKS-cluster-us"
  type        = string
}

variable "name" {
  description = "Name of the VPC and EKS Cluster"
  default     = "limanEKS"
  type        = string
}

variable "region" {
  description = "region"
  default     = "us-east-1"
  type        = string
}

variable "eks_cluster_version" {
  description = "EKS Cluster version"
  default     = "1.32"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR. This should be a valid private (RFC 1918) CIDR range"
  default     = "10.0.0.0/16"
  type        = string
}

variable "mountpoint_s3_csi_path_arns" {
  description = "List of S3 path ARNs (with wildcard suffix) for Mountpoint S3 CSI"
  type        = list(string)
  default     = [
    "arn:aws:s3:::kuberntes-limanEKS-data"
  ]
}