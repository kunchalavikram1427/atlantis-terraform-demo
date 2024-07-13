# Atlantis Terraform Demo
https://github.com/runatlantis/atlantis-example

## Installing tools

### Installing AWS CLI
https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html
https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html
```
aws --version
aws configure help
```

### Installing kubectl
https://kubernetes.io/docs/tasks/tools/
```
kubectl version
```

### Installing eksctl
https://aws.amazon.com/eks/
https://docs.aws.amazon.com/eks/
https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html
https://eksctl.io/
https://github.com/weaveworks/eksctl
```
eksctl version
```

## Create EKS Cluster

### Create IAM User
Create another IAM user with programmatic access

### Configure AWS CLI
```
aws configure
```
Check if credentials are working properly or not
```
aws iam list-users
```
```
{
    "Users": [
        {
            "Path": "/",
            "UserName": "DEMO_USER",
            "UserId": "XYZ",
            "Arn": "arn:aws:iam::223344556:user/DEMO_USER",
            "CreateDate": "2024-06-27T09:56:19+00:00"
        }
    ]
}
```


### Create EKS cluster through EKSCTL
```
eksctl create cluster --name test --region=ap-south-1 --nodegroup-name demo --nodes 2 --nodes-min 1 --nodes-max 2 --node-volume-size 8 
```
```
eksctl get cluster --region=ap-south-1
```
```
NAME    REGION          EKSCTL CREATED
test    ap-south-1      True
```

### Get kube config
```
aws eks update-kubeconfig --region ap-south-1 --name test 
```
```
kubectl get nodes
NAME                                            STATUS   ROLES    AGE     VERSION
ip-192-168-51-70.ap-south-1.compute.internal    Ready    <none>   6m45s   v1.30.0-eks-036c24b
ip-192-168-68-105.ap-south-1.compute.internal   Ready    <none>   6m43s   v1.30.0-eks-036c24b
```

### Associate OIDC provider
https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html
```
eksctl utils associate-iam-oidc-provider --region=ap-south-1 --cluster=test --approve
```
```
aws eks describe-cluster --name test --query "cluster.identity.oidc.issuer" --output text
```
### Deploy AWS LoadBalancer Controller
The AWS Load Balancer Controller manages AWS Elastic Load Balancers for a Kubernetes cluster. You can use the controller to expose your cluster apps to the internet. The controller provisions AWS load balancers that point to cluster Service or Ingress resources. In other words, the controller creates a single IP address or DNS name that points to multiple pods in your cluster.
- https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
- https://docs.aws.amazon.com/eks/latest/userguide/lbc-helm.html
- https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html

```
eksctl create iamserviceaccount \
  --cluster=test \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::576223106391:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
```
```
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
```
```
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=test \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller 
```
```
kubectl get deployment -n kube-system aws-load-balancer-controller
```

### Delete EKS cluster
```
eksctl delete cluster --name test --region=ap-south-1
```

## Installing Atlantis

### Create GitHub token and Webhook secret
- Create a Personal Access Token in GitHub with repo scope
- Generate a Webhook secrets(random string of > 24 characters). This is optional but is highly recommended for security.

### Deploying Atlantis
https://www.runatlantis.io/docs/deployment.html

Atlantis can be installed with K8s manifests, Helm Charts and more.

### Create a K8s secret with token and webhook secret
```
echo -n "yourtoken" > token
echo -n "yoursecret" > webhook-secret
kubectl create secret generic atlantis-vcs --from-file=token --from-file=webhook-secret
```
Create AWS credentials secret
```
kubectl create secret generic aws-credentials --from-literal=AWS_ACCESS_KEY_ID=XYZ --from-literal=AWS_SECRET_ACCESS_KEY=ABC 
```
```
kubectl apply -f atlantis_deployment/deployment.yaml
```
```
kubectl get ing
NAME       CLASS   HOSTS   ADDRESS                                                                     
atlantis   alb     *       k8s-default-atlantis-157433424a-1535146993.ap-south-1.elb.amazonaws.com                                                              
```
### Configuring Webhooks
https://www.runatlantis.io/docs/configuring-webhooks.html

- In repository webhook configurations, set Payload URL to http://$URL/events (or https://$URL/events if you're using SSL) where $URL is where Atlantis is hosted(ALB address). 
- Set Content type to application/json
- Set Secret to the Webhook Secret you generated previously
- Select Let me select individual events and check the boxes Pull request reviews, Pushes, Issue comments,Pull requests
- Leave Active checked and click Add webhook

## Configuring Atlantis
using  `atlantis.yaml` file
```
version: 3
automerge: true
autodiscover:
  mode: auto
delete_source_branch_on_merge: true
parallel_plan: true
parallel_apply: true
abort_on_execution_order_fail: true
```
## Links
- https://eksctl.io/usage/iamserviceaccounts/
- https://aws.amazon.com/blogs/containers/amazon-eks-pod-identity-a-new-way-for-applications-on-eks-to-obtain-iam-credentials/
- https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html
- https://www.runatlantis.io/docs/upgrading-atlantis-yaml.html
