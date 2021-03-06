# Airflow on Azure Kubernetes

A repository with notes and code for deploying Apache Airflow to Azure Kubernetes.

## Deploy the Azure Resources using Terraform

### Setup

Rename the `secrets-sample.tfvars` file to `secrets.tfvars` and update the values in that file.

### Terraform Init

```bash

cd terraform

terraform init --backend-config backend-secrets.tfvars

```

### Terraform Apply

```bash

# Run the plan to see the changes
terraform plan \
-var 'base_name=cdw-airflowaks-20211224' \
-var 'location=eastus2' \
-var 'node_count=2' \
--var-file=secrets.tfvars


# Apply the script with the specified variable values
terraform apply \
-var 'base_name=cdw-airflowaks-20211224' \
-var 'location=eastus2' \
-var 'node_count=2' \
--var-file=secrets.tfvars

# Connect to the AKS cluster
az aks get-credentials --resource-group cdw-airflowaks-20211224 --name cdw-airflowaks-20211224 --overwrite-existing 

```

## Install Airflow

```bash

kubectl create namespace airflow

helm repo add apache-airflow https://airflow.apache.org

helm install airflow apache-airflow/airflow --namespace airflow \
  --set webserverSecretKey=$(hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/urandom) \
  --set config.webserver.expose_config=true \
  --set postgresql.enabled=false \
  --set pgbouncer.enabled=false \
  --set redis.enabled=false \
  --set data.metadataSecretName=airflow-connection-metadata \
  --set data.resultBackendSecretName=airflow-connection-results \
  --set data.brokerUrlSecretName=airflow-connection-redis \
  --set dags.gitSync.enabled=true \
  --set dags.gitSync.repo=https://github.com/cwiederspan/airflow-sample-dags.git \
  --set dags.gitSync.branch=main \
  --set dags.gitSync.subPath=dags

helm uninstall airflow -n airflow

```

## Helpers

```bash

kubectl port-forward svc/airflow-webserver 8080:8080 --namespace airflow

kubectl run -it --rm --image=busybox busybox -- sh

kubectl run -it --rm --image=governmentpaas/psql psql

psql -d airflow_metadata -h cdw-airflowaks-20211224.postgres.database.azure.com -U psqladmin --password
psql -d postgres -h cdw-airflowaks-20211224.postgres.database.azure.com -U psqladmin --password

# List all databases
\l

# List all tables
\dt

SELECT *
FROM pg_stat_activity
WHERE datname = 'airflow';

SELECT pg_terminate_backend (pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'airflow';

```