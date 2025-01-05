#!/bin/bash -eu

set -x

ntfy() {
  curl -fsS -m 10 --retry 3 \
    https://ntfy.sh/${NTFY_TOPIC} \
    "$@"
}

ntfy -d "start packering ..."

# packer build => ami_id
packer plugins install github.com/hashicorp/amazon
template=debian-apache-ami.pkr.hcl
packer validate $template
packer init $template
packer build  -var 'region=eu-west-1' $template | tee packer_output.txt
ami_id=$(< packer_output.txt tail | awk '$1=="eu-west-1:"{print $2}')

ntfy -d "packering done ${ami_id}, start terraforming ..."

# terraform apply, var ami_id => IP
terraform init
terraform apply -auto-approve -var "ami_id=${ami_id}"
public_ip=$(terraform output -json | jq -r '.public_ip.value')

ntfy -d "terraforming done, testing..."

# test `curl http://ip/ | grep foo`
curl -fsS -m 30 --retry 12 --retry-all-errors -o output.txt "http://${public_ip}/"
 
# terraform destroy
terraform output > tfoutput.txt

ntfy -F 'curl=@output.txt' -F 'tfoutput=@tfoutput.txt' -F 'message=please destroy'
