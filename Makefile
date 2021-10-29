SHELL = /bin/sh

installations: deps install clean

deps:
	$(info [+] Download the relevant dependencies)
	pip install docker
	pip install docker-compose
	brew install kind
	brew install helm
	brew install kubectl
.PHONY: deps

install:
	$(info [+] Install the relevant dependencies)
	# create the k8s cluster - can take approx 3 mins
	@kind create cluster --name airflow-cluster --config kind-cluster.yaml
	# Create k8s namespace
	@kubectl create namespace airflow
	# download the airflow helm chart
	@helm repo add apache-airflow https://airflow.apache.org
	@helm repo update
	# deploy airflow on k8s using k8s!
	@helm install airflow apache-airflow/airflow --namespace airflow --debug --wait=false
.PHONY: install

port_forwarding:
	kubectl port-forward svc/airflow-webserver 8080:8080 -n airflow --context kind-airflow-cluster

clean:
	$(info [+] Remove any redundant files, e.g. downloads)
	@helm repo remove apache-airflow
	@kubectl delete namespace airflow
	@kind delete cluster --name airflow-cluster
.PHONY: clean
