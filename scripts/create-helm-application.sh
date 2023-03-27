#!/bin/bash

for ARGUMENT in "$@"
do
   K=$(echo $ARGUMENT | cut -f1 -d=)
   KEY=${K:2}
   KEY_LENGTH=${#KEY}
   VALUE="${ARGUMENT:$KEY_LENGTH+3}"

   export "$KEY"="$VALUE"
done


if [ -z "$applicationName" ]
then
    echo "applicationName cannot be empty"
    exit
fi
if [ -z "$env" ]
then
    echo "envname cannot be empty"
    exit
fi

mkdir helm
helm create helm/$applicationName
mv helm/$applicationName/values.yaml helm/$applicationName/values.$env.yaml 

#we set the container port to 9000 for our application
sed '38 c\
              containerPort: 9000
' helm/$applicationName/templates/deployment.yaml > helm/$applicationName/templates/deployment-temp.yaml
cat helm/$applicationName/templates/deployment-temp.yaml > helm/$applicationName/templates/deployment.yaml
rm helm/$applicationName/templates/deployment-temp.yaml

#we will set the service as nodeport and port to 9000
#here you can set the image repository now or later once the file is created
yq e '.image.repository = ""'  -i helm/$applicationName/values.$env.yaml
yq e '.image.pullPolicy = "Always"'  -i helm/$applicationName/values.$env.yaml
yq e '.service.type = "NodePort", .service.targetPort = 9000'  -i helm/$applicationName/values.$env.yaml

#we will change the name of the kubernetes resources being created according
#to our app name and env
yq e '.fullnameOverride = strenv(applicationName) + "-"+strenv(env)'  -i helm/$applicationName/values.$env.yaml
yq e '.nameOverride = strenv(applicationName) + "-"+strenv(env)'  -i helm/$applicationName/values.$env.yaml

#we will create an ingress resource in order to allow traffic to be routed to our service 
yq e '.ingress.enabled = true'  -i helm/$applicationName/values.$env.yaml

#we set our application service as the default backend for ingress
yq e '.ingress.defaultBackendServiceName = env(applicationName) + "-"+strenv(env)'  -i helm/$applicationName/values.$env.yaml

#we will setup host details for the ingress service
#we will remove the existing host entries
yq e -i 'del(.ingress.hosts[0].host)' helm/$applicationName/values.$env.yaml 
#we will set the name of our backend service 
yq e '.ingress.hosts[0].paths[0].backend.service.name = env(applicationName) + "-"+strenv(env)'  -i helm/$applicationName/values.$env.yaml
#we will set the port of our backend service to 80 where our application is running
yq e '.ingress.hosts[0].paths[0].backend.service.port.number = 80'  -i helm/$applicationName/values.$env.yaml
#we will set the route path to / for ingress to route trafic to root path
yq e '.ingress.hosts[0].paths[0].path = "/"'  -i helm/$applicationName/values.$env.yaml
#we will set pathType to ImplementationSpecific to determine the appropriate path type for the backend Service based on annotations
yq e '.ingress.hosts[0].paths[0].pathType = "ImplementationSpecific"'  -i helm/$applicationName/values.$env.yaml


#we will now set annotations to for the services 
#this indicates the type of ingress class is application load balancer
yq e '.ingress.annotations["kubernetes.io/ingress.class"] = "alb"'  -i helm/$applicationName/values.$env.yaml
#this indicates the alb is an internet facing
yq e '.ingress.annotations["alb.ingress.kubernetes.io/scheme"] = "internet-facing"'  -i helm/$applicationName/values.$env.yaml
#this indicates the target type for the alb target , which is set to ip
yq e '.ingress.annotations["alb.ingress.kubernetes.io/target-type"] = "ip"'  -i helm/$applicationName/values.$env.yaml
#this indicates that if prometheus should scrape metrics from the Pod , its set to true
yq e '.podAnnotations["prometheus.io/scrape"] = "true"'  -i helm/$applicationName/values.$env.yaml
#this indicates port on which pod is serving 
yq e '.podAnnotations["prometheus.io/port"] = "9000"'  -i helm/$applicationName/values.$env.yaml
#this indicates alb to listen to port 80 for incoming traffic
yq e '.ingress.annotations["alb.ingress.kubernetes.io/listen-ports"] = "[{\"HTTP\":80}]"'  -i helm/$applicationName/values.$env.yaml



cp helm/$applicationName/values.$env.yaml helm/$applicationName/values.qa.yaml 
cp helm/$applicationName/values.$env.yaml helm/$applicationName/values.local.yaml 

#name change -> qa
yq e '.fullnameOverride = strenv(applicationName) + "-qa"'  -i helm/$applicationName/values.qa.yaml
yq e '.nameOverride = strenv(applicationName) + "-qa"'  -i helm/$applicationName/values.qa.yaml

#host -> qa
yq e '.ingress.hosts[0].paths[0].backend.service.name = env(applicationName) + "-qa"'  -i helm/$applicationName/values.qa.yaml

#defaultBackend -> qa
yq e '.ingress.defaultBackendServiceName = env(applicationName) + "-qa"'  -i helm/$applicationName/values.qa.yaml

#name change -> local
yq e '.fullnameOverride = strenv(applicationName) + "-local"'  -i helm/$applicationName/values.local.yaml
yq e '.nameOverride = strenv(applicationName) + "-local"'  -i helm/$applicationName/values.local.yaml

#host -> local
yq e '.ingress.hosts[0].paths[0].backend.service.name = env(applicationName) + "-local"'  -i helm/$applicationName/values.local.yaml

#defaultBackend -> local
yq e '.ingress.defaultBackendServiceName = env(applicationName) + "-local"'  -i helm/$applicationName/values.local.yaml
#defaultBackend -> local
yq e '.ingress.annotations = {}'  -i helm/$applicationName/values.local.yaml


#pullPolicy will be IfNotPresent to fulfil local builds
yq e '.image.pullPolicy = "IfNotPresent"'  -i helm/$applicationName/values.local.yaml


echo "
env:
  configmap:
    data:
      ENVIRONMENT_NAME: develop" >> helm/$applicationName/values.$env.yaml

echo "
env:
  configmap:
    data:
      ENVIRONMENT_NAME: qa" >> helm/$applicationName/values.qa.yaml


#deployment


