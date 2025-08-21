# VMS - GCP Data Science Workstation

A lean CLI app for creating and managing secure, data science-ready Windows VMs in GCP with Terraform.

## Features

- **Interactive VM Configuration**: Choose from multiple VM types with cost information
- **Spot Instance Support**: Save 60-91% on compute costs
- **Secure by Default**: Network access restricted to your IP
- **Data Science Ready**: Pre-configured with essential tools
- **User-Friendly**: Confirmation prompts before any destructive actions
- **Automated Setup**: One-command installation and deployment

## Quick Start

### Option 1: Interactive Menu
```bash
git clone <this-repo>
cd vms
./quickstart.sh
```

### Option 2: Direct Commands
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

## Prerequisites

- Python 3.7+
- Terraform (or run `bash scripts/setup.sh` to install on Linux)
- GCP authentication (service account key file or Application Default Credentials)
- GCP billing account and organization access

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

# Or delete entire project (irreversible!)
# Follow prompts during destroy command
```

## Support

This tool creates standard GCP resources. For issues:
1. Check GCP Console for resource status
2. Review Terraform logs
3. Ensure GCP permissions are correct