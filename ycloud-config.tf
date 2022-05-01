terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

variable "token" {
  type = string
}

locals {
  image_id = "fd8sc0f4358r8pt128gg"
  zone = "ru-central1-b"
  user_name = "pcadm"
  bucket_name = "tf-bucket-yc"
}
provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = local.zone
}

resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = var.sa_id
  description        = "static access key for object storage"
}

resource "yandex_storage_bucket" "tf-bucket-yc" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = local.bucket_name
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}
resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.129.0.0/24"]
}

resource "yandex_compute_instance" "vm-dev" {
  name        = "vm-dev"
  
  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = local.image_id
      size = 15
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    nat = true
  }

  metadata = {
    user-data = "${file("/home/${local.user_name}/.meta.txt")}"
  }

  provisioner "file" {
    source      = "/home/${local.user_name}/.s3cfg"
    destination = "/home/${local.user_name}/.s3cfg"
    connection {
      type     = "ssh"
      user     = local.user_name
      private_key = "${file("/home/${local.user_name}/.private_yc")}"
      host     = self.network_interface.0.nat_ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt install -y git maven s3cmd",
      "git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git ./app-src",
      "cd app-src/ && mvn package -DskipTest",
      "s3cmd --storage-class COLD put ./target/hello-1.0.war s3://${local.bucket_name}/hello-1.0.war"
          ]
    connection {
      type     = "ssh"
      user     = local.user_name
      private_key = "${file("/home/${local.user_name}/.private_yc")}"
      host     = self.network_interface.0.nat_ip_address
    }
  }
}

resource "yandex_compute_instance" "vm-prod" {
  name        = "vm-prod"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = local.image_id
      size = 15
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    nat = true
  }

  metadata = {
    user-data = "${file("/home/${local.user_name}/.meta.txt")}"
  }

  provisioner "file" {
    source      = "/home/${local.user_name}/.s3cfg"
    destination = "/home/${local.user_name}/.s3cfg"
    connection {
      type     = "ssh"
      user     = local.user_name
      private_key = "${file("/home/${local.user_name}/.private_yc")}"
      host     = self.network_interface.0.nat_ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt install -y s3cmd tomcat9",
      "s3cmd get s3://${local.bucket_name}/hello-1.0.war hello-1.0.war",
      "sudo cp hello-1.0.war /var/lib/tomcat9/webapps/",
      "s3cmd rm s3://${local.bucket_name} --force --recursive"
    ]
    connection {
      type     = "ssh"
      user     = local.user_name
      private_key = "${file("/home/${local.user_name}/.private_yc")}"
      host     = self.network_interface.0.nat_ip_address
    }
  }
  depends_on = [
    yandex_compute_instance.vm-dev,
  ]
}

output "public_ip_address_vm-dev" {
  value = yandex_compute_instance.vm-dev.network_interface.0.nat_ip_address
}

output "public_ip_address_vm-prod" {
  value = yandex_compute_instance.vm-prod.network_interface.0.nat_ip_address
}