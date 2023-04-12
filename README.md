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

## Multienv code , copy this and change the env name

For example below code creates a qa environment
Replace qa to your env and paste the code in ```create-helm-application.sh```
```
cp helm/$applicationName/values.$env.yaml helm/$applicationName/values.qa.yaml 


#name change -> qa
yq e '.fullnameOverride = strenv(applicationName) + "-qa"'  -i helm/$applicationName/values.qa.yaml
yq e '.nameOverride = strenv(applicationName) + "-qa"'  -i helm/$applicationName/values.qa.yaml

#host -> qa
yq e '.ingress.hosts[0].paths[0].backend.service.name = env(applicationName) + "-qa"'  -i helm/$applicationName/values.qa.yaml

#defaultBackend -> qa
yq e '.ingress.defaultBackendServiceName = env(applicationName) + "-qa"'  -i helm/$applicationName/values.qa.yaml

echo "
env:
  configmap:
    data:
      ENVIRONMENT_NAME: qa" >> helm/$applicationName/values.qa.yaml
```
