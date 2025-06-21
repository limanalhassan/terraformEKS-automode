provider "kubernetes" {
  alias                  = "eks"
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", "terraform"]
  }
}

resource "null_resource" "wait_for_cluster" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = "Start-Sleep -Seconds 45; aws eks wait cluster-active --name ${module.eks.cluster_name} --profile terraform"
  }
}

resource "null_resource" "kube_config" {
  depends_on = [null_resource.wait_for_cluster]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region} --profile terraform"
  }
}

resource "null_resource" "apply_nodeclass" {
  depends_on = [null_resource.kube_config]

  provisioner "local-exec" {
    # Create a temporary YAML file and apply it
    interpreter = ["PowerShell", "-Command"]
    command     = <<EOT
$yamlContent = @"
apiVersion: eks.amazonaws.com/v1
kind: NodeClass
metadata:
  name: default-nodeclass
spec:
  ephemeralStorage:
    size: 200Gi
  networkPolicy: DefaultAllow
  networkPolicyEventLogs: Disabled
  role: ${module.eks.node_iam_role_name}
  securityGroupSelectorTerms:
  - tags:
      aws:eks:cluster-name: ${module.eks.cluster_name}
  snatPolicy: Random
  subnetSelectorTerms:
  - tags:
      karpenter.sh/discovery: ${module.eks.cluster_name}
  tags:
     "Name": "limanEKS-eks-worker-node"
"@

$yamlContent | Out-File -FilePath "nodeclass.yaml" -Encoding utf8
kubectl apply -f nodeclass.yaml
Remove-Item -Path "nodeclass.yaml"
EOT
  }
}

resource "null_resource" "apply_nodepool" {
  depends_on = [null_resource.apply_nodeclass]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = <<EOT
$yamlContent = @"
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default-nodepool
  labels:
    nodepool-type: default
    instance-type: basic
spec:
  disruption:
    budgets:
    - nodes: "10%"
    consolidateAfter: 30s
    consolidationPolicy: WhenEmptyOrUnderutilized
  template:
    metadata:
      labels:
        workload-type: default
    spec:
      expireAfter: 336h
      nodeClassRef:
        group: eks.amazonaws.com
        kind: NodeClass
        name: default-nodeclass
      requirements:
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["spot"]
      - key: eks.amazonaws.com/instance-category
        operator: In
        values: ["t", "c", "m"]
      - key: kubernetes.io/arch
        operator: In
        values: ["amd64"]
      - key: kubernetes.io/os
        operator: In
        values: ["linux"]
"@

$yamlContent | Out-File -FilePath "nodepool.yaml" -Encoding utf8
kubectl apply -f nodepool.yaml
Remove-Item -Path "nodepool.yaml"
EOT
  }
}