
# use remote s3 backend tfstate
data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "bijubayarea-s3-remote-backend-deadbeef"
    key    = "test-terraform-eks-cluster/terraform.tfstate"
    region = var.region
  }

}

# local backed tfstate
#data "terraform_remote_state" "eks" {
#  backend = "local"
#
#  config = {
#    path = "../test-terraform-eks-cluster/terraform.tfstate"
#  }
#}

# Retrieve EKS cluster information
provider "aws" {
  region                   = data.terraform_remote_state.eks.outputs.region
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "vscode-user"
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.aws_eks_cluster.cluster.name
    ]
  }
}

/*
provider "kubernetes" {
  host = var.host

  client_certificate     = var.client_certificate
  client_key             = var.client_key
  cluster_ca_certificate = var.cluster_ca_certificate
}
*/