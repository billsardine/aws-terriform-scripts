#! /bin/bash

#Todo
# User provisoning


# installing Necessary Packages
sudo apt-get update && sudo apt-get install -y  unzip pwgen jq mdcat

#install azure cli
echo "Installing Azure cli"
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

#install AWS cli
echo "Installing AWS cli"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sudo rm -r aws
sudo rm awscliv2.zip

#install GCP cli
echo "Installing AWS cli"
echo "Importing GCP public key"
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "gcloud CLI distribution URI as a package source"
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
echo "update and install gcloud cli"
sudo apt-get update && sudo apt-get install -y google-cloud-cli

#Install Terraform
echo "Installing Terraform"
echo "Importing Hashicorp GPG key"
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "Adding Hashicorp repo to the system"
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform