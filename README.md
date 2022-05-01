Demo of terraform usage with yandex cloud
=========

Short info
------------

Tested on Ubuntu 20.04

Terraform scenarion creates instances (Ubuntu 20.04 LTS) on YC:

1) vm-dev with maven to package war file (boxfuse app)
2) S3 bucket to copy war file
3) vm-prod to download war file from bucket and publish with tomcat

After the deployment you will get public ip addresses of VM instances.
Follow http://vm-prod-public-ip:8080/hello-1.0

Preparation:
------------



Additional packages are required (including terraform):

```
apt update && apt install -y s3cmd git
```
Terraform installation:
https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started

YC CLI install:
```
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
```

YC init to initialize your profile with token:
```
yc init
```
Follow YC manual: https://cloud.yandex.ru/docs/cli/quickstart

Clone repository:

```
git clone https://github.com/sk0ld/terraform-ycloud-demo.git
cd terraform-ycloud-demo
```

To create file with your IDs (inside project directory):
```
touch wp.auto.tfvars
```
Example of content wp.auto.tfvars:
```
folder_id = "your_folder_id"
sa_id = "your_sa_id"
cloud_id = "your_cloud_id"
token = "your_token"
```

Settings for terraform:
```
touch ~/.terraformrc
```
Content of .terraformrc:
```
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```

To prepare configuration (inside the directory with *.tf):
```
terraform init
terraform plan
terraform apply
```

Apply without confirmation:
```
terraform apply --auto-approve
```

To delete all the created instances:

```
terraform destroy
```

To delete all without confirmation:
```
terraform destroy --auto-approve
```

Requirements
------------

Create additional virtual directory in Yandex Cloud. 
There is directory with name tf-dir for current example.
Delete all networks inside directory or contact YC support to extend quantity of networks.

Info for S3 Bucket
------------------

Static key for service account:
https://github.com/yandex-cloud/docs/blob/master/en/iam/operations/sa/create-access-key.md

Configure service account to use S3 storage:
https://cloud.yandex.com/en/docs/storage/tools/s3cmd

Copy S3 config to your user directory:
```
cp ~/.s3cfg /home/your_user/.s3cfg
```

ssh keys and additial configs:
-----------------------------

Generate and put private and public ssh keys for your VMs here:
```
/home/your_user/.private_yc
```

To create user metadata (for example for user pcadm):
```
touch /home/your_user/meta.txt
```

Content of meta.txt :
```
#cloud-config
users:
  - name: pcadm
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - ssh-rsa AAAAB3Nza......OjbSMRX user@example.com
      - ssh-rsa AAAAB3Nza......Pu00jRN user@desktop
```

