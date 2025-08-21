# VMS - GCP Data Science Workstation - personal utility

A lean CLI app for creating and managing secure, data science-ready Windows VMs in GCP with Terraform.

## Features

- **Interactive VM Configuration**: Choose from multiple VM types with cost information
- **Spot Instance Support**: Save 60-91% on compute costs
- **Secure by Default**: Network access restricted to your IP
- **Data Science Ready**: Pre-configured with essential tools
- **User-Friendly**: Confirmation prompts before any destructive actions
- **Automated Setup**: One-command installation and deployment


## Quick Start (GCP CLI Only)

1. **Clone and setup**:
   ```bash
   git clone <this-repo>
   cd vms
   python3 vms.py setup
   ```

2. **Configure your VM**:
   ```bash
   python3 vms.py configure
   ```

3. **Deploy your workstation**:
   ```bash
   python3 vms.py provision
   ```

4. **Destroy all resources (GCP CLI only)**:
   ```bash
   python3 vms.py destroy
   ```

**Note:** All commands above are run in GCP Cloud Shell or any environment with gcloud and Terraform installed and authenticated. No service account key is required if you use Cloud Shell or gcloud auth application-default login.

### Troubleshooting

- If you see errors about missing APIs (e.g., Compute Engine API, Cloud Resource Manager API, Cloud Billing API), enable them in the GCP Console for your project.
- If you see permission errors, ensure your user has the required IAM roles (Project Creator, Billing Manager, Compute Admin).
- If you see 'bc: command not found', run `sudo apt-get install -y bc` in Cloud Shell.
- For image errors, use the correct image family and project, e.g., `projects/windows-cloud/global/images/family/windows-2022` for Windows Server 2022.

## Prerequisites

- Python 3.7+
- GCP billing account and organization access
- Terraform (or run `bash scripts/setup.sh` to install on Linux)
- GCP authentication (see Authentication section below)

## Authentication

VMS supports multiple GCP authentication methods (no gcloud required):

### Method 1: Service Account (Recommended)
1. Create a service account in GCP Console with these roles:
   - Project Creator
   - Billing Account User  
   - Compute Admin
2. Download the JSON key file
3. Set environment variable: `export GOOGLE_APPLICATION_CREDENTIALS=/path/to/keyfile.json`

### Method 2: User Account
If you have gcloud installed: `gcloud auth application-default login`

### Method 3: Workload Identity
Automatically works in GCP environments (Cloud Shell, GCE instances, etc.)

## Commands

- `python3 vms.py setup` - Install dependencies and tools
- `python3 vms.py configure` - Select VM and disk configuration interactively
- `python3 vms.py provision` - Create the GCP workstation
- `python3 vms.py destroy` - Clean up resources
- `python3 vms.py status` - Show current configuration and status

## Configuration

The interactive configuration script will help you choose:

- **VM Type**: From e2-micro to c2-standard-4 with cost estimates
- **Spot Instances**: Significant savings for development workloads
- **Disk Type**: Standard, balanced, or SSD persistent disks
- **Disk Size**: Minimum 50GB, recommended 100GB+

## Security

- Network access restricted to your current IP
- Windows Defender enabled and updated
- No credentials stored in files
- Secure password generation

## What's Included

Your VM comes pre-configured with:

- Windows Server 2022 Datacenter
- Additional 50GB SSD data drive (D:)
- Firefox, Chrome, VS Code, Python, Git
- Power BI Desktop download shortcut
- Windows Defender protection

## Cost Estimation

Regular instances start from ~$5/month for basic usage. Spot instances provide 60-91% savings. The configuration tool shows estimated monthly costs for all options.

## Cleanup


Always clean up resources when done:

```bash
# Remove all resources but keep project
python3 vms.py destroy

# To delete entire project manually:
# 1. Via GCP Console: https://console.cloud.google.com/iam-admin/projects
# 2. Via gcloud (if installed): gcloud projects delete PROJECT_ID
```

**Troubleshooting destroy issues:**

- If `python3 vms.py destroy` hangs or fails to delete the VPC network, it usually means there are still resources (such as subnets, firewall rules, or static IPs) attached to the network.
- **Remediation:**
   1. Go to the GCP Console > VPC network > VPC networks.
   2. Check for any remaining subnets, firewall rules, or static IPs associated with your custom network (not the default network).
   3. Delete these resources manually if they remain.
   4. Retry `python3 vms.py destroy` to complete cleanup.

## Support

This tool creates standard GCP resources. For issues:
1. Check GCP Console for resource status
2. Review Terraform logs
3. Ensure GCP permissions are correct