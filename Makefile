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

setup_port_forwarding:
	$(info [+] To access the Airflow UI, open a new terminal and execute the following command)
	kubectl port-forward svc/airflow-webserver 8080:8080 -n airflow --context kind-airflow-cluster

#note: this is only done if you'r configuring a new custom airflow-cluster
configure_airflow_on_K8s:
	$(info [+] Configure Airflow on K8s for your needs (e.g., set the executor, add any desired Airflow vars/connections))
	helm show values apache-airflow/airflow > values.yaml
	# Add any vars or connections that you want to export each time your Airflow instance gets deployed, by defining a ConfigMap
	# TODO#
	# Add the ConfigMap to the cluster
	kubectl apply -f variables.yaml
	# Deploy Airflow on K8s again
	helm ls -n airflow
	helm upgrade --install airflow apache-airflow/airflow -n airflow -f values.yaml --debug
	helm ls -n airflow

install_airflow_k8s_deps:
	# create custom docker image
	docker build -t airflow-custom:1.0.0 .
	kind load docker-image airflow-custom:1.0.0 --name airflow-cluster
	# upgrade the helm chart
	helm upgrade --install airflow apache-airflow/airflow -n airflow -f values.yaml --debug
	helm ls -n airflow

deploy_dags_on_k8s:


check_airflow_providers:
	kubectl exec <webserver_pod_id> -n airflow -- airflow providers lis

clean:
	$(info [+] Remove any redundant files, e.g. downloads)
	@helm repo remove apache-airflow
	@kubectl delete namespace airflow
	@kind delete cluster --name airflow-cluster
.PHONY: clean
