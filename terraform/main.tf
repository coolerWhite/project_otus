terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token = var.token
  cloud_id = var.cloud_id
  folder_id = var.folder_id
  zone = var.zone
}

#resource "yandex_compute_disk" "kuber-disk" {
#  count = 2
#  name = "kuber-disk-${count.index+1}"
#  type = "network-ssd"
#  zone = var.zone
#  image_id = var.image_id
#  size = 40
#}

resource "yandex_compute_instance" "kuber" {
  count = 3
  name = "kuber-${count.index+1}"
  #hostname = "kuberVM-${count.index+1}"
  #depends_on = [ yandex_compute_disk.kuber-disk ]

  resources {
    cores = 4
    memory = 4
  }

  boot_disk {
    initialize_params {
        name = "kuber-disk${count.index+1}"
        type = "network-ssd"
        image_id = var.image_id
        size = 40
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    ipv4 = true
    nat = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

  connection {
    type = "ssh"
    host = self.network_interface.0.nat_ip_address
    user = var.user
    agent = false
    private_key = file(var.public_key_path)
  }
}
