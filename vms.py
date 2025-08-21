#!/usr/bin/env python3
"""
VMS - GCP Data Science Workstation CLI
A lean CLI app for creating and managing GCP VMs with Terraform
"""

import os
import sys
import subprocess
import json
import click
from pathlib import Path
from colorama import init, Fore, Style
from tabulate import tabulate
from google.cloud import resourcemanager_v3
from google.auth import default

# Initialize colorama for cross-platform colored output
init()

REPO_ROOT = Path(__file__).parent
TERRAFORM_DIR = REPO_ROOT / "terraform"
SCRIPTS_DIR = REPO_ROOT / "scripts"


def print_banner():
    """Print the VMS CLI banner"""
    print(f"{Fore.CYAN}╔═══════════════════════════════════════╗{Style.RESET_ALL}")
    print(f"{Fore.CYAN}║          VMS - GCP VM Manager         ║{Style.RESET_ALL}")
    print(f"{Fore.CYAN}║    Data Science Workstation CLI      ║{Style.RESET_ALL}")
    print(f"{Fore.CYAN}╚═══════════════════════════════════════╝{Style.RESET_ALL}")
    print()


def check_prerequisites():
    """Check if required tools are installed"""
    print(f"{Fore.YELLOW}Checking prerequisites...{Style.RESET_ALL}")
    
    missing_tools = []
    
    # Check Terraform
    try:
        result = subprocess.run(["terraform", "version"], capture_output=True, text=True)
        if result.returncode != 0:
            missing_tools.append("terraform")
    except FileNotFoundError:
        missing_tools.append("terraform")
    
    if missing_tools:
        print(f"{Fore.RED}Missing required tools: {', '.join(missing_tools)}{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}To install missing tools:{Style.RESET_ALL}")
        if "terraform" in missing_tools:
            print(f"  - Terraform: Run {Fore.GREEN}bash scripts/setup.sh{Style.RESET_ALL}")
        return False
    
    print(f"{Fore.GREEN}✓ All prerequisites met{Style.RESET_ALL}")
    return True


def confirm_action(message, default=False):
    """Ask for user confirmation with a clear prompt"""
    default_text = "Y/n" if default else "y/N"
    response = input(f"{Fore.YELLOW}{message} ({default_text}): {Style.RESET_ALL}").strip().lower()
    
    if not response:
        return default
    
    return response in ['y', 'yes']


def delete_gcp_project(project_id):
    """Delete a GCP project using the Resource Manager API"""
    try:
        # Get default credentials
        credentials, _ = default()
        
        # Create Resource Manager client
        client = resourcemanager_v3.ProjectsClient(credentials=credentials)
        
        # Delete the project
        request = resourcemanager_v3.DeleteProjectRequest(name=f"projects/{project_id}")
        operation = client.delete_project(request=request)
        
        print(f"{Fore.YELLOW}Project deletion initiated. This may take a few minutes...{Style.RESET_ALL}")
        
        # Wait for operation to complete
        result = operation.result(timeout=300)  # 5 minute timeout
        
        return True
        
    except Exception as e:
        print(f"{Fore.RED}Error deleting project: {str(e)}{Style.RESET_ALL}")
        return False


@click.group()
@click.version_option(version="1.0.0", prog_name="vms")
def cli():
    """VMS - GCP Data Science Workstation CLI
    
    A lean CLI app for creating and managing secure, data science-ready 
    Windows VMs in GCP with Terraform.
    """
    pass


@cli.command()
def setup():
    """Setup and install dependencies"""
    print_banner()
    
    print(f"{Fore.CYAN}Setting up VMS CLI environment...{Style.RESET_ALL}")
    
    if not confirm_action("Install Python dependencies?", True):
        print("Setup cancelled.")
        return
    
    # Install Python dependencies
    print(f"{Fore.YELLOW}Installing Python dependencies...{Style.RESET_ALL}")
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"], check=True)
        print(f"{Fore.GREEN}✓ Python dependencies installed{Style.RESET_ALL}")
    except subprocess.CalledProcessError:
        print(f"{Fore.RED}✗ Failed to install Python dependencies{Style.RESET_ALL}")
        return
    
    # Check if Terraform setup is needed
    try:
        subprocess.run(["terraform", "version"], capture_output=True, check=True)
        print(f"{Fore.GREEN}✓ Terraform already installed{Style.RESET_ALL}")
    except (FileNotFoundError, subprocess.CalledProcessError):
        if confirm_action("Install Terraform system-wide? (Linux only)", True):
            print(f"{Fore.YELLOW}Installing Terraform...{Style.RESET_ALL}")
            try:
                subprocess.run(["bash", "scripts/setup.sh"], check=True)
                print(f"{Fore.GREEN}✓ Terraform installed{Style.RESET_ALL}")
            except subprocess.CalledProcessError:
                print(f"{Fore.RED}✗ Failed to install Terraform{Style.RESET_ALL}")
    
    print(f"{Fore.GREEN}Setup complete!{Style.RESET_ALL}")
    print(f"{Fore.YELLOW}Authentication setup:{Style.RESET_ALL}")
    print(f"{Fore.YELLOW}  For GCP authentication, you can use:{Style.RESET_ALL}")
    print(f"{Fore.YELLOW}  - Service account key file (set GOOGLE_APPLICATION_CREDENTIALS env var){Style.RESET_ALL}")
    print(f"{Fore.YELLOW}  - Application Default Credentials (gcloud auth application-default login){Style.RESET_ALL}")
    print(f"{Fore.YELLOW}  - Or run: export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json{Style.RESET_ALL}")


