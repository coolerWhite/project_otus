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

resource "yandex_vpc_network" "k8s_net" {
  name = "k8s_net"
}

resource "yandex_vpc_subnet" "k8s_net-a" {
  v4_cidr_blocks = ["10.244.0.0/16"]
  zone = var.zone
  network_id = yandex_vpc_network.k8s_net.id
}

#resource "yandex_dns_zone" "k8s_dns" {
#  zone = "k8s-dns.otus."
#  name = "k8s-dns"
#  public = false
#  private_networks = [yandex_vpc_network.k8s_net.id]
#}

#resource "yandex_dns_recordset" "k8s_rs1" {
#  zone_id = yandex_dns_zone.k8s_dns.id
#  name = "k8s-otus"
#  type = "A"
#}

resource "yandex_vpc_security_group" "group1" {
  name        = "k8s_security-group"
  network_id  = "${yandex_vpc_network.k8s_net.id}"

  labels = {
    my-label = "k8s_security-group"
  }

  ingress {
    protocol       = "TCP"
    description       = "Правило разрешает проверки доступности с диапазона адресов балансировщика нагрузки."
    predefined_target = "loadbalancer_healthchecks"
    from_port = 0
    to_port           = 65535
  }

  ingress {
    protocol = "TCP"
     description = "Правило разрешает входящий трафик из интернета на диапазон портов NodePort."
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port = 30000
    to_port = 32767
  }

  ingress {
    protocol = "TCP"
    description = "Правило разрешает подключение к API Kubernetes через порт 6443 из указанной сети."
    v4_cidr_blocks = ["0.0.0.0/0"]
    port = 6443
  }

  ingress {
    protocol       = "TCP"
    description = "Правило разрешает подключение к API Kubernetes через порт 443 из указанной сети."
    v4_cidr_blocks = ["0.0.0.0/0"]
    port = 443
  }

  ingress {
    protocol = "ANY"
    description = "Правило разрешает взаимодействие мастер-узел и узел-узел внутри группы безопасности."
    predefined_target = "self_security_group"
    from_port = 0
    to_port = 65535
  }

  ingress {
    protocol = "ANY"
    description = "Правило разрешает взаимодействие под-под и сервис-сервис."
    v4_cidr_blocks = concat(yandex_vpc_subnet.k8s_net-a.v4_cidr_blocks)
    from_port = 0
    to_port = 65535
  }

  ingress {
    protocol = "ICMP"
    description = "Правило разрешает отладочные ICMP-пакеты из внутренних подсетей."
    v4_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  egress {
    protocol = "ANY"
    description = "Правило разрешает весь исходящий трафик. Узлы могут связаться с Yandex Container Registry, Yandex Object Storage, Docker Hub и т. д."
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 65535

  }
}

resource "yandex_kms_symmetric_key" "k8s_kms" {
  name = "k8s_kms"
  description = "сервис для создания ключей шифрования в Yandex Cloud и управления ими."
  default_algorithm = "AES_128"
  rotation_period = "8760h"
}

resource "yandex_kubernetes_cluster" "k8s_cluster" {
  name        = "k8s"
  network_id = yandex_vpc_network.k8s_net.id

  master {
    version = "1.23"
    zonal {
      zone      = yandex_vpc_subnet.k8s_net-a.zone
      subnet_id = yandex_vpc_subnet.k8s_net-a.id
    }

    public_ip = true

    security_group_ids = ["${yandex_vpc_security_group.group1.id}"]

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        start_time = "15:00"
        duration   = "3h"
      }
    }

    master_logging {
      enabled = true
      folder_id = var.folder_id
      kube_apiserver_enabled = true
      cluster_autoscaler_enabled = true
      events_enabled = true
      audit_enabled = true
    }
  }

  service_account_id      = var.service_account //id уже созданного аккаунта записанное в переменные
  node_service_account_id = var.service_account

  labels = {
    my_key       = "k8s_cluster"
    my_other_key = "hw-1"
  }

  release_channel = "RAPID"
  #network_policy_provider = "CALICO"

  kms_provider {
    key_id = "${yandex_kms_symmetric_key.k8s_kms.id}"
  }
}

resource "yandex_kubernetes_node_group" "k8s-node" {
  cluster_id = yandex_kubernetes_cluster.k8s_cluster.id
  version = "1.23"
  name = "k8s-node"

  instance_template {
    platform_id = "standard-v1"
    container_runtime {
      type = "docker"
    }
    network_interface {
      nat = true
      subnet_ids = [yandex_vpc_subnet.k8s_net-a.id]
      #ipv4_dns_records {
      #  fqdn = "{instance_group.id}"
      #  dns_zone_id = yandex_dns_zone.k8s_dns.id
      #}
    }
    resources {
      cores = 4
      memory = 4
    }
    boot_disk {
      type = "network-hdd"
      size = 40
    }
    scheduling_policy {
      preemptible = true
    }
    metadata = {
      ssh-keys = "ubuntu:${file(var.public_key_path)}"
    }
  }
  scale_policy {
    auto_scale {
      min = 1
      max = 3
      initial = 1
    }
  }
  allocation_policy {
    location {
      zone = var.zone
    }
  }
}


output "instance_group_masters_public_ips" {
  description = "Public IP addresses for master"
  value = yandex_kubernetes_cluster.k8s_cluster.master[0].external_v4_endpoint
}
