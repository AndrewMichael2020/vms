#!/bin/bash
# Setup script for installing Terraform on Linux systems

set -e

echo "VMS Setup - Installing Terraform"
echo "================================="

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "Error: This script is designed for Linux systems only."
    echo "Please install Terraform manually from: https://www.terraform.io/downloads.html"
    exit 1
fi

# Check if running as root or with sudo access
if [[ $EUID -eq 0 ]]; then
    SUDO=""
elif sudo -n true 2>/dev/null; then
    SUDO="sudo"
else
    echo "Error: This script requires sudo access to install Terraform system-wide."
    echo "Please run with sudo or install Terraform manually."
    exit 1
fi

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        TERRAFORM_ARCH="amd64"
        ;;
    aarch64|arm64)
        TERRAFORM_ARCH="arm64"
        ;;
    i386|i686)
        TERRAFORM_ARCH="386"
        ;;
    *)
        echo "Error: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Set Terraform version
TERRAFORM_VERSION="1.6.6"
TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TERRAFORM_ARCH}.zip"

echo "Installing Terraform ${TERRAFORM_VERSION} for ${TERRAFORM_ARCH}..."

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Download Terraform
echo "Downloading Terraform..."
if command -v wget >/dev/null 2>&1; then
    wget -q "$TERRAFORM_URL" -O terraform.zip
elif command -v curl >/dev/null 2>&1; then
    curl -sL "$TERRAFORM_URL" -o terraform.zip
else
    echo "Error: Neither wget nor curl is available. Please install one of them."
    exit 1
fi

# Verify download
if [[ ! -f terraform.zip ]]; then
    echo "Error: Failed to download Terraform"
    exit 1
fi

# Install unzip if not available
if ! command -v unzip >/dev/null 2>&1; then
    echo "Installing unzip..."
    if command -v apt-get >/dev/null 2>&1; then
        $SUDO apt-get update && $SUDO apt-get install -y unzip
    elif command -v yum >/dev/null 2>&1; then
        $SUDO yum install -y unzip
    elif command -v dnf >/dev/null 2>&1; then
        $SUDO dnf install -y unzip
    else
        echo "Error: Cannot install unzip. Please install it manually."
        exit 1
    fi
fi

# Extract and install
echo "Installing Terraform..."
unzip -q terraform.zip
$SUDO mv terraform /usr/local/bin/

# Verify installation
if command -v terraform >/dev/null 2>&1; then
    echo "✓ Terraform installed successfully!"
    terraform version
else
    echo "Error: Terraform installation failed"
    exit 1
fi

# Cleanup
cd /
rm -rf "$TEMP_DIR"

echo "Setup complete!"