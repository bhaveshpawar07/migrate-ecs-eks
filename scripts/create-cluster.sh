#!/bin/bash

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
if [ -z "$pvtSubnet" ]
then
    echo "Private subnet cannot be empty"
    exit
fi
if [ -z "$pubSubnet" ]
then
    echo "Public subnet cannot be empty"
    exit
fi
if [ -z "$port" ]
then
    echo "port subnet cannot be empty"
    exit
fi
if [ -z "$imageLocation" ]
then
    echo "imageLocation cannot be empty"
    exit
fi

echo "Creating cluster in existing vpc"
eksctl create cluster\
 --name $applicationName-$env\
 --region $region\
 --fargate\
 --vpc-private-subnets=$pvtSubnets\
 --vpc-public-subnets=$pubSubnets

echo "Updating context"
kubectl config use-context arn:aws:eks:$region:$awsAccountId:cluster/$applicationName-$env

aws eks update-kubeconfig --name $applicationName-$env

echo "Creating helm application"
make helm-app applicationName=$applicationName env=$env port=$port imageLocation=$imageLocation

echo "Installing helm application"
make helm-upgrade applicationName=$applicationName env=$env 

echo "Creating IAM account"
make create-iamaccount applicationName=$applicationName env=$env awsAccountId=$awsAccountId

echo "Creating ALB for the service"
make create-alb applicationName=$applicationName env=$env awsAccountId=$awsAccountId region=$region