Demo of terraform usage with yandex cloud
=========

Short info
------------

Tested on Ubuntu 20.04

Additional packages are required (including terraform):

```
apt update && apt install -y 
```

To prepare configuration (inside the directory with *.tf):
```
terraform init
terraform plan
terraform apply
```

To delete all the created instances:

```
terraform destroy
```

Requirements
------------

Create additional virtual directory in Yandex Cloud. 
There is directory with name tf-dir for current example.
