#!/usr/bin/env python3
"""
VMS CLI Application - Data Science Workstation on GCP
A user-friendly CLI for provisioning Windows VMs in GCP with Terraform
"""

import os
import sys
import subprocess
import json
import getpass
from pathlib import Path
from typing import Optional, Dict, Any

try:
    import click
    from rich.console import Console
    from rich.prompt import Prompt, Confirm
    from rich.panel import Panel
    from rich.progress import Progress, SpinnerColumn, TextColumn
    from rich.table import Table
    from rich.text import Text
except ImportError:
    print("❌ Required packages not found. Please run: pip install -r requirements.txt")
    sys.exit(1)

console = Console()

class VMSManager:
    """Main VMS management class"""
    
    def __init__(self):
        self.project_dir = Path(__file__).parent
        self.terraform_dir = self.project_dir / "terraform"
        self.tfvars_file = self.terraform_dir / "terraform.tfvars"
        
    def check_prerequisites(self) -> bool:
        """Check if all prerequisites are installed"""
        console.print("🔍 Checking prerequisites...", style="blue")
        
        # Check Terraform
        try:
            result = subprocess.run(['terraform', '--version'], capture_output=True, text=True)
            if result.returncode == 0:
                console.print("✅ Terraform found", style="green")
            else:
                console.print("❌ Terraform not found. Run: bash setup.sh", style="red")
                return False
        except FileNotFoundError:
            console.print("❌ Terraform not found. Run: bash setup.sh", style="red")
            return False
            
        # Check gcloud CLI
        try:
            result = subprocess.run(['gcloud', '--version'], capture_output=True, text=True)
            if result.returncode == 0:
                console.print("✅ gcloud CLI found", style="green")
            else:
                console.print("❌ gcloud CLI not found. Please install from: https://cloud.google.com/sdk/docs/install", style="red")
                return False
        except FileNotFoundError:
            console.print("❌ gcloud CLI not found. Please install from: https://cloud.google.com/sdk/docs/install", style="red")
            return False
            
        return True
    
    def get_gcp_info(self) -> Dict[str, str]:
        """Interactively collect GCP information"""
        console.print("\n📋 GCP Configuration", style="bold blue")
        
        # Get billing accounts
        console.print("🔍 Fetching your GCP billing accounts...", style="blue")
        try:
            result = subprocess.run(['gcloud', 'beta', 'billing', 'accounts', 'list', '--format=json'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                billing_accounts = json.loads(result.stdout)
                if billing_accounts:
                    table = Table(title="Available Billing Accounts")
                    table.add_column("Name", style="cyan")
                    table.add_column("Account ID", style="green")
                    table.add_column("Open", style="yellow")
                    
                    for account in billing_accounts:
                        table.add_row(
                            account.get('displayName', 'N/A'),
                            account.get('name', '').replace('billingAccounts/', ''),
                            'Yes' if account.get('open', False) else 'No'
                        )
                    console.print(table)
        except Exception as e:
            console.print(f"⚠️ Could not fetch billing accounts: {e}", style="yellow")
            
        billing_account_id = Prompt.ask("Enter your GCP billing account ID")
        
        # Get organizations
        console.print("🔍 Fetching your GCP organizations...", style="blue")
        try:
            result = subprocess.run(['gcloud', 'organizations', 'list', '--format=json'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                orgs = json.loads(result.stdout)
                if orgs:
                    table = Table(title="Available Organizations")
                    table.add_column("Display Name", style="cyan")
                    table.add_column("Organization ID", style="green")
                    
                    for org in orgs:
                        table.add_row(
                            org.get('displayName', 'N/A'),
                            org.get('name', '').replace('organizations/', '')
                        )
                    console.print(table)
        except Exception as e:
            console.print(f"⚠️ Could not fetch organizations: {e}", style="yellow")
            
        organization_id = Prompt.ask("Enter your GCP organization ID")
        
        project_name = Prompt.ask("Enter a name for your new GCP project", default="VMS Data Science Workstation")
        
        return {
            'billing_account_id': billing_account_id,
            'organization_id': organization_id,
            'project_name': project_name
        }
    
    def run_config_selection(self) -> bool:
        """Run the configuration selection script"""
        console.print("\n⚙️ Running VM configuration selection...", style="blue")
        
        try:
            os.chdir(self.terraform_dir)
            result = subprocess.run(['bash', 'select_config.sh'], check=True)
            return True
        except subprocess.CalledProcessError as e:
            console.print(f"❌ Configuration selection failed: {e}", style="red")
            return False
        except FileNotFoundError:
            console.print("❌ select_config.sh not found in terraform directory", style="red")
            return False
    
    def get_windows_password(self) -> str:
        """Get Windows admin password from user"""
        console.print("\n🔐 Windows Admin Password", style="bold blue")
        console.print("You can either:")
        console.print("1. Set a custom password")
        console.print("2. Leave blank to auto-generate a secure password")
        
        password = getpass.getpass("Enter Windows admin password (or press Enter for auto-generate): ")
        return password
    
    def update_tfvars(self, gcp_info: Dict[str, str], password: str) -> None:
        """Update terraform.tfvars with all configuration"""
        
        # Read existing tfvars if it exists
        existing_config = {}
        if self.tfvars_file.exists():
            with open(self.tfvars_file, 'r') as f:
                content = f.read()
                # Parse existing values (simple parsing for generated format)
                for line in content.split('\n'):
                    if '=' in line and not line.strip().startswith('#'):
                        key, value = line.split('=', 1)
                        existing_config[key.strip()] = value.strip().strip('"')
        
        # Write complete configuration
        with open(self.tfvars_file, 'w') as f:
            f.write(f'''# VMS Configuration - Generated by VMS CLI
# Generated on: {subprocess.run(["date"], capture_output=True, text=True).stdout.strip()}

# GCP Configuration
project_name = "{gcp_info['project_name']}"
billing_account_id = "{gcp_info['billing_account_id']}"
organization_id = "{gcp_info['organization_id']}"

# VM Configuration (from select_config.sh)
vm_machine_type = "{existing_config.get('vm_machine_type', 'e2-standard-4')}"
disk_type = "{existing_config.get('disk_type', 'pd-balanced')}"
disk_size_gb = {existing_config.get('disk_size_gb', '50')}

# Windows Configuration
windows_admin_password = "{password}"
''')
    
    def terraform_init(self) -> bool:
        """Initialize Terraform"""
        console.print("\n🚀 Initializing Terraform...", style="blue")
        
        try:
            os.chdir(self.terraform_dir)
            with Progress(
                SpinnerColumn(),
                TextColumn("[progress.description]{task.description}"),
                console=console
            ) as progress:
                task = progress.add_task("Initializing Terraform...", total=None)
                result = subprocess.run(['terraform', 'init'], 
                                      capture_output=True, text=True, check=True)
                progress.stop()
            
            console.print("✅ Terraform initialized successfully", style="green")
            return True
        except subprocess.CalledProcessError as e:
            console.print(f"❌ Terraform init failed: {e.stderr}", style="red")
            return False
    
    def terraform_plan(self) -> bool:
        """Run Terraform plan"""
        console.print("\n📋 Planning Terraform deployment...", style="blue")
        
        try:
            os.chdir(self.terraform_dir)
            result = subprocess.run(['terraform', 'plan'], check=True)
            return True
        except subprocess.CalledProcessError as e:
            console.print(f"❌ Terraform plan failed", style="red")
            return False
    
    def terraform_apply(self) -> bool:
        """Apply Terraform configuration"""
        console.print("\n🚀 Deploying your VMS workstation...", style="blue")
        console.print("⚠️ This will create real GCP resources and incur costs!", style="yellow")
        
        if not Confirm.ask("Do you want to proceed with the deployment?"):
            console.print("Deployment cancelled.", style="yellow")
            return False
        
        try:
            os.chdir(self.terraform_dir)
            result = subprocess.run(['terraform', 'apply', '-auto-approve'], check=True)
            console.print("🎉 VMS workstation deployed successfully!", style="green")
            
            # Show outputs
            self.show_outputs()
            return True
        except subprocess.CalledProcessError as e:
            console.print(f"❌ Terraform apply failed", style="red")
            return False
    
    def show_outputs(self) -> None:
        """Show Terraform outputs"""
        try:
            os.chdir(self.terraform_dir)
            result = subprocess.run(['terraform', 'output', '-json'], 
                                  capture_output=True, text=True, check=True)
            outputs = json.loads(result.stdout)
            
            table = Table(title="🎉 Your VMS Workstation Details")
            table.add_column("Property", style="cyan")
            table.add_column("Value", style="green")
            
            for key, value in outputs.items():
                if isinstance(value, dict) and 'value' in value:
                    table.add_row(key.replace('_', ' ').title(), str(value['value']))
            
            console.print(table)
            
            console.print("\n📖 Next Steps:", style="bold blue")
            console.print("1. Connect via RDP using the external IP above")
            console.print("2. Use your Windows admin credentials")
            console.print("3. The D: drive is available for data storage")
            console.print("4. Download Power BI from the desktop shortcut")
            
        except Exception as e:
            console.print(f"⚠️ Could not fetch outputs: {e}", style="yellow")
    
    def terraform_destroy(self) -> bool:
        """Destroy Terraform resources"""
        console.print("\n🗑️ Destroying VMS workstation...", style="red")
        console.print("⚠️ This will permanently delete all resources!", style="yellow")
        
        if not Confirm.ask("Are you sure you want to destroy all resources?", default=False):
            console.print("Destruction cancelled.", style="yellow")
            return False
        
        # Double confirmation
        if not Confirm.ask("This action cannot be undone. Confirm destruction?", default=False):
            console.print("Destruction cancelled.", style="yellow")
            return False
        
        try:
            os.chdir(self.terraform_dir)
            result = subprocess.run(['terraform', 'destroy', '-auto-approve'], check=True)
            console.print("✅ VMS workstation destroyed successfully", style="green")
            return True
        except subprocess.CalledProcessError as e:
            console.print(f"❌ Terraform destroy failed", style="red")
            return False

@click.group()
def cli():
    """VMS CLI - Data Science Workstation on GCP"""
    pass

@cli.command()
def provision():
    """Provision a new VMS workstation"""
    console.print(Panel("🚀 VMS Provisioning Wizard", style="bold blue"))
    
    vms = VMSManager()
    
    # Check prerequisites
    if not vms.check_prerequisites():
        console.print("\n❌ Prerequisites not met. Please install missing components.", style="red")
        return
    
    # Get GCP information
    gcp_info = vms.get_gcp_info()
    
    # Run configuration selection
    if not vms.run_config_selection():
        console.print("\n❌ Configuration selection failed.", style="red")
        return
    
    # Get Windows password
    password = vms.get_windows_password()
    
    # Update tfvars
    vms.update_tfvars(gcp_info, password)
    
    # Initialize Terraform
    if not vms.terraform_init():
        return
    
    # Show plan
    if not vms.terraform_plan():
        return
    
    # Apply configuration
    vms.terraform_apply()

@cli.command()
def destroy():
    """Destroy the VMS workstation"""
    console.print(Panel("🗑️ VMS Destruction", style="bold red"))
    
    vms = VMSManager()
    
    if not vms.check_prerequisites():
        console.print("\n❌ Prerequisites not met.", style="red")
        return
    
    vms.terraform_destroy()

@cli.command()
def status():
    """Show current VMS status"""
    console.print(Panel("📊 VMS Status", style="bold blue"))
    
    vms = VMSManager()
    
    try:
        os.chdir(vms.terraform_dir)
        
        # Check if terraform is initialized
        if not (vms.terraform_dir / ".terraform").exists():
            console.print("❌ Terraform not initialized. Run 'vms provision' first.", style="red")
            return
        
        # Show current state
        result = subprocess.run(['terraform', 'show', '-json'], 
                              capture_output=True, text=True, check=True)
        state = json.loads(result.stdout)
        
        if state.get('values'):
            console.print("✅ VMS workstation is deployed", style="green")
            vms.show_outputs()
        else:
            console.print("📭 No VMS workstation currently deployed", style="yellow")
            
    except subprocess.CalledProcessError:
        console.print("📭 No VMS workstation currently deployed", style="yellow")
    except Exception as e:
        console.print(f"❌ Error checking status: {e}", style="red")

if __name__ == '__main__':
    cli()