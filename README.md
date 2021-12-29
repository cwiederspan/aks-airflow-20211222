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

```

## Install Airflow

```bash

kubectl create namespace airflow

helm repo add apache-airflow https://airflow.apache.org

helm install airflow apache-airflow/airflow --namespace airflow \
  --set postresql.enabled=false \
  --set pgbouncer.enabled=false \
  --set data.metadataConnection.user=psqladmin \
  --set data.metadataConnection.pass=YOUR_PASSWORD_HERE \
  --set data.metadataConnection.protocol=postgresql \
  --set data.metadataConnection.host=cdw-airflowaks-20211224.postgres.database.azure.com \
  --set data.metadataConnection.port=5432 \
  --set data.metadataConnection.db=airflow

helm uninstall airflow -n airflow

```

## Helpers

```bash

kubectl run -it --rm --image=busybox busybox -- sh

kubectl run -it --rm --image=governmentpaas/psql psql

psql -d airflow -h cdw-airflowaks-20211224.postgres.database.azure.com -U psqladmin --password

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