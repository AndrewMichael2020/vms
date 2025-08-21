# Variables for VMS GCP configuration
variable "project_name" {
  description = "Name for the new GCP project"
  type        = string
  default     = "vms-workstation"
}

variable "project_id" {
  description = "GCP Project ID (leave empty to auto-generate)"
  type        = string
  default     = ""
}

variable "billing_account_id" {
  description = "GCP Billing Account ID"
  type        = string
}

variable "org_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "GCP machine type for the VM"
  type        = string
  default     = "e2-standard-4"
}

variable "preemptible" {
  description = "Use preemptible (spot) instance"
  type        = bool
  default     = false
}

variable "disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-balanced"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 100
}

variable "attached_disk_size_gb" {
  description = "Additional SSD disk size in GB"
  type        = number
  default     = 50
}

variable "windows_admin_password" {
  description = "Windows admin password (leave empty to auto-generate)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "allowed_ip_ranges" {
  description = "IP ranges allowed to access the VM (leave empty to use your current IP)"
  type        = list(string)
  default     = []
}