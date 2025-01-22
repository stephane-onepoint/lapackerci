#!/bin/bash -eu

set -x

ntfy() {
  curl -fsS -m 10 --retry 3 \
    https://ntfy.sh/${NTFY_TOPIC} \
    "$@"
}

ntfy -d "start packering ..."

if [ -z "${ami_id:-}" ];
then
	# packer build => ami_id
	template=debian-apache-ami.pkr.hcl
	packer validate $template
	packer init $template  # will dl the plugin if needed
	packer build  -var 'region=eu-west-1' $template | tee packer_output.txt
	# last line of packer output contains the id of the newly created AMI
	#   214   eu-west-1: ami-0613c69b9db83ba96
	ami_id=$(tail packer_output.txt | awk '$1=="eu-west-1:"{print $2}')
fi

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
