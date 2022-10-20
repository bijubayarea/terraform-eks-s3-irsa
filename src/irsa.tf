data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions = [
      "s3:ListAllMyBuckets",
    ]

    resources = [
      "*",
    ]
  }
  statement {
    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.irsa.arn,
      "${aws_s3_bucket.irsa.arn}/*"
    ]
  }
}

module "s3_policy_role" {
  source                = "../modules/eks_irsa"
  enable_irsa           = true
  namespace             = "default"
  serviceaccount        = "s3-policy"
  create_serviceaccount = true
  #cluster               = var.cluster_name
  cluster               = data.aws_eks_cluster.cluster.name
  #issuer_url            = replace(module.aws_vpc_eks.cluster_oidc_issuer_url, "https://", "")
  issuer_arn            = data.aws_iam_openid_connect_provider.eks_oidc_provider.arn
  issuer_url            = replace(data.aws_iam_openid_connect_provider.eks_oidc_provider.url, "https://", "")
  iam_role              = module.s3_policy_role.irsa_role
  aws_account_id        = var.aws_account_id[var.env]
  policy                = data.aws_iam_policy_document.s3_policy.json
}
