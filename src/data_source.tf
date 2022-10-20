
# Get the OIDC provider provisioned for EKS cluster
data "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

