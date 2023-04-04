
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
if [ -z "$region" ]
then
    echo "region cannot be empty"
    exit
fi

helm repo add eks https://aws.github.io/eks-charts
helm repo update

vpcId=$(aws eks describe-cluster --name $applicationName-$env --query 'cluster.resourcesVpcConfig.vpcId' | grep "vpc-.*")
echo $vpcId

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$applicationName-$env \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller-$env \
  --set vpcId="${vpcId//\"/}" \
  --set region=$region

kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
