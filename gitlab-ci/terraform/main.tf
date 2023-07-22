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

resource "yandex_compute_instance" "docker" {
  name = "docker"

  resources {
    cores = 4
    memory = 8
  }

  boot_disk{
    initialize_params {
      image_id = var.image_id
      size = 25
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
    host = yandex_compute_instance.docker.network_interface.0.nat_ip_address
    user = var.user
    agent = false
    private_key = file(var.private_key_path)
  }
}
