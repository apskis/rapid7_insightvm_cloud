#!/bin/bash
# Version: 1.2
# Install the Asset Custom Object for Rapid7 InsightVM Cloud Integration
# This script checks if the Asset object already exists before installing
# Compatible with ThreatQ 5.x installations

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo "=================================================="
    echo "$1"
    echo "=================================================="
    echo ""
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

print_header "Rapid7 InsightVM Cloud - Asset Object Installer"

# Detect ThreatQ version
detect_threatq_version() {
    if [ -d "/opt/threatq" ]; then
        THREATQ_VERSION="6"
        API_PATH="/opt/threatq"
        print_info "Detected ThreatQ 6.x installation"
    elif [ -d "/var/www/api" ]; then
        THREATQ_VERSION="5"
        API_PATH="/var/www/api"
        print_info "Detected ThreatQ 5.x installation"
    else
        print_error "Could not detect ThreatQ installation"
        print_error "Expected /var/www/api (5.x) or /opt/threatq (6.x)"
        exit 1
    fi
}

# Determine log directory
if [ -z "$1" ]; then
    LOG_DIR="/var/log/threatq"
    print_info "No log directory specified, using default: ${LOG_DIR}"
else
    LOG_DIR="$1"
    print_info "Using log directory: ${LOG_DIR}"
fi

# Create log directory if it doesn't exist
mkdir -p "${LOG_DIR}"

LOG_FILE="${LOG_DIR}/asset_object_install_$(date +%Y%m%d_%H%M%S).log"
print_info "Log file: ${LOG_FILE}"

# Get the directory where this script is located
SCRIPT_DIR=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )
print_info "Script directory: ${SCRIPT_DIR}"

# Detect ThreatQ version
detect_threatq_version

# Function to check if Asset object exists
check_asset_object_exists() {
    print_info "Checking if Asset custom object already exists..."
    
    # Query the database to check for asset object
    if [ "$THREATQ_VERSION" = "5" ]; then
        ASSET_EXISTS=$(cd /var/www/api && php artisan tinker --execute="echo \App\Models\ObjectType::where('code', 'asset')->exists() ? 'true' : 'false';" 2>/dev/null || echo "error")
    else
        # For ThreatQ 6.x, use kubectl
        ASSET_EXISTS=$(kubectl exec -n threatq deployment/threatq-api -- php artisan tinker --execute="echo \App\Models\ObjectType::where('code', 'asset')->exists() ? 'true' : 'false';" 2>/dev/null || echo "error")
    fi
    
    if [ "$ASSET_EXISTS" = "error" ]; then
        print_warning "Could not query database, will attempt installation anyway"
        return 1
    elif [ "$ASSET_EXISTS" = "true" ]; then
        return 0
    else
        return 1
    fi
}

# Function to verify required files exist
verify_files() {
    print_info "Verifying required files..."
    
    local missing_files=0
    
    if [ ! -f "${SCRIPT_DIR}/asset.json" ]; then
        print_error "Missing: asset.json"
        missing_files=1
    else
        print_success "Found: asset.json"
    fi
    
    if [ ! -f "${SCRIPT_DIR}/images/asset.svg" ]; then
        print_error "Missing: images/asset.svg"
        missing_files=1
    else
        print_success "Found: images/asset.svg"
    fi
    
    if [ $missing_files -eq 1 ]; then
        print_error "Required files are missing. Please ensure all files are in the correct location."
        exit 1
    fi
    
    print_success "All required files found"
}

