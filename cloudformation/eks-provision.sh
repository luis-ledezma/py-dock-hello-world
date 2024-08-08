eksctl create cluster --name py-dock-hello-world-cluster --version 1.28 --fargate

eksctl utils associate-iam-oidc-provider --cluster py-dock-hello-world-cluster --approve

eksctl create iamserviceaccount --cluster=py-dock-hello-world-cluster --namespace=kube-system --name=aws-load-balancer-controller --attach-policy-arn=arn:aws:iam::025066248951:policy/AWSLoadBalancerControllerIAMPolicy --override-existing-serviceaccounts --approve

eksctl get iamserviceaccount --cluster py-dock-hello-world-cluster --name aws-load-balancer-controller --namespace kube-system

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
--set clusterName=py-dock-hello-world-cluster \
--set serviceAccount.create=false \
--set region=us-east-2 \
--set vpcId=vpc-04f1cdb654008f379 \
--set serviceAccount.name=aws-load-balancer-controller \
-n kube-system
