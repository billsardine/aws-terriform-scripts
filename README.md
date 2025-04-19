# Terraform scripts for AWS 

## Terraform Host

For a host to support 20 environments ensure that your host has at least 30 gigs of disk.  I would recommend no less than 80 gigs to support labs up to 60 pods

The following software must be installed.  This is done automatically by the jump box deploy script ```jumpbox/setup_jumpbox.sh```

- Terraform:  <https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli>
- AWS cli:  <https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>
- Azure cli:  <https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt>
- GCP cli:  <https://cloud.google.com/sdk/docs/install>