@cli.command()
def configure():
    """Configure VM and disk options interactively"""
    print_banner()
    
    if not check_prerequisites():
        return
    
    print(f"{Fore.CYAN}Configuring VM and disk options...{Style.RESET_ALL}")
    
    if not confirm_action("Select VM and disk configuration?", True):
        print("Configuration cancelled.")
        return
    
    # Run the configuration script
    config_script = SCRIPTS_DIR / "select_config.sh"
    if config_script.exists():
        try:
            subprocess.run(["bash", str(config_script)], check=True, cwd=TERRAFORM_DIR)
            print(f"{Fore.GREEN}✓ Configuration saved to terraform/terraform.tfvars{Style.RESET_ALL}")
        except subprocess.CalledProcessError:
            print(f"{Fore.RED}✗ Configuration failed{Style.RESET_ALL}")
    else:
        print(f"{Fore.RED}✗ Configuration script not found{Style.RESET_ALL}")


@cli.command()
def provision():
    """Provision a new GCP Data Science Workstation"""
    print_banner()
    
    if not check_prerequisites():
        return
    
    print(f"{Fore.CYAN}Provisioning GCP Data Science Workstation...{Style.RESET_ALL}")
    
    # Confirm before proceeding
    if not confirm_action("Start provisioning a new GCP Data Science Workstation project?", False):
        print("Provisioning cancelled.")
        return
    
    # Change to terraform directory
    os.chdir(TERRAFORM_DIR)
    
    try:
        # Initialize Terraform
        print(f"{Fore.YELLOW}Initializing Terraform...{Style.RESET_ALL}")
        subprocess.run(["terraform", "init"], check=True)
        
        # Apply Terraform configuration
        print(f"{Fore.YELLOW}Applying Terraform configuration...{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}You will be prompted for required configuration values.{Style.RESET_ALL}")
        subprocess.run(["terraform", "apply"], check=True)
        
        print(f"{Fore.GREEN}✓ Provisioning complete!{Style.RESET_ALL}")
        
    except subprocess.CalledProcessError:
        print(f"{Fore.RED}✗ Provisioning failed{Style.RESET_ALL}")
        return


@cli.command()
def destroy():
    """Destroy the GCP workstation and clean up resources"""
    print_banner()
    
    if not check_prerequisites():
        return
    
    print(f"{Fore.RED}DANGER: This will destroy all resources in your GCP project!{Style.RESET_ALL}")
    
    if not confirm_action("Destroy all resources using Terraform?", False):
        print("Destroy cancelled.")
        return
    
    # Change to terraform directory
    os.chdir(TERRAFORM_DIR)
    
    try:
        print(f"{Fore.YELLOW}Destroying resources...{Style.RESET_ALL}")
        subprocess.run(["terraform", "destroy"], check=True)
        print(f"{Fore.GREEN}✓ Resources destroyed{Style.RESET_ALL}")
        
    except subprocess.CalledProcessError:
        print(f"{Fore.RED}✗ Destroy failed{Style.RESET_ALL}")
        return
    
    # Offer to delete the entire project
    if confirm_action("Delete the entire GCP project? (IRREVERSIBLE!)", False):
        project_id = input(f"{Fore.YELLOW}Enter project ID to delete: {Style.RESET_ALL}").strip()
        
        if project_id and confirm_action(f"Are you absolutely sure you want to delete project '{project_id}'?", False):
            if delete_gcp_project(project_id):
                print(f"{Fore.GREEN}✓ Project '{project_id}' deletion initiated{Style.RESET_ALL}")
            else:
                print(f"{Fore.RED}✗ Failed to delete project{Style.RESET_ALL}")
        else:
            print("Project deletion cancelled.")


@cli.command()
def status():
    """Show current status and configuration"""
    print_banner()
    
    print(f"{Fore.CYAN}VMS Status{Style.RESET_ALL}")
    print("=" * 50)
    
    # Check prerequisites
    check_prerequisites()
    
    # Check if terraform directory exists and is initialized
    if TERRAFORM_DIR.exists():
        terraform_init_file = TERRAFORM_DIR / ".terraform"
        if terraform_init_file.exists():
            print(f"{Fore.GREEN}✓ Terraform initialized{Style.RESET_ALL}")
        else:
            print(f"{Fore.YELLOW}! Terraform not initialized{Style.RESET_ALL}")
        
        # Check for terraform.tfvars
        tfvars_file = TERRAFORM_DIR / "terraform.tfvars"
        if tfvars_file.exists():
            print(f"{Fore.GREEN}✓ Configuration file exists{Style.RESET_ALL}")
        else:
            print(f"{Fore.YELLOW}! No configuration file found{Style.RESET_ALL}")
    else:
        print(f"{Fore.RED}✗ Terraform directory not found{Style.RESET_ALL}")


if __name__ == "__main__":
    cli()