# Airflow on Azure Kubernetes

A repository with notes and code for deploying Apache Airflow to Azure Kubernetes.


### Setup Shell Variables

These variables will be used throughout the demo.

```bash

# This will be used as the name of the RG and cluster
NAME=cdw-kubernetes-2021224

# The AKS gitops add-on is only available in a few locations while in preview
LOCATION=eastus2

# This is the AAD Tenant ID
TENANT_ID=<your-tenant-id>

# This is the Object ID of the AAD Group that will be the Admin owners of the cluster
GROUP_ID=<your-group-id>

# These are for the PostgreSQL database
DB_ADMIN=dbadmin
DB_PWD=<your-password>

```

## Azure Resource Setup

### Create an Azure Resource Group

```bash

az group create -n $NAME -l $LOCATION

```

### Create a PostgreSQL Server
```bash

# Create the PostgreSQL Server
az postgres server create \
-g $NAME \
-n $NAME \
-l $LOCATION \
--admin-user $DB_ADMIN \
--admin-password $DB_PWD \
--version 11 \
--minimal-tls-version TLS1_2 \
--public-network-access 0.0.0.0 \
--sku-name B_Gen5_2


--ssl-enforcement Disabled \


# Create the PostgreSQL database
az postgres db create -g $NAME -s $NAME -n airflow

```

### Create an Azure Kubernetes Cluster

```bash

# Create cluster
az aks create \
--resource-group $NAME \
--name $NAME \
--location $LOCATION \
--kubernetes-version 1.22.4 \
--node-count 1 \
--network-plugin kubenet \
--generate-ssh-keys \
--enable-managed-identity \
--enable-aad \
--enable-azure-rbac \
--aad-tenant-id $TENANT_ID \
--aad-admin-group-object-ids $GROUP_ID \
--auto-upgrade-channel stable \
--enable-cluster-autoscaler \
--min-count 1 \
--max-count 3 \
--node-vm-size Standard_D4s_v3 \
--zones {1,2,3} \
--enable-addons monitoring

# Get credentials and login
az aks get-credentials -n $NAME -g $NAME --overwrite

```

## Install Airflow

```bash

kubectl create namespace airflow
helm repo add apache-airflow https://airflow.apache.org
helm install airflow apache-airflow/airflow --namespace airflow

```