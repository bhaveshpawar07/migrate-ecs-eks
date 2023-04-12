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

helm upgrade --install $applicationName-$env ./helm/$applicationName --values=./helm/$applicationName/values.$env.yaml --debug --wait --force