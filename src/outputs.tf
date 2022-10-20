output "cluster_name" {
  description = "EKS Cluster Name"
  value       = data.aws_eks_cluster.cluster.name
}

output "oidc_provider_url" {
  description = "oidc provider url"
  #value       =  data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  value       =  replace(data.aws_iam_openid_connect_provider.eks_oidc_provider.url, "https://", "")
}

output "oidc_provider_arn" {
  description = "oidc provider arn"
  value       =  data.aws_iam_openid_connect_provider.eks_oidc_provider.arn
}

output "iam_role" {
  description = "iam role"
  value       =  module.s3_policy_role.irsa_role
}
