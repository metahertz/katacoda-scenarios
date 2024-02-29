provider "google" {
  credentials = file("./gcloud.secret.json")
  project     = "cas-instruqt"
  region      = "us-central1"  # Change to your desired region
}

## Google API Resources need enabling


resource "google_project_service" "crm_api" {
  service = "cloudresourcemanager.googleapis.com"
  disable_dependent_services = true
}

resource "time_sleep" "gcp_wait_crm_api_enabling" {
  depends_on = [
    google_project_service.crm_api
  ]
  create_duration = "1m"
}

resource "google_project_service" "cloudbuild_service" {
  service = "cloudbuild.googleapis.com"
  depends_on = [time_sleep.gcp_wait_crm_api_enabling]
  disable_dependent_services = true
}


resource "google_compute_network" "panw_ctf_network" {
  name = "panw-ctf-network"
}

resource "google_compute_subnetwork" "panw_ctf_subnet1" {
  name          = "panw-ctf-subnet1"
  network       = google_compute_network.panw_ctf_network.self_link
  ip_cidr_range = "10.0.0.0/24"  # Change to your desired subnet IP range
}

resource "google_compute_instance" "panw_ctf_ui" {
  name         = "panw-ctf-ui"
  machine_type = "n1-standard-1"  # Change to your desired machine type
  zone         = "us-central1-a"  # Change to your desired zone

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-jammy-v20240223"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.panw_ctf_subnet1.self_link

    access_config {
      // This will give the instance a public IP address
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash -xe
    # Cloud-init script for panw_ctf_ui
    echo "Configuring panw_ctf_ui" > /tmp/lablog.txt
    # Add other commands as needed
    pip3 install --upgrade requests
    git clone https://github.com/metahertz/kubernetes-devsecops-workshop.git
    GCP_ACCOUNT_ID=NOTUSED
    sudo chmod +x ./kubernetes-devsecops-workshop/next-jam-24/*.sh
    sudo ./kubernetes-devsecops-workshop/next-jam-24/base-setup-ui.sh
    sudo ./kubernetes-devsecops-workshop/next-jam-24/personalize.sh
  EOF
}

resource "google_compute_instance" "panw_ctf_bank" {
  name         = "panw-ctf-bank"
  machine_type = "n1-standard-1"
  zone         = "us-central1-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-jammy-v20240223"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.panw_ctf_subnet1.self_link

    access_config {
      // This will give the instance a public IP address
    }
  }

  metadata_startup_script = <<-EOF
    # Cloud-init script for panw_ctf_bank
    echo "Configuring panw_ctf_bank" > /tmp/lablog.txt
    sudo apt-get update >> /tmp/lablog.txt
    # Add other commands as needed
    git clone https://github.com/metahertz/kubernetes-devsecops-workshop.git >> /tmp/lablog.txt
    GCP_ACCOUNT_ID=NOTUSED
    sudo chmod +x ./kubernetes-devsecops-workshop/next-jam-24/*.sh
    sudo ./kubernetes-devsecops-workshop/next-jam-24/base-setup-ctf.sh
    sudo ./kubernetes-devsecops-workshop/next-jam-24/personalize.sh
  EOF
}


resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.panw_ctf_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]  # Allow traffic from anywhere (for demonstration purposes)
}



#resource "google_container_registry" "gcr" {
#}

resource "google_cloudbuild_trigger" "build_trigger" {
  depends_on = [google_project_service.cloudbuild_service]
  name     = "rebuild-bank"

  description = "Trigger a rebuild of Jankybank containers"

  filename = "cloudbuild.yaml"  # Replace with your Cloud Build configuration file

  trigger_template {
    branch_name       = "master"  # Replace with the branch you want to trigger the build on
  }

}
