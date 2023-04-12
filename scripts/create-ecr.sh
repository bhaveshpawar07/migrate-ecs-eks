#!/bin/bash

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

if [ -z "$region" ]
then
    echo "region cannot be empty"
    exit
fi

if [ -z "$awsAccountId" ]
then
    echo "awsAccountId cannot be empty"
    exit
fi

aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $awsAccountId.dkr.ecr.$region.amazonaws.com

aws ecr create-repository --repository-name=$applicationName-$env | grep "repository"

aws ecr create-repository --repository-name=aws-load-balancer-controller | grep "repository"

docker pull 602401143452.dkr.ecr.ap-south-1.amazonaws.com/amazon/aws-load-balancer-controller:v2.4.4

docker tag 602401143452.dkr.ecr.$region.amazonaws.com/amazon/aws-load-balancer-controller:v2.4.4 $awsAccountId.dkr.ecr.$region.amazonaws.com/aws-load-balancer-controller:v2.4.4

aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $awsAccountId.dkr.ecr.$region.amazonaws.com

docker push $awsAccountId.dkr.ecr.$region.amazonaws.com/aws-load-balancer-controller:v2.4.4