# Function to create backup
create_backup() {
    print_info "Creating backup of existing custom objects..."
    BACKUP_DIR="/var/backups/threatq/custom_objects_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "${BACKUP_DIR}"
    
    if [ "$THREATQ_VERSION" = "5" ]; then
        if [ -d "/var/www/api/database/seeds/data/custom_objects" ]; then
            cp -r /var/www/api/database/seeds/data/custom_objects/* "${BACKUP_DIR}/" 2>/dev/null || true
            print_success "Backup created at: ${BACKUP_DIR}"
        fi
    else
        print_info "Backup not applicable for ThreatQ 6.x"
    fi
}

# ThreatQ 5.x installation process
install_threatq_5x() {
    # Step 1: Enter Maintenance Mode
    print_header "Step 1 of 6: Entering Maintenance Mode"
    print_warning "ThreatQ will be temporarily unavailable to users"
    /var/www/api/artisan down >> "${LOG_FILE}" 2>&1
    print_success "Maintenance mode enabled"
    
    # Ensure we exit maintenance mode on script exit (even if error)
    trap '/var/www/api/artisan up >> "${LOG_FILE}" 2>&1; print_info "Maintenance mode disabled"' EXIT
    
    # Step 2: Copy Files
    print_header "Step 2 of 6: Copying Asset Custom Object Files"
    
    # Create directories if they don't exist
    mkdir -p /var/www/api/database/seeds/data/icons/images/custom_objects/
    mkdir -p /var/www/api/database/seeds/data/custom_objects/
    
    # Copy with verbose output
    if cp -v "${SCRIPT_DIR}/images/asset.svg" /var/www/api/database/seeds/data/icons/images/custom_objects/ >> "${LOG_FILE}" 2>&1; then
        print_success "Copied asset.svg"
    else
        print_error "Failed to copy asset.svg"
        exit 1
    fi
    
    if cp -v "${SCRIPT_DIR}/asset.json" /var/www/api/database/seeds/data/custom_objects/ >> "${LOG_FILE}" 2>&1; then
        print_success "Copied asset.json"
    else
        print_error "Failed to copy asset.json"
        exit 1
    fi
    
    # Step 3: Install Custom Object
    print_header "Step 3 of 6: Installing Asset Custom Object"
    print_info "This may take a moment..."
    
    if /var/www/api/artisan threatq:make-object-set --file=/var/www/api/database/seeds/data/custom_objects/asset.json >> "${LOG_FILE}" 2>&1; then
        print_success "Asset custom object installed"
    else
        print_error "Failed to install asset custom object - check log file"
        exit 1
    fi
    
    # Step 4: Configure Icon
    print_header "Step 4 of 6: Configuring Asset Icon"
    
    if /var/www/api/artisan threatq:object-settings --code=asset --icon=/var/www/api/database/seeds/data/icons/images/custom_objects/asset.svg >> "${LOG_FILE}" 2>&1; then
        print_success "Icon configured"
    else
        print_error "Failed to configure icon - check log file"
        exit 1
    fi
    
    # Step 5: Update Permissions
    print_header "Step 5 of 6: Updating ThreatQ Permissions"
    print_info "This may take a moment..."
    
    if /var/www/api/artisan threatq:update-permissions >> "${LOG_FILE}" 2>&1; then
        print_success "Permissions updated"
    else
        print_error "Failed to update permissions - check log file"
        exit 1
    fi
    
    # Step 6: Restart Services
    print_header "Step 6 of 6: Restarting ThreatQ Services"
    
    if systemctl restart threatq-dynamo >> "${LOG_FILE}" 2>&1; then
        print_success "Services restarted"
    else
        print_warning "Failed to restart threatq-dynamo - you may need to restart manually"
    fi
}

# ThreatQ 6.x installation process
install_threatq_6x() {
    print_error "ThreatQ 6.x detected - Custom object installation must be done through the ThreatQ UI"
    print_info ""
    print_info "To install the Asset custom object in ThreatQ 6.x:"
    print_info "1. Log into ThreatQ as an administrator"
    print_info "2. Navigate to System Configuration > Object Management > Custom Objects"
    print_info "3. Click 'Add Custom Object'"
    print_info "4. Fill in the following details:"
    print_info "   - Code: asset"
    print_info "   - Name: Assets"
    print_info "   - Description: An object defining an asset of an organization"
    print_info "   - Foreground Color: #ffffff"
    print_info "   - Background Color: #db4e4e"
    print_info "5. Add a 'Title' field (varchar 255, required)"
    print_info "6. Add a 'Description' field (text, optional)"
    print_info "7. Upload the asset.svg icon from: ${SCRIPT_DIR}/images/asset.svg"
    print_info "8. Save the custom object"
    print_info ""
    exit 1
}

# Main installation process
main() {
    # Log start time
    echo "Installation started at: $(date)" >> "${LOG_FILE}"
    echo "ThreatQ Version: ${THREATQ_VERSION}.x" >> "${LOG_FILE}"
    
    # Verify files exist
    verify_files
    
    # Check if Asset object already exists
    if check_asset_object_exists; then
        print_success "Asset custom object already exists in ThreatQ!"
        print_info "Skipping installation - no changes needed."
        echo "Asset object already exists - skipped installation" >> "${LOG_FILE}"
        print_header "Installation Complete - No Action Needed"
        exit 0
    fi
    
    print_info "Asset custom object not found - proceeding with installation..."
    
    # Create backup
    create_backup
    
    # Install based on version
    if [ "$THREATQ_VERSION" = "5" ]; then
        install_threatq_5x
    else
        install_threatq_6x
    fi
    
    # Log completion
    echo "Installation completed successfully at: $(date)" >> "${LOG_FILE}"
    
    # Final success message
    print_header "Installation Complete!"
    print_success "Asset custom object has been successfully installed"
    print_info "Log file: ${LOG_FILE}"
    print_info ""
    print_info "Next steps:"
    print_info "1. Log into ThreatQ (may need to refresh browser)"
    print_info "2. Verify 'Asset' appears in object type dropdown"
    print_info "3. Upload and configure the rapid7_insightvm_cloud.yaml integration"
    print_info "4. Configure the integration with your Rapid7 API key and base URL"
    print_info "5. Enable the integration to start ingesting assets"
    print_info ""
}

# Run main installation
main

exit 0