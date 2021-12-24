# Deploy Kubernetes

## Setup

Rename the `secrets-sample.tfvars` file to `secrets.tfvars` and update the values in that file.

## Terraform Init

```bash

cd terraform

terraform init --backend-config backend-secrets.tfvars

```

## Terraform Apply

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
