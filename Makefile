create-ecr:
	./scripts/create-ecr.sh 

create-cluster:
	./scripts/create-cluster.sh

helm-app: 
	rm -rf helm && ./scripts/create-helm-application.sh

helm-upgrade: 
	./scripts/helm-upgrade.sh

create-iamaccount:
	./scripts/create-iamaccount.sh

create-alb:
	./scripts/create-alb.sh