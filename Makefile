#
# Variables
#
CLUSTER=k3s-cluster
HELM_REPO=bitnami


setup-k8s:
	@echo "\n>>> Creating local K8S cluster..."
	-k3d cluster create ${CLUSTER} --agents 2
	@echo "\n"
	@sleep 10
	kubectl get nodes

setup-python:
	@echo "\n>>> Setting up the python virtual env - using pipenv..."
	-pipenv --python 3.8
	pipenv shell
		
setup-psql:
	@echo "\n>>> Installing PostgreSQL..."
	-helm repo add ${HELM_REPO} https://charts.bitnami.com/bitnami
	-helm install postgresql ${HELM_REPO}/postgresql
	@echo "\n"
	kubectl get svc postgresql

psql-password:
	@kubectl get secret --namespace default postgresql -o jsonpath="{.data.postgres-password}" | base64 --decode > postgresql.txt
	@echo "\n>>> PostgreSQL password: " ; cat ./postgresql.txt
	@echo

psql-setup-data:
	./psql-populate.sh db/1_create_tables.sql
	./psql-populate.sh db/2_seed_users.sql
	./psql-populate.sh db/3_seed_tokens.sql

setup: setup-k8s setup-psql psql-password psql-setup-data setup-python

install:
	@echo "\n>>> Installing python dependencies..."
	pipenv install -r analytics/requirements.txt
	# To connect via port-forwarding
	kubectl port-forward --namespace default svc/postgresql 5432:5432 &

clean-k8s:
	@echo "\n>>> Deleting the K3S cluster: ${CLUSTER}..."
	-k3d cluster delete ${CLUSTER}
	k3d cluster list

clean-python:
	@echo "\n>>> Deleting the python dependencies...\n"
	-pipenv uninstall --all --clear --quiet

clean: clean-k8s clean-python



