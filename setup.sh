#!/bin/bash
# VMS Setup Script - Install Terraform on Linux

set -e

echo "🚀 VMS Setup: Installing Terraform..."

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "❌ This script is designed for Linux systems only."
    exit 1
fi

# Check if terraform is already installed
if command -v terraform &> /dev/null; then
    echo "✅ Terraform is already installed:"
    terraform --version
    read -p "Do you want to reinstall/update? (y/N): " reinstall
    if [[ $reinstall != "y" && $reinstall != "Y" ]]; then
        echo "Skipping Terraform installation."
        exit 0
    fi
fi

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64) TF_ARCH="amd64" ;;
    aarch64) TF_ARCH="arm64" ;;
    armv7l) TF_ARCH="arm" ;;
    *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Get latest Terraform version
echo "📡 Fetching latest Terraform version..."
TF_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep '"tag_name":' | cut -d'"' -f4 | sed 's/v//')

if [[ -z "$TF_VERSION" ]]; then
    echo "❌ Failed to fetch latest Terraform version. Using fallback version 1.6.0"
    TF_VERSION="1.6.0"
fi

echo "📦 Downloading Terraform v$TF_VERSION for $TF_ARCH..."

# Create temporary directory
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

# Download and verify
wget -q "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_${TF_ARCH}.zip"

# Extract and install
unzip -q terraform_${TF_VERSION}_linux_${TF_ARCH}.zip

# Check if user has sudo access
if sudo -n true 2>/dev/null; then
    echo "🔐 Installing Terraform to /usr/local/bin (requires sudo)..."
    sudo mv terraform /usr/local/bin/
else
    echo "🏠 Installing Terraform to ~/.local/bin..."
    mkdir -p ~/.local/bin
    mv terraform ~/.local/bin/
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo "📝 Adding ~/.local/bin to PATH in ~/.bashrc"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        echo "⚠️  Please run: source ~/.bashrc or restart your terminal"
    fi
fi

# Cleanup
cd /
rm -rf "$TMP_DIR"

# Verify installation
if command -v terraform &> /dev/null; then
    echo "✅ Terraform installation completed successfully!"
    terraform --version
else
    echo "❌ Terraform installation failed. Please check your PATH."
    exit 1
fi

echo ""
echo "🎉 Setup complete! You can now use the VMS CLI application."
echo "📖 Next steps:"
echo "   1. Install Python requirements: pip install -r requirements.txt"
echo "   2. Run the VMS CLI: python vms.py"