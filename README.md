# VMS Data Science Workstation on GCP

This Terraform configuration provisions a secure, data science-ready Windows VM in a new GCP project, with network, firewall, and attached disk. It also provides instructions for safe password management and deprovisioning.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (or run `bash setup.sh` to install on Linux)
- [gcloud CLI](https://cloud.google.com/sdk/docs/install)
- Have your GCP billing account ID ready  
	(To list: `gcloud beta billing accounts list`)
- Have your GCP organization ID ready  
	(To list: `gcloud organizations list`)
- Make sure you have permissions to create projects and resources in your GCP organization
- Install all Python requirements:
	```bash
	pip install -r requirements.txt
	```

- To install Terraform system-wide (Linux):
	```bash
	bash setup.sh
	```

## Setup & Guided Provisioning

1. **Clone this repo and enter the terraform directory:**
	```bash
	cd terraform
	```
2. **Choose your VM and disk type (with cost info):**
	```bash
	bash select_config.sh
	```
	- This script will show you 5 ranked VM and disk options (with regular and spot prices) and let you select interactively.
	- Your choices will be written to `terraform.tfvars`.
	- Recommendation for most users: VM: e2-standard-4 or n2-standard-4, Disk: pd-balanced (50GB+)

3. **Guided Start:**
	```bash
	python vms.py provision
	```
	- You will be prompted for all required secrets and configuration values interactively.
	- Alternatively, use the direct Terraform approach:
	```bash
	echo "Would you like to start provisioning a new GCP Data Science Workstation project? (Y/N)"
	read start
	if [ "$start" = "Y" ] || [ "$start" = "y" ]; then
	  terraform init
	  terraform apply
	else
	  echo "Provisioning cancelled."
	fi
	```

## CLI Commands

The VMS CLI provides user-friendly commands for managing your workstation:

- `python vms.py provision` - Provision a new VMS workstation with guided setup
- `python vms.py status` - Show current VMS workstation status and connection details
- `python vms.py destroy` - Safely destroy the VMS workstation with confirmation prompts

## After VM Creation

- **RDP/SSH Access:** Use the external IP and your credentials.
- **Windows Admin Password:**
	- During `terraform apply`, you will be prompted for a Windows admin password (or leave blank to auto-generate).
	- The password will be set automatically using `gcloud compute reset-windows-password` after the VM is provisioned.
	- The password (if set) will be output as a sensitive Terraform output. If left blank, check your CLI output for the generated password.
- **Power BI Installation:**
	- On first login, open Edge/Chrome and download Power BI Desktop from https://powerbi.microsoft.com/desktop
	- Or run the pre-installed shortcut on the desktop (if available).

## Deprovisioning (Cleanup)

To delete all resources, including the VM, disks, and the project itself:

```bash
# Using the CLI (recommended)
python vms.py destroy

# Or using Terraform directly
cd terraform
terraform destroy

# Or, to delete the entire project (irreversible!)
echo "Would you like to destroy project NEW_PROJECT_ID and all its dependencies? (yes/no)"
read confirm
if [ "$confirm" = "yes" ]; then
	gcloud projects delete NEW_PROJECT_ID
else
	echo "Project deletion cancelled."
fi
```

## Features

- **User-friendly CLI** with confirmation prompts before any destructive actions
- **Automated tasks** without exposing secrets - all sensitive data is handled securely
- **Interactive configuration selection** with cost information display
- **Comprehensive .gitignore** - excludes files larger than 1MB, OS images, and sensitive data
- **Secure password management** - option to auto-generate or set custom Windows admin password
- **Cost transparency** - shows estimated costs for VM and disk configurations before deployment
- **Safe deprovisioning** - multiple confirmation prompts to prevent accidental resource deletion

## Notes

- The attached 50GB+ disk is mounted as a secondary drive (D:). Use it for data storage.
- All network access is restricted to your IP for safety.
- Windows Defender is enabled and updated on first boot.
- For GPU or more advanced data science needs, edit `main.tf` to use a GPU-enabled machine type and image.
- The CLI automatically handles Terraform initialization and provides clear status information.

## Security

- Network access is automatically restricted to your current public IP address
- Windows admin passwords are handled securely (never logged or displayed in plain text)
- GCP credentials and secrets are never committed to version control
- All large files and OS images are excluded from git via comprehensive .gitignore