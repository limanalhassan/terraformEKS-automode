# tofu EKS Infrastructure

<div align="center">

[![tofu](https://img.shields.io/badge/tofu-%235835CC.svg?style=for-the-badge&logo=tofu&logoColor=white)](https://opentofu.org/docs/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/docs/home/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://docs.aws.amazon.com/eks/latest/userguide/automode.html)

</div>

<p align="center">
  <strong>A comprehensive tofu configuration for deploying and managing MoonliteLabs Amazon Elastic Kubernetes Service (EKS) clusters with essential add-ons and configurations.</strong>
</p>

---

## 🏗️ Architecture Overview

This tofu configuration deploys a our EKS cluster with the following components:

- **EKS Cluster** with self and AWS managed node groups
- **VPC** with public/private subnets
- **IAM roles** Roles and policies for cluster and nodes
- **Helm-based add-ons** including ArgoCD, External DNS, Ingress settings for EKS auto-mode, and Metrics Server
- **GPU-enabled node pools** (manual deployment)
- **S3-backed persistent storage** Configurations for how our statefiles are stored and operated

## 📁 Project Structure

<details>
<summary>Current file structure</summary>

```
terraformEKS/
├── README.md                    # This documentation
├── backend.tf                   # tofu state backend configuration
├── versions.tf                  # tofu and provider version constraints
├── variables.tf                 # Input variables definitions
├── output.tf                    # Output values
├── data.tf                      # Data sources
├── main.tf                      # Main tofu configuration
├── vpc.tf                       # VPC and networking resources
├── eks.tf                       # EKS cluster configuration
├── iam.tf                       # IAM roles and policies
├── default-nodes.tf             # Default EKS managed node groups
├── auth_config.tf               # Kubernetes authentication configuration
├── addon-helm.tf                # Helm charts and add-ons deployment
├── helm-valuesFiles/            # Helm chart values configurations
│   ├── argocd.yaml              # ArgoCD configuration
│   ├── externalDNS.yaml         # External DNS configuration
│   ├── ingress-confirm.yaml     # Ingress controller configuration  
│   └── metric-server.yaml       # Metrics server configuration
└── manifests/                   # Kubernetes manifests (manual deployment)
    ├── gpu-nodepools.yaml       # GPU-enabled node pool configuration
    ├── pod-test.yaml            # Test pod for validation
    └── s3-pv-pvc.yaml           # S3-backed persistent storage
```

</details>

## 🚀 Quick Start

<details>
<summary>📋 Prerequisites</summary>

<br>

We need the following tools installed before the use of this configuration:

- [tofu](https://www.tofu.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate permissions
- [kubectl](https://kubernetes.io/docs/tasks/tools/) for cluster management

</details>

<details>
<summary>🔑 Required AWS Permissions</summary>

<br>

AWS credentials must have permissions for:
- **EC2**: VPC, Subnets, Security Groups, NAT Gateway
- **EKS**: Cluster, Node Groups, Add-ons
- **IAM**: Roles, Policies, Instance Profiles
- **S3**: For tofu state backend

</details>

### 🛠️ Deployment Steps

1. **Clone the repository**
   ```bash
   git clone git@github.com:Moonlite-Media/tofuEKS.git
   cd terraformEKS
   ```

2. **Configure variables**
   ```bash
   Review and modify variables.tf as needed
   ```

3. **Initialize tofu**
   ```bash
   tofu init
   ```

4. **Plan the deployment**
   ```bash
   tofu plan
   ```

5. **Apply the configuration**
   ```bash
   tofu apply
   ```

6. **Configure kubeconfig for kubectl**
   ```bash
   aws eks update-kubeconfig --name limanEKS-cluster-us --region us-east-1
   ```

7. **Deploy manual manifests**
   ```bash
   kubectl apply -f manifests/
   ```

## ⚙️ Configuration

<details>
<summary>🔧 Core Variables</summary>

<br>

Key variables you should configure in `tofu.tfvars` but currently in `variables.tf`:

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `cluster_name` | Name of the EKS cluster | limanEKS-cluster-us | ✅ |
| `region` | AWS region for deployment | us-east-1 | ✅ |
| `vpc_cidr` | CIDR block for VPC | `10.0.0.0/16` | ✅ |
| `node_instance_type` | EC2 instance type for nodes | `dynamic` | ✅ |
| `node_group_size` | Desired number of nodes | `dynamic` | ✅ |

</details>

### 🔍 Exploring Module Outputs

To get all available outputs from each module, you can use the OpenTofu/Terraform console:

<details>
<summary>💡 Using tofu console for module exploration</summary>
<br>

**Start the console:**
```bash
tofu console
```

## Explore specific modules:

**Get all EKS module outputs**
```bash
module.eks
```

**Get all VPC module outputs** 
```bash
module.vpc
```

**Get all IAM module outputs**
```bash
module.iam
```

**Access specific values:**
```bash
# Example: Get specific EKS cluster details
module.eks.cluster_endpoint
module.eks.cluster_security_group_id
```

**Example: Get VPC details**
```bash
module.vpc.vpc_id
module.vpc.private_subnet_ids
```


This approach helps you discover all available outputs from each module without having to check the source code.

</details>


### 🎯 Helm Add-ons

The following add-ons are automatically deployed via Helm using helm release:

<details>
<summary>🔄 ArgoCD</summary>

- **Purpose**: GitOps continuous delivery tool
- **Configuration**: `helm-valuesFiles/argocd.yaml`
- **Access**: Available via `https://argocd.limanEKSlabs.com/`

</details>

<details>
<summary>🌐 External DNS</summary>

- **Purpose**: Automatically manage DNS records for services
- **Configuration**: `helm-valuesFiles/externalDNS.yaml`
- **Requirements**: Route53 hosted zone

</details>

<details>
<summary>🚪 Ingress Controller</summary>

- **Purpose**: Manage ingress traffic to the cluster via EKS auto-mode. The configuration contains ingressParam and ingressClassParam
- **Configuration**: `helm-valuesFiles/ingress-confirm.yaml`
- **Type**: EKS auto-mode managed ingress `https://docs.aws.amazon.com/eks/latest/userguide/auto-configure-alb.html`

</details>

<details>
<summary>📈 Metrics Server</summary>

- **Purpose**: Cluster-wide resource usage metrics
- **Configuration**: `helm-valuesFiles/metric-server.yaml`
- **Used by**: `kubectl top pods`, `kubectl top nodes`

</details>

## 🔧 Manual Deployments

> **Note**: The `manifests/` directory contains Kubernetes resources that require manual deployment after tofu completes.

<details>
<summary>🎮 GPU Node Pools</summary>

<br>

```bash
kubectl apply -f manifests/gpu-nodepools.yaml
```
Deploys GPU nodes for our workloads.

</details>

<details>
<summary>💾 S3 Persistent Storage</summary>

<br>

```bash
kubectl apply -f manifests/s3-pv-pvc.yaml
```
Creates persistent volumes backed by S3 for stateful applications.

</details>

<details>
<summary>🧪 Test Pod</summary>

<br>

```bash
kubectl apply -f manifests/pod-test.yaml
```
Deploys a test pod for cluster validation and troubleshooting.

</details>

## 📊 Outputs

After successful deployment, tofu provides:

- 🔗 `cluster_endpoint` - EKS cluster API endpoint
- 📛 `cluster_name` - Name of the created EKS cluster  
- 🏷️ `cluster_arn` - ARN of the EKS cluster
- 🚀 `node_group_arn` - ARN of the managed node group
- 🌐 `vpc_id` - ID of the created VPC

---

## 🛠️ Management Commands

<details>
<summary>🔐 Cluster Access</summary>

<br>

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name limanEKS-cluster-us

# Verify cluster access
kubectl cluster-info
kubectl get nodes
```

</details>

## 🔒 Security Considerations

- 🛡️ **RBAC**: Kubernetes RBAC configured via `auth_config.tf`
- 🔑 **IAM**: Least-privilege IAM roles for cluster and nodes
- 🌐 **Network**: Private subnets for worker nodes  
- 🔐 **Encryption**: EKS secrets encryption at rest with KMS key

---

## 🚨 Troubleshooting

<details>
<summary>❗ Common Issues that would be faced while accessing the cluster</summary>

<br>

### 1. Node group creation fails
- ✅ Check IAM permissions for EKS service role
- ✅ Verify subnet configuration and availability zones

### 2. Add-ons fail to install  
- ✅ Ensure cluster is ready: `kubectl get nodes`

### 3. kubectl access denied
- ✅ Update kubeconfig: `aws eks update-kubeconfig --name limanEKS-cluster-us --region us-east-1`
- ✅ Verify AWS credentials and region
- ✅ `kubectl config current-context`

</details>

<details>
<summary>🔍 Debugging Commands</summary>

<br>

```bash
# Check cluster status
aws eks describe-cluster --name limanEKS-cluster-us

# Check pod logs
kubectl logs -f <pod-name> -n <namespace>
```

</details>

</div>