# Use S3 to test IRSA : IAM Role for pod Service account

This repository creates the S3 bucket, IAM Roles, IAM policy and k8s service account to test pod service account access to AWS S3 bucket.
pod deployment is direct via 'kubectl apply'

# Overview
With the latest release of EKS (1.13 and 1.14), AWS Kubernetes control plane comes with support for IAM roles for service accounts. This feature allows us to associate an IAM role with a Kubernetes service account. We can now provision temporary credentials and then provide AWS permissions to the containers in any pod that uses that service account. Furthermore, we no longer need to provide extended permissions to the worker node IAM role so that pods on that node can call AWS APIs.

![1](https://github.com/bijubayarea/terraform-eks-s3-irsa/blob/main/images/authentication_authorization_flow.png)



# Steps
To configure EKS, OpenID Connect (OIDC) provider, IAM Roles and service accounts using Terraform
- Deploy EKS cluster with IRSA and OIDC enabled (https://github.com/bijubayarea/test-terraform-eks-cluster)
- create S3 bucket as private ()
- create IAM policy to read this private S3 bucket
- create IAM Identity provider with EKS OIDC provider with audience=sts.awsamazon.com
- create IAM Role and attach this IAM S3 Policy
- Create a Service Account with above IAM Role ARN in annotation section of k8s SA (argoCD - https://github.com/bijubayarea/argocd-eks-pod-s3-access)
- use the Service Account in a pod to access the S3 bucket (argoCD - https://github.com/bijubayarea/argocd-eks-pod-s3-access)

# Advantages
The IAM roles for service accounts feature provides the following benefits:

(1) Least privilege- By using the IAM roles for service accounts feature, you no longer need to provide extended permissions to the worker node IAM role so that pods on that node can call AWS APIs. You can scope IAM permissions to a service account, and only pods that use that service account have access to those permissions.

(2) Credential isolation- A container can only retrieve credentials for the IAM role that is associated with the service account to which it belongs. A container never has access to credentials that are intended for another container that belongs to another pod.

(3) Auditability- Access and event logging is available through CloudTrail to help ensure retrospective auditing.

# IAM Roles for Service Accounts Technical Overview
AWS IAM supports federated identities using OIDC. This feature allows us to authenticate AWS API calls with supported identity providers and receive a valid OIDC JSON web token (JWT). You can pass this token to the AWS STS AssumeRoleWithWebIdentity API operation and receive IAM temporary role credentials. Such credentials can be used to communicate with services likes Amazon S3 and DynamoDB.

# AWS Documentation
   link : https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/

   Drilling further down into our solution: OIDC federation access allows you to assume IAM roles via the Secure Token Service (STS), enabling authentication with an OIDC provider, receiving a JSON Web Token (JWT), which in turn can be used to assume an IAM role. Kubernetes, on the other hand, can issue so-called projected service account tokens, which happen to be valid OIDC JWTs for pods. Our setup equips each pod with a cryptographically-signed token that can be verified by STS against the OIDC provider of your choice to establish the pod’s identity. Additionally, we’ve updated AWS SDKs with a new credential provider that calls sts:AssumeRoleWithWebIdentity, exchanging the Kubernetes-issued OIDC token for AWS role credentials.

   The resulting solution is now available in EKS, where we manage the control plane and run the webhook responsible for injecting the necessary environment variables and projected volume. The solution is also available in a DIY Kubernetes setup on AWS; more on that option can be found below.

   To benefit from the new IRSA feature the necessary steps, on a high level, are:

   - Create a cluster with eksctl or terraform and OIDC provider setup enabled. This feature works with EKS clusters 1.13 and above.
   - Create an IAM role defining access to the target AWS services, for example S3, and annotate a service account with said IAM role.
   - Finally, configure your pods by using the service account created in the previous step and assume the IAM role.
   - Because the service account has an eks.amazonaws.com/role-arn annotation, the webhook injects the necessary environment variables (AWS_ROLE_ARN and AWS_WEB_IDENTITY_TOKEN_FILE) and sets up the aws-iam-token projected volume in the pod that the job supervises.

   ![2](https://github.com/bijubayarea/terraform-eks-s3-irsa/blob/main/images/irp-eks-setup-1024x1015.png)
   
# Background
In Kubernetes version 1.12, support was added for a new ProjectedServiceAccountToken feature, which is an OIDC JSON web token that also contains the service account identity, and supports a configurable audience.

Amazon EKS now hosts a public OIDC discovery endpoint per cluster containing the signing keys for the ProjectedServiceAccountToken JSON web tokens so external systems, like IAM, can validate and accept the Kubernetes-issued OIDC tokens.

OIDC federation access allows you to assume IAM roles via the Secure Token Service (STS), enabling authentication with an OIDC provider, receiving a JSON Web Token (JWT), which in turn can be used to assume an IAM role. Kubernetes, on the other hand, can issue so-called projected service account tokens, which happen to be valid OIDC JWTs for pods. Our setup equips each pod with a cryptographically-signed token that can be verified by STS against the OIDC provider of your choice to establish the pod’s identity.

new credential provider ”sts:AssumeRoleWithWebIdentity”

# Preparation

## Spin up EKS cluster using github repo

Repo: https://github.com/bijubayarea/test-terraform-eks-cluster .
This repo is used to spin up EKS Cluster with SPOT EKS managed node group.

## Requirements

To use this repo for demo purposes you will need the following.
- AWS Account (at least one, can do multiple)
- AWS IAM Credentials with admin purposes (for demo)
- AWS IAM Role with adminstrative privileges for Terraform to   assume (multi-account setup)
- AWS S3 Bucket to hold state
- Kubectl installed
- Terraform 0.14.3 installed 
- Basic knowledge of AWS IAM, and Kubernetes components.

## STEPS
    - github to spin up EKS cluster  (https://github.com/bijubayarea/test-terraform-eks-cluster)
    - github to create  (https://github.com/bijubayarea/terraform-eks-s3-irsa)
        - IAM role + trusted entity OIDC(EKS cluster's OIDC)
        -  policy to access one S3 bucket 
        -  role-policy attachment, 
        -  create s3 bucket
        -  create ns = irsa-s3-ns
        -  create service account=s3-policy with IAM Role ARN
        -  create deployment with ns/sa and read/write one S3 bucket.

        
## To spin up
This Repo : https://github.com/bijubayarea/terraform-eks-s3-irsa

- Add your roles, and account ID's to the variables.tf
- Add your pre-existing S3 State bucket to main.tf

- Run `cd src; terraform init`
Which will initialize your workspace and pull any providers needed such as AWS and the Kubernetes providers.

Then run a terraform plan `terraform plan -var 'env=test' src/`

If looks ok go ahead and run the apply `terraform apply -var 'env=test' src/`

Answer with yes when asked if you want to apply. It will take a bit to provision the VPC, related resources, the EKS cluster and related resources. Once done you need to setup your local kubectl for access by running `aws eks update-kubeconfig --region us-west-2 --name aws-vpc` or `aws eks update-kubeconfig --region us-west-2 --name aws-vpc --role arn:aws:iam::<account_id>:role/<name>` with whatever role you used to create the cluster (defined in variables).

## Config 

![3](https://github.com/bijubayarea/terraform-eks-s3-irsa/blob/main/images/irsa-oidc.png)

![4](https://github.com/bijubayarea/terraform-eks-s3-irsa/blob/main/images/Trusted_Entities.png)


![5](https://github.com/bijubayarea/terraform-eks-s3-irsa/blob/main/images/s3_policy.png)


## Kubernetes Testing
To deploy the demo app to test IRSA ability run:
`kubectl apply -f demo_irsa_app/demo_app.yaml --dry-run=client`
if the dry run looks ok go ahead and apply it.
`kubectl apply -f demo_irsa_app/demo_app.yaml`

Once deployed you can describe the deployment, service account, etc and see how they are linked up.


```hcl
      $ k get deploy -n irsa-s3-ns
        NAME      READY   UP-TO-DATE   AVAILABLE   AGE
        aws-cli   1/1     1            1           65s 
        
        $ k get pod -n irsa-s3-ns
        NAME                       READY   STATUS    RESTARTS   AGE
        aws-cli-7cb595d468-sl5ln   1/1     Running   0          78s
               
        $ k logs -n aws-cli aws-cli-7cb595d468-sl5ln -c aws-cli
        Error from server (NotFound): namespaces "aws-cli" not found      
        
        $ k logs -n irsa-s3-ns aws-cli-7cb595d468-sl5ln -c aws-cli
        2022-10-19 22:46:38 bijubayarea-s3-irsa-backend
        2022-10-19 15:35:07 bijubayarea-s3-remote-backend-deadbeef
        2022-10-20 18:40:32 bijubayarea-s3-test 

      ```


## Tear Down
First empty your s3 bucket.
`terraform destroy -var 'env=test' src/`