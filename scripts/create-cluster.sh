#!/bin/bash
for ARGUMENT in "$@"
do
   K=$(echo $ARGUMENT | cut -f1 -d=)
   KEY=${K:2}
   KEY_LENGTH=${#KEY}
   VALUE="${ARGUMENT:$KEY_LENGTH+3}"

   export "$KEY"="$VALUE"
done

if [ -z "$region" ]
then
    echo "region cannot be empty"
    exit
fi
if [ -z "$applicationName" ]
then
    echo "applicationName cannot be empty"
    exit
fi

if [ -z "$env" ]
then
    echo "env cannot be empty"
    exit
fi

if [ -z "$awsAccountId" ]
then
    echo "awsAccountId cannot be empty"
    exit
fi

echo "Creating cluster in existing vpc"
eksctl create cluster\
 --name $applicationName-$env\
 --region $region\
 --fargate\
 --vpc-private-subnets=enter_your_subnet\
 --vpc-public-subnets=enter_your_subnet

kubectl config use-context arn:aws:eks:$region:$awsAccountId:cluster/$applicationName-$env

aws eks update-kubeconfig --name $applicationName-$envs 

./scripts/helm-upgrade.sh region=$region applicationName=$applicationName env=$env awsAccountId=$awsAccountId

eksctl utils associate-iam-oidc-provider --cluster $applicationName-$env --approve

oidc_id=$(aws eks describe-cluster --name $applicationName-$env --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)

echo "oidc_id:"$oidc_id

curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name $applicationName-AWSLBControllerIAMPolicy-$env \
    --policy-document file://iam_policy.json | grep "resource"

eksctl create iamserviceaccount \
  --cluster=$applicationName-$env \
  --namespace=kube-system \
  --name=aws-load-balancer-controller-$env \
  --role-name "$applicationName-AmazonEKSLBControllerRole-$env" \
  --attach-policy-arn=arn:aws:iam::$awsAccountId:policy/$applicationName-AWSLBControllerIAMPolicy-$env \
  --approve --override-existing-serviceaccounts


helm repo add eks https://aws.github.io/eks-charts

helm repo update


vpcId=$(aws eks describe-cluster --name $applicationName-$env --query 'cluster.resourcesVpcConfig.vpcId' | grep "vpc-.*")

echo $vpcId
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$applicationName-$env \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller-$env \
  --set image.repository="$awsAccountId.dkr.ecr.$region.amazonaws.com/aws-load-balancer-controller" \
  --set image.tag="v2.4.4" \
  --set vpcId="${vpcId//\"/}" \
  --set region=$region

kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
