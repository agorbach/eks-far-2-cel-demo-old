############################################
# Account
############################################
variable "account_id" {
  description = "AWS Account ID (12 digits)"
  type        = string
  default     = "748576367822"
}

############################################
# VPC
############################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

  name = "eks-13-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"               = "1"
    "kubernetes.io/cluster/eks-13"         = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"      = "1"
    "kubernetes.io/cluster/eks-13"         = "shared"
  }
}

############################################
# EKS Cluster
############################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.0.0"

  name               = "eks-13"
  kubernetes_version = "1.30"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  cluster_addons = {
    coredns = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }

    vpc-cni = {
      most_recent = true
    }
  }

  #################################################
  # IAM → Kubernetes Access
  #################################################
  access_entries = {
    admin = {
      principal_arn = "arn:aws:iam::${var.account_id}:user/eks-far-2-cel-demo-user"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  #################################################
  # Managed Node Group
  #################################################
  eks_managed_node_groups = {
    default = {
      name           = "default-ng"
      instance_types = ["t3.medium"]
      ami_type       = "AL2_x86_64"

      min_size     = 1
      desired_size = 2
      max_size     = 3
    }
  }
}
