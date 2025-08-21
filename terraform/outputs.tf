output "project_id" {
  description = "The GCP project ID"
  value       = google_project.project.project_id
}

output "vm_name" {
  description = "Name of the VM instance"
  value       = google_compute_instance.vm_instance.name
}

output "vm_external_ip" {
  description = "External IP address of the VM"
  value       = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
}

output "vm_zone" {
  description = "Zone where the VM is deployed"
  value       = google_compute_instance.vm_instance.zone
}

output "machine_type" {
  description = "Machine type of the VM"
  value       = google_compute_instance.vm_instance.machine_type
}

output "is_preemptible" {
  description = "Whether the VM is preemptible (spot instance)"
  value       = var.preemptible
}

output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc_network.name
}

output "allowed_ip_ranges" {
  description = "IP ranges allowed to access the VM"
  value       = local.allowed_ips
}

output "windows_admin_password" {
  description = "Windows administrator password"
  value       = local.admin_password
  sensitive   = true
}

output "rdp_connection_info" {
  description = "RDP connection information"
  value = {
    external_ip = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
    username    = "Administrator"
    password    = local.admin_password
    port        = 3389
  }
  sensitive = true
}

output "data_disk_info" {
  description = "Information about the attached data disk"
  value = {
    name      = google_compute_disk.data_disk.name
    size_gb   = google_compute_disk.data_disk.size
    type      = google_compute_disk.data_disk.type
    drive     = "D:"
  }
}

output "connection_instructions" {
  description = "Instructions for connecting to the VM"
  value = <<-EOT
    ╔════════════════════════════════════════════════════════════════╗
    ║                     Connection Information                     ║
    ╠════════════════════════════════════════════════════════════════╣
    ║ VM External IP: ${google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip}                                     ║
    ║ Username:       Administrator                                  ║
    ║ RDP Port:       3389                                          ║
    ║                                                               ║
    ║ To connect:                                                   ║
    ║ 1. Use Remote Desktop Connection (Windows)                    ║
    ║ 2. Or use 'rdesktop' on Linux                               ║
    ║ 3. SSH access also available on port 22 (if needed)          ║
    ║                                                               ║
    ║ Data Storage:                                                 ║
    ║ • Boot disk: ${var.disk_size_gb}GB (${var.disk_type})                               ║
    ║ • Data disk: ${var.attached_disk_size_gb}GB SSD (mounted as D: drive)                ║
    ║                                                               ║
    ║ Security:                                                     ║
    ║ • Access restricted to: ${join(", ", local.allowed_ips)}                     ║
    ║ • Windows Defender enabled and updated                        ║
    ╚════════════════════════════════════════════════════════════════╝
  EOT
}