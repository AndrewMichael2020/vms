#!/bin/bash
# VM and Disk Configuration Selection Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                   VMS Configuration Selector                    ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo

# VM options with pricing (approximate, for reference)
VM_OPTIONS=(
    "e2-micro|1 vCPU, 1 GB RAM|$5.11/month|$2.45/month"
    "e2-small|1 vCPU, 2 GB RAM|$10.22/month|$4.91/month"
    "e2-medium|1 vCPU, 4 GB RAM|$20.44/month|$9.81/month"
    "e2-standard-2|2 vCPUs, 8 GB RAM|$40.88/month|$19.63/month"
    "e2-standard-4|4 vCPUs, 16 GB RAM|$81.76/month|$39.25/month"
    "n2-standard-2|2 vCPUs, 8 GB RAM|$58.40/month|$17.52/month"
    "n2-standard-4|4 vCPUs, 16 GB RAM|$116.80/month|$35.04/month"
    "c2-standard-4|4 vCPUs, 16 GB RAM|$144.27/month|$43.28/month"
)

# Disk options with pricing
DISK_OPTIONS=(
    "pd-standard|Standard persistent disk|$0.04/GB/month"
    "pd-balanced|Balanced persistent disk|$0.10/GB/month"
    "pd-ssd|SSD persistent disk|$0.17/GB/month"
)

# Function to display options
display_vm_options() {
    echo -e "${YELLOW}Available VM options:${NC}"
    echo "┌─────┬─────────────────┬─────────────────────┬──────────────┬──────────────┐"
    echo "│ No. │ Machine Type    │ Specifications      │ Regular Cost │ Spot Cost    │"
    echo "├─────┼─────────────────┼─────────────────────┼──────────────┼──────────────┤"
    
    for i in "${!VM_OPTIONS[@]}"; do
        IFS='|' read -ra PARTS <<< "${VM_OPTIONS[$i]}"
        printf "│ %-3d │ %-15s │ %-19s │ %-12s │ %-12s │\n" $((i+1)) "${PARTS[0]}" "${PARTS[1]}" "${PARTS[2]}" "${PARTS[3]}"
    done
    
    echo "└─────┴─────────────────┴─────────────────────┴──────────────┴──────────────┘"
    echo
}

display_disk_options() {
    echo -e "${YELLOW}Available disk options:${NC}"
    echo "┌─────┬─────────────────────┬──────────────────────────────┬─────────────────┐"
    echo "│ No. │ Disk Type           │ Description                  │ Cost            │"
    echo "├─────┼─────────────────────┼──────────────────────────────┼─────────────────┤"
    
    for i in "${!DISK_OPTIONS[@]}"; do
        IFS='|' read -ra PARTS <<< "${DISK_OPTIONS[$i]}"
        printf "│ %-3d │ %-19s │ %-28s │ %-15s │\n" $((i+1)) "${PARTS[0]}" "${PARTS[1]}" "${PARTS[2]}"
    done
    
    echo "└─────┴─────────────────────┴──────────────────────────────┴─────────────────┘"
    echo
}

# Display recommendations
echo -e "${GREEN}💡 Recommendations for most users:${NC}"
echo "   • VM: e2-standard-4 or n2-standard-4 (good balance of performance and cost)"
echo "   • Disk: pd-balanced with 50GB+ (balanced performance and cost)"
echo "   • Consider spot instances for development workloads (60-91% discount)"
echo

# Select VM
display_vm_options
while true; do
    read -p "Select VM option (1-${#VM_OPTIONS[@]}): " vm_choice
    if [[ "$vm_choice" =~ ^[0-9]+$ ]] && [ "$vm_choice" -ge 1 ] && [ "$vm_choice" -le "${#VM_OPTIONS[@]}" ]; then
        break
    else
        echo -e "${RED}Invalid choice. Please select a number between 1 and ${#VM_OPTIONS[@]}.${NC}"
    fi
done

# Extract selected VM details
IFS='|' read -ra SELECTED_VM <<< "${VM_OPTIONS[$((vm_choice-1))]}"
VM_TYPE="${SELECTED_VM[0]}"
VM_SPECS="${SELECTED_VM[1]}"

echo -e "${GREEN}✓ Selected VM: ${VM_TYPE} (${VM_SPECS})${NC}"
echo

