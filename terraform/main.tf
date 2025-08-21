# Get current IP address for firewall rules
data "http" "current_ip" {
  url = "https://ipv4.icanhazip.com"
}

locals {
  # Generate project ID if not provided
  project_id = var.project_id != "" ? var.project_id : "${var.project_name}-${random_id.project_suffix.hex}"
  
  # Use provided IP ranges or current IP
  allowed_ips = length(var.allowed_ip_ranges) > 0 ? var.allowed_ip_ranges : ["${chomp(data.http.current_ip.response_body)}/32"]
  
  # Generate password if not provided
  admin_password = var.windows_admin_password != "" ? var.windows_admin_password : random_password.windows_admin_password.result
}

# Random suffix for project ID
resource "random_id" "project_suffix" {
  byte_length = 4
}

# Generate Windows admin password if not provided
resource "random_password" "windows_admin_password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Create new GCP project
resource "google_project" "project" {
  name            = var.project_name
  project_id      = local.project_id
  billing_account = var.billing_account_id
  org_id         = var.org_id
}

# Enable required APIs
resource "google_project_service" "compute_api" {
  project = google_project.project.project_id
  service = "compute.googleapis.com"
  
  disable_dependent_services = true
}

# VPC Network
resource "google_compute_network" "vpc_network" {
  project                 = google_project.project.project_id
  name                    = "vms-network"
  auto_create_subnetworks = false
  
  depends_on = [google_project_service.compute_api]
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  project       = google_project.project.project_id
  name          = "vms-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

# Firewall rule for RDP
resource "google_compute_firewall" "allow_rdp" {
  project = google_project.project.project_id
  name    = "allow-rdp"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = local.allowed_ips
  target_tags   = ["rdp-server"]
}

# Firewall rule for SSH (optional, for troubleshooting)
resource "google_compute_firewall" "allow_ssh" {
  project = google_project.project.project_id
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = local.allowed_ips
  target_tags   = ["ssh-server"]
}

# Additional SSD disk
resource "google_compute_disk" "data_disk" {
  project = google_project.project.project_id
  name    = "vms-data-disk"
  type    = "pd-ssd"
  zone    = var.zone
  size    = var.attached_disk_size_gb
}

# VM Instance
resource "google_compute_instance" "vm_instance" {
  project      = google_project.project.project_id
  name         = "vms-workstation"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["rdp-server", "ssh-server"]

  # Use preemptible if specified
  scheduling {
    preemptible        = var.preemptible
    automatic_restart  = !var.preemptible
    on_host_maintenance = var.preemptible ? "TERMINATE" : "MIGRATE"
  }

  boot_disk {
    initialize_params {
      # Windows Server 2022 Datacenter
      image = "projects/windows-cloud/global/images/family/windows-2022"
      type  = var.disk_type
      size  = var.disk_size_gb
    }
  }

  # Attach additional SSD disk
  attached_disk {
    source      = google_compute_disk.data_disk.id
    device_name = "data-disk"
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      # Ephemeral public IP
    }
  }

  # Startup script for Windows configuration
  metadata = {
    windows-startup-script-ps1 = <<-EOT
      # Enable Windows Defender and update
      Set-MpPreference -DisableRealtimeMonitoring $false
      Update-MpSignature
      
      # Initialize and format the data disk (D:)
      Get-Disk | Where-Object {$_.PartitionStyle -eq 'RAW'} | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -UseMaximumSize -DriveLetter D | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Data" -Confirm:$false
      
      # Install Chocolatey for package management
      Set-ExecutionPolicy Bypass -Scope Process -Force
      [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
      iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
      
      # Install common data science tools
      choco install -y firefox googlechrome vscode python git
      
      # Create desktop shortcut for Power BI download
      $WshShell = New-Object -comObject WScript.Shell
      $Shortcut = $WshShell.CreateShortcut("$env:PUBLIC\Desktop\Download Power BI.url")
      $Shortcut.TargetPath = "https://powerbi.microsoft.com/desktop"
      $Shortcut.Save()
      
      # Set Windows admin password if provided
      if ("${local.admin_password}" -ne "") {
          net user Administrator "${local.admin_password}"
          net user Administrator /active:yes
      }
    EOT
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  depends_on = [
    google_project_service.compute_api,
    google_compute_disk.data_disk
  ]
}
