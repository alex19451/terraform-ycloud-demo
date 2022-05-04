terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token     = "token"
  cloud_id  = "b1gsgarlchl6avjsn2vj"
  folder_id = "b1gvq38letn60dbl2ed1"
  zone      = "ru-central1-a"
}

variable "user" {
   description = "registry user docker hub"
   type        = string
   default     = "12431551"
}
variable "password" {
   description = "registry password docker hub"
   type        = string
   default     = "password"
}
variable "vers" {
   description = "registry password docker hub"
   type        = string
   default     = "2.0"
}

resource "yandex_compute_instance" "build-node" {
  name = "build-node"

  resources {
    cores  = 2
    memory = 2
  }


  boot_disk {
    initialize_params {
      image_id = "fd8sc0f4358r8pt128gg"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    user-data = "${file("/home/alex1945/terraform1/meta.txt")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt install -y docker.io git",
      "git clone https://github.com/alex19451/devoptest.git ./app",
      "cd app/docker-compose/mvnbuild && sudo docker build -t myimagenew:${var.vers} .",
      "sudo docker login -u ${var.user} -p ${var.password}",
      "sudo docker tag myimagenew:${var.vers} ${var.user}/myimagenew:${var.vers} && sudo docker push ${var.user}/myimagenew:${var.vers}"
          ]
    connection {
      type     = "ssh"
      user     =  "alex1945"
      private_key = "${file("/root/.ssh/yandex_c")}"
      host     = self.network_interface.0.nat_ip_address
    }
  }
}
resource "yandex_compute_instance" "prod-node" {
  name = "prod-node"

  resources {
    cores  = 4
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8sc0f4358r8pt128gg"
      type = "network-ssd"
      size = 15
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    user-data = "${file("/home/alex1945/terraform1/meta.txt")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt install -y docker.io",
      "sudo docker run -p 8088:8080 ${var.user}/myimagenew:${var.vers}",
          ]
    connection {
      type     = "ssh"
      user     =  "alex1945"
      private_key = "${file("/root/.ssh/yandex_c")}"
      host     = self.network_interface.0.nat_ip_address
    }
   }
  depends_on = [
    yandex_compute_instance.build-node,
  ]
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}


resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.build-node.network_interface.0.ip_address
}

output "internal_ip_address_vm_2" {
  value = yandex_compute_instance.prod-node.network_interface.0.ip_address
}


output "external_ip_address_vm_1" {
  value = yandex_compute_instance.build-node.network_interface.0.nat_ip_address
}

output "external_ip_address_vm_2" {
  value = yandex_compute_instance.prod-node.network_interface.0.nat_ip_address
}
