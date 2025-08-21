#!/bin/bash
# VMS Quick Start Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}VMS Quick Start${NC}"
echo "================="
echo

# Check if Python is available
if ! command -v python3 >/dev/null 2>&1; then
    echo -e "${RED}Error: Python 3 is required but not found.${NC}"
    exit 1
fi

# Quick menu
echo -e "${YELLOW}What would you like to do?${NC}"
echo "1) Setup VMS (install dependencies)"
echo "2) Configure VM options"
echo "3) Provision GCP workstation"
echo "4) Check status"
echo "5) Destroy resources"
echo "0) Exit"
echo

read -p "Select option (0-5): " choice

case $choice in
    1)
        echo -e "${GREEN}Setting up VMS...${NC}"
        python3 vms.py setup
        ;;
    2)
        echo -e "${GREEN}Configuring VM options...${NC}"
        python3 vms.py configure
        ;;
    3)
        echo -e "${GREEN}Provisioning GCP workstation...${NC}"
        python3 vms.py provision
        ;;
    4)
        echo -e "${GREEN}Checking status...${NC}"
        python3 vms.py status
        ;;
    5)
        echo -e "${RED}Destroying resources...${NC}"
        python3 vms.py destroy
        ;;
    0)
        echo -e "${YELLOW}Goodbye!${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option. Please select 0-5.${NC}"
        exit 1
        ;;
esac