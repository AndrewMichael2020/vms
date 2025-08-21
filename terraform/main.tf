# VMS Terraform Configuration for GCP Windows VM

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

# Variables
variable "project_name" {
  description = "Name for the new GCP project"
  type        = string
}

variable "billing_account_id" {
  description = "GCP billing account ID"
  type        = string
}

variable "organization_id" {
  description = "GCP organization ID"
  type        = string
}

variable "vm_machine_type" {
  description = "GCP machine type for the VM"
  type        = string
  default     = "e2-standard-4"
}

variable "disk_type" {
  description = "Type of persistent disk"
  type        = string
  default     = "pd-balanced"
}

variable "disk_size_gb" {
  description = "Size of the persistent disk in GB"
  type        = number
  default     = 50
}

variable "windows_admin_password" {
  description = "Windows admin password (leave empty to auto-generate)"
  type        = string
  default     = ""
  sensitive   = true
}

# Generate random project ID suffix
resource "random_id" "project_suffix" {
  byte_length = 4
}

# Create GCP project
resource "google_project" "vms_project" {
  name                = var.project_name
  project_id          = "${lower(replace(var.project_name, " ", "-"))}-${random_id.project_suffix.hex}"
  billing_account     = var.billing_account_id
  org_id             = var.organization_id
  auto_create_network = false
}

# Enable required APIs
resource "google_project_service" "compute" {
  project = google_project.vms_project.project_id
  service = "compute.googleapis.com"
}

resource "google_project_service" "oslogin" {
  project = google_project.vms_project.project_id
  service = "oslogin.googleapis.com"
}

# Get current user's public IP
data "external" "user_ip" {
  program = ["bash", "-c", "curl -s https://api.ipify.org?format=json"]
}

# Create VPC network
resource "google_compute_network" "vms_network" {
  name                    = "vms-network"
  project                = google_project.vms_project.project_id
  auto_create_subnetworks = false
  depends_on             = [google_project_service.compute]
}

# Create subnet
resource "google_compute_subnetwork" "vms_subnet" {
  name          = "vms-subnet"
  project       = google_project.vms_project.project_id
  network       = google_compute_network.vms_network.id
  ip_cidr_range = "10.0.0.0/24"
  region        = "us-central1"
}

# Create firewall rule for RDP
resource "google_compute_firewall" "allow_rdp" {
  name    = "allow-rdp"
  project = google_project.vms_project.project_id
  network = google_compute_network.vms_network.id

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["${data.external.user_ip.result.ip}/32"]
  target_tags   = ["windows-vm"]
}

# Create firewall rule for SSH (if needed)
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  project = google_project.vms_project.project_id
  network = google_compute_network.vms_network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["${data.external.user_ip.result.ip}/32"]
  target_tags   = ["windows-vm"]
}

# Create persistent disk for data storage
resource "google_compute_disk" "data_disk" {
  name    = "vms-data-disk"
  project = google_project.vms_project.project_id
  type    = var.disk_type
  size    = var.disk_size_gb
  zone    = "us-central1-a"

  depends_on = [google_project_service.compute]
}

# Create Windows VM instance
resource "google_compute_instance" "windows_vm" {
  name         = "vms-windows-workstation"
  project      = google_project.vms_project.project_id
  machine_type = var.vm_machine_type
  zone         = "us-central1-a"

  tags = ["windows-vm"]

  boot_disk {
    initialize_params {
      image = "windows-cloud/windows-2022"
      size  = 100
      type  = "pd-standard"
    }
  }

  # Attach data disk
  attached_disk {
    source      = google_compute_disk.data_disk.id
    device_name = "data-disk"
    mode        = "READ_WRITE"
  }

  network_interface {
    network    = google_compute_network.vms_network.id
    subnetwork = google_compute_subnetwork.vms_subnet.id

    access_config {
      # Ephemeral external IP
    }
  }

  # Startup script to configure Windows
  metadata = {
    sysprep-specialize-script-ps1 = file("${path.module}/windows-startup.ps1")
  }

  depends_on = [
    google_project_service.compute,
    google_compute_disk.data_disk
  ]
}

# Outputs
output "project_id" {
  description = "The GCP project ID"
  value       = google_project.vms_project.project_id
}

output "vm_name" {
  description = "Name of the VM instance"
  value       = google_compute_instance.windows_vm.name
}

output "vm_external_ip" {
  description = "External IP address of the VM"
  value       = google_compute_instance.windows_vm.network_interface[0].access_config[0].nat_ip
}

output "vm_internal_ip" {
  description = "Internal IP address of the VM"
  value       = google_compute_instance.windows_vm.network_interface[0].network_ip
}

output "windows_password" {
  description = "Windows admin password (if auto-generated)"
  value       = var.windows_admin_password == "" ? "Check CLI output for generated password" : "Password set by user"
  sensitive   = true
}