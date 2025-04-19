# Scripts to provision software on the jump box

This script installs the software that is necessary to deploy the pods. This installs:

- Azure cli
- AWS cli
- GCP cli
- terraform

```cli
./setup_jumpbox.sh
```

you will need to authenticate Azure cli and GCP CLI

Azure login

```cli
az login
```

Switch to correct subscription for the workshop

```cli
az account set --subscription 'name'
```

GCP login

```cli
gcloud auth application-default login
```
