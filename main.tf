data "terraform_remote_state" "project-and-networks" {
  backend = "remote"
  config = {
    organization = "AFRLDigitalMFG"
    workspaces = {
      name = "shared_vpc_projects"
    }
  }
}

resource "google_compute_address" "ssh-tunnel-external-access" {
  name    =  "ssh-tunnel-external-access-address"
  address_type = "EXTERNAL"
  description = "public endpoint for ssh tunnel endpoint"
  network_tier = "PREMIUM"
  region      = var.region
  project     = var.project_id
}

resource google_compute_firewall "allow-ssh-tunnel-external-access" {
  name    = "allow-ssh-tunnel-endpoint-access"
  network = "projects/${data.terraform_remote_state.project-and-networks.outputs.shared_vpc_host_project}/global/networks/${data.terraform_remote_state.project-and-networks.outputs.afrl-shared-vpc-network-name}"
  project = data.terraform_remote_state.project-and-networks.outputs.shared_vpc_host_project
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags = [var.external_ssh_access_tag]
  source_ranges = ["${var.source_range1}","${var.source_range2}"]
}

resource google_compute_firewall "allow-afrl-sp-subnet-access" {
  name    = "allow-afrl-sp-subnet-access"
  network = "projects/${data.terraform_remote_state.project-and-networks.outputs.shared_vpc_host_project}/global/networks/${data.terraform_remote_state.project-and-networks.outputs.afrl-shared-vpc-network-name}"
  project = data.terraform_remote_state.project-and-networks.outputs.shared_vpc_host_project
  allow {
    protocol = "tcp"
  }
  target_tags = [var.ssh_tunnel_tags]
  source_ranges = ["${data.terraform_remote_state.project-and-networks.outputs.afrl-shared-vpc-subnet-cidr_block}"]
}

resource "google_compute_instance" "ssh-tunnel-endpoint-server" {
  name         = "afrl-ssh-tunnel-endpoint"
  project = var.project_id
  machine_type = "n1-standard-2"
  tags = ["${var.ssh_tunnel_tags}", "${var.external_ssh_access_tag}"]

  zone = var.zone

  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/debian-9-stretch-v20191210"
      size = 10
      type  = "pd-standard"
    }
  }


  network_interface {
    subnetwork = "projects/${var.project_id}/regions/${var.region}/subnetworks/${data.terraform_remote_state.project-and-networks.outputs.afrl-shared-vpc-subnet-1}"

    access_config {
      nat_ip = google_compute_address.ssh-tunnel-external-access.address
    }
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}