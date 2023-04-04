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

echo "- Create helm application"
rm -rf helm && ./scripts/create-helm-application.sh --applicationName=$applicationName

echo "- Create ECR repositories for your own application and the amazon load balancer controller"
./scripts/create-ecr.sh --region=$region --applicationName=$applicationName --env=$env --awsAccountId=$awsAccountId

echo "- Create Cluster"
./scripts/create-cluster.sh --region=$region --applicationName=$applicationName --env=$env --awsAccountId=$awsAccountId

echo "-Checking pods status"
pods=($(kubectl get pods -n kube-system --no-headers -o custom-columns=":metadata.name" | grep "aws-load-balancer-controller-*"))
echo $pods
for i in $pods
do
echo "checking $i"
while [[ $(kubectl get pods $i -n kube-system -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod" && sleep 1; done
done

echo "- Run subsequent updates"
./scripts/helm-upgrade.sh --region=$region --applicationName=$applicationName --env=$env --awsAccountId=$awsAccountId