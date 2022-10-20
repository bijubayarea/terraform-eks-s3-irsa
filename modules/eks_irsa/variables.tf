variable "namespace" {
  description = "Name of Kubernetes namespace"
}

variable "serviceaccount" {
  description = "Name of Kubernetes serviceaccount"
  default     = ""
}

variable "cluster" {
  description = "Name of Kubernetes cluster"
  default     = ""
}

variable "create_namespace" {
  description = "Enables creating the namespace"
  default     = true
}

variable "create_serviceaccount" {
  description = "Enables creating a serviceaccount"
  default     = false
}

variable "enable_irsa" {
  description = "Add irsa role for the serviceaccount"
  default     = false
}

variable "policy" {
  description = "Policy json to apply to the irsa role"
  default     = ""
}

variable "issuer_arn" {
  description = "EKS cluster OIDC ARN"
  default     = ""
}

variable "issuer_url" {
  description = "EKS cluster OIDC ARN"
  default     = ""
}

variable "aws_account_id" {
  description = "AWS account id to configure irsa role"
  default     = ""
}

variable "iam_role" {
  description = "iam role"
  default     =  ""
}