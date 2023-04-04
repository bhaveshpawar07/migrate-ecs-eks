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