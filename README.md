# ECS to EKS Migration


## Pre-requisites
- helm
- yq
- docker desktop
- aws cli
- kubectl
- eksctl
- helmify

Use this repo to migrate from your existing ECS to EKS.

For a detailed tutorial on how to use this , please go through [this article.]()

## Examples

Use the command below to setup EKS from your existing ECS , you will need to update the vpc and image before using this command.

``` ./scripts/setup-eks.sh --applicationName=eks-fargate-starter --env=qa --awsAccountId=XYZ --region=ap-south-1 ```
