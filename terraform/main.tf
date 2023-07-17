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

resource "yandex_kubernetes_cluster" "project" {
  name        = "project"
  #description = "description"

  network_id = "${yandex_vpc_network.network_resource_name.id}"

  master {
    version = "1.27"
    zonal {
      zone      = "${yandex_vpc_subnet.subnet_resource_name.zone}"
      subnet_id = "${yandex_vpc_subnet.subnet_resource_name.id}"
    }

    public_ip = true

    security_group_ids = ["${yandex_vpc_security_group.security_group_name.id}"]

    master_logging {
      enabled = true
      log_group_id = "${yandex_logging_group.log_group_resoruce_name.id}"
      kube_apiserver_enabled = true
      cluster_autoscaler_enabled = true
      events_enabled = true
      audit_enabled = true
    }
  }

  service_account_id      = "${yandex_iam_service_account.service_account_resource_name.id}"
  node_service_account_id = "${yandex_iam_service_account.node_service_account_resource_name.id}"

  labels = {
    my_key       = "my_value"
    my_other_key = "my_other_value"
  }

  release_channel = "RAPID"
  network_policy_provider = "CALICO"

  kms_provider {
    key_id = "${yandex_kms_symmetric_key.kms_key_resource_name.id}"
  }
}