# Ask about spot instance
read -p "Use spot instance for significant cost savings? (y/N): " use_spot
if [[ "$use_spot" =~ ^[Yy]$ ]]; then
    PREEMPTIBLE="true"
    echo -e "${GREEN}✓ Using spot instance (preemptible)${NC}"
else
    PREEMPTIBLE="false"
    echo -e "${YELLOW}Using regular instance${NC}"
fi
echo

# Select disk
display_disk_options
while true; do
    read -p "Select disk option (1-${#DISK_OPTIONS[@]}): " disk_choice
    if [[ "$disk_choice" =~ ^[0-9]+$ ]] && [ "$disk_choice" -ge 1 ] && [ "$disk_choice" -le "${#DISK_OPTIONS[@]}" ]; then
        break
    else
        echo -e "${RED}Invalid choice. Please select a number between 1 and ${#DISK_OPTIONS[@]}.${NC}"
    fi
done

# Extract selected disk details
IFS='|' read -ra SELECTED_DISK <<< "${DISK_OPTIONS[$((disk_choice-1))]}"
DISK_TYPE="${SELECTED_DISK[0]}"
DISK_DESC="${SELECTED_DISK[1]}"

echo -e "${GREEN}✓ Selected Disk: ${DISK_TYPE} (${DISK_DESC})${NC}"
echo

# Ask for disk size
while true; do
    read -p "Enter disk size in GB (minimum 50, recommended 100+): " disk_size
    if [[ "$disk_size" =~ ^[0-9]+$ ]] && [ "$disk_size" -ge 50 ]; then
        break
    else
        echo -e "${RED}Invalid size. Please enter a number >= 50.${NC}"
    fi
done

echo -e "${GREEN}✓ Disk size: ${disk_size}GB${NC}"
echo

# Calculate estimated monthly cost
VM_COST=$(echo "${SELECTED_VM[2]}" | grep -o '[0-9.]*')
DISK_COST_PER_GB=$(echo "${SELECTED_DISK[2]}" | grep -o '[0-9.]*')
TOTAL_DISK_COST=$(echo "$disk_size * $DISK_COST_PER_GB" | bc -l)
TOTAL_COST=$(echo "$VM_COST + $TOTAL_DISK_COST" | bc -l)

if [[ "$PREEMPTIBLE" == "true" ]]; then
    SPOT_VM_COST=$(echo "${SELECTED_VM[3]}" | grep -o '[0-9.]*')
    SPOT_TOTAL_COST=$(echo "$SPOT_VM_COST + $TOTAL_DISK_COST" | bc -l)
    echo -e "${BLUE}💰 Estimated monthly cost: \$$(printf "%.2f" $SPOT_TOTAL_COST) (spot instance)${NC}"
else
    echo -e "${BLUE}💰 Estimated monthly cost: \$$(printf "%.2f" $TOTAL_COST)${NC}"
fi
echo

# Create terraform.tfvars
echo -e "${YELLOW}Writing configuration to terraform.tfvars...${NC}"
cat > terraform.tfvars << EOF
# VMS Configuration - Generated by select_config.sh
# $(date)

# VM Configuration
machine_type = "$VM_TYPE"
preemptible = $PREEMPTIBLE

# Disk Configuration  
disk_type = "$DISK_TYPE"
disk_size_gb = $disk_size

# Network Configuration (will be prompted for during terraform apply)
# project_id = "your-project-id"
# billing_account_id = "your-billing-account-id"
# org_id = "your-org-id"
EOF

echo -e "${GREEN}✓ Configuration saved to terraform.tfvars${NC}"
echo
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}Configuration Summary:${NC}"
echo "  VM Type:      $VM_TYPE ($VM_SPECS)"
echo "  Spot Instance: $([ "$PREEMPTIBLE" == "true" ] && echo "Yes" || echo "No")"
echo "  Disk Type:    $DISK_TYPE ($DISK_DESC)"
echo "  Disk Size:    ${disk_size}GB"
if [[ "$PREEMPTIBLE" == "true" ]]; then
    echo "  Est. Cost:    \$$(printf "%.2f" $SPOT_TOTAL_COST)/month (spot)"
else
    echo "  Est. Cost:    \$$(printf "%.2f" $TOTAL_COST)/month"
fi
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Run: python3 vms.py provision"
echo "  2. Follow the prompts to enter your GCP details"
echo "  3. Confirm the deployment when ready"