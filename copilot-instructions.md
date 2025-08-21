Following this readme, create a small CLI app to make a very nice, very cool, very lean VM in GCP.
Remember to automate tasks, while not exposing secrets.
Make it user friendly by asking questions for confirmation before committing anything.
Have a comprehensive .gitignore, esp not to store files like OS images (basically anything larger than 1MB).

"# VMS Data Science Workstation on GCP

This Terraform configuration provisions a secure, data science-ready Windows VM in a new GCP project, with network, firewall, and attached disk. It also provides instructions for safe password management and deprovisioning.

Terraform (or run bash setup.sh to install on Linux)

gcloud CLI

Have your GCP billing account ID ready
(To list: gcloud beta billing accounts list)

Have your GCP organization ID ready
(To list: gcloud organizations list)

Make sure you have permissions to create projects and resources in your GCP organization

Install all Python requirements:

 pip install -r requirements.txt
To install Terraform system-wide (Linux):

 bash setup.sh
Setup & Guided Provisioning
Clone this repo and enter the terraform directory:

cd terraform
Choose your VM and disk type (with cost info):

bash select_config.sh
This script will show you 5 ranked VM and disk options (with regular and spot prices) and let you select interactively.
Your choices will be written to terraform.tfvars.
Recommendation for most users: VM: e2-standard-4 or n2-standard-4, Disk: pd-balanced (50GB+)
Guided Start:

echo "Would you like to start provisioning a new GCP Data Science Workstation project? (Y/N)"
read start
if [ "$start" = "Y" ] || [ "$start" = "y" ]; then
  terraform init
  terraform apply
else
  echo "Provisioning cancelled."
fi
You will be prompted for all required secrets and configuration values interactively.
After VM Creation
RDP/SSH Access: Use the external IP and your credentials.
Windows Admin Password:
During terraform apply, you will be prompted for a Windows admin password (or leave blank to auto-generate).
The password will be set automatically using gcloud compute reset-windows-password after the VM is provisioned.
The password (if set) will be output as a sensitive Terraform output. If left blank, check your CLI output for the generated password.
Power BI Installation:
On first login, open Edge/Chrome and download Power BI Desktop from https://powerbi.microsoft.com/desktop
Or run the pre-installed shortcut on the desktop (if available).
Deprovisioning (Cleanup)
To delete all resources, including the VM, disks, and the project itself:

cd terraform
terraform destroy
# Or, to delete the entire project (irreversible!):
echo "Would you like to destroy project NEW_PROJECT_ID and all its dependencies? (yes/no)"
read confirm
if [ "$confirm" = "yes" ]; then
	gcloud projects delete NEW_PROJECT_ID
else
	echo "Project deletion cancelled."
fi
Notes
The attached 50GB SSD disk is mounted as a secondary drive (D:). Use it for data storage.
All network access is restricted to your IP for safety.
Windows Defender is enabled and updated on first boot.
For GPU or more advanced data science needs, edit main.tf to use a GPU-enabled machine type and image.
"
