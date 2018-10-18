#!/bin/sh

cd data

apt update
apt install -y awscli
mv terraform /usr/bin/terraform
chmod +x /usr/bin/terraform
terraform init
terraform apply -auto-approve
sh