# NOTE: Based on https://success.docker.com/article/certified-infrastructures-aws

# Install Terraform and Ansible

# Download templates and scripts from https://success.docker.com/assets/certified-infrastructures-aws/.%2Faws%2Fref-arch%2Fcertified-infrastructures-aws%2F.%2Ffiles%2Faws-v1.0.0.tar.gz

# Uncompress and move the directory `aws-v1.0.0` to `cluster/`

cd cluster/aws-v1.0.0/

# Create terraform.tfvars file. Use one of the files from `examples` as the starting point.

# Create a key in AWS named `devops23`

# Download `devops23.pem` to the current directory

echo '##Manager details
linux_manager_instance_type = "m4.xlarge"

##Linux worker details
linux_worker_instance_type = "t2.large"

##Windows worker details
windows_worker_instance_type = "i3.xlarge"

##DTR Linux worker details
dtr_instance_type = "m4.xlarge"' \
    >instances.auto.tfvars

export AWS_ACCESS_KEY_ID=[...]

export AWS_SECRET_ACCESS_KEY=[...]

export AWS_DEFAULT_REGION=us-east-2

terraform init

terraform plan

terraform apply -auto-approve

# Create Route53 entries using the domains from the Terraform output

# Change `windows_enabled: yes` to `windows_enabled: no` in the `group_vars/windows` file

open "https://store.docker.com/my-content"

# Download the licence key (`docker_subscription.lic`) and copy it to the current directory

# Uncomment `docker_ucp_license_path` line in `group_vars/all`

# Uncomment `docker_ucp_admin_password` line in `group_vars/all` and replace `<placeholder>`

# Uncomment `docker_ucp_lb` line in `group_vars/all` and replace `<placeholder>`

# Uncomment `docker_dtr_lb` line in `group_vars/all` and replace `<placeholder>`

# Uncomment `docker_ee_subscriptions_ubuntu` line in `group_vars/all` and replace `<placeholder>`

mkdir -p ssl_cert

openssl genrsa -out ssl_cert/key.pem 2048

SUBJ="
C=ES
ST=
O=
localityName=
commonName=*.us-east-2.elb.amazonaws.com
organizationalUnitName=
emailAddress=
"

openssl req -new \
    -subj "$(echo -n "$SUBJ" | tr "\n" "/")" \
    -key ssl_cert/key.pem \
    -out ssl_cert/ca.pem \
    -passin pass:

openssl x509 -req -days 365 \
    -in ssl_cert/ca.pem \
    -signkey ssl_cert/key.pem \
    -out ssl_cert/cert.pem

mv ssl_cert/ca.pem ssl_cert/ca.pem.orig

cp ssl_cert/cert.pem ssl_cert/ca.pem

ansible-playbook \
    --private-key=devops23.pem \
    -i inventory install.yml

# Fails with: Failed to import docker-py - No module named requests.exceptions. Try `pip install docker-py`

# Issues:
#   https://github.com/ansible/ansible/issues/20492
#   https://github.com/ansible/ansible-modules-core/issues/4246