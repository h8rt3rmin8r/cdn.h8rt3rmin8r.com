#!/usr/bin/env bash

# ==============================================================================
# Script Name: install-docker.sh
# Description: Production-ready Docker installation for Ubuntu Server.
#              Includes verification, verbosity, and fail-safe error handling.
# Author:      h8rt3rmin8r
# ==============================================================================

set -o pipefail  # Fail if any command in a pipe fails

# --- Configuration & Colors ---
readonly LOG_FILE="/var/log/docker_install.log"
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# --- Helper Functions ---

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Description:
  Installs Docker Engine (Community Edition) on Ubuntu Server.
  Performs pre-flight checks, installs dependencies, sets up repositories,
  and verifies the installation.

Options:
  -h, --help    Show this help message and exit.

Examples:
  ./$(basename "$0")
EOF
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Custom Error Handler
# Usage: execute_step "Description of step" "Failure Advice" command [args...]
execute_step() {
    local description="$1"
    local fix_advice="$2"
    shift 2
    local command="$@"

    echo -ne "${BLUE}[Running]${NC} ${description}..."
    
    # Run command, capture output to log file, silence stdout/stderr unless failed
    if eval "$command" >> "$LOG_FILE" 2>&1; then
        echo -e "\r${GREEN}[OK]${NC} ${description}          "
    else
        echo -e "\r${RED}[FAIL]${NC} ${description}          "
        log_error "Step failed: $description"
        log_error "Command executed: $command"
        log_error "Logs available at: $LOG_FILE"
        log_error "Suggested Fix: $fix_advice"
        log_error "Tail of log:"
        tail -n 5 "$LOG_FILE" | sed 's/^/  /'
        exit 1
    fi
}

# --- Main Execution ---

# Parse Arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage; exit 0 ;;
        *) log_error "Unknown parameter: $1"; usage; exit 1 ;;
    esac
    shift
done

# Clear log file
: > "$LOG_FILE"

echo -e "${YELLOW}Starting Docker Installation Script...${NC}"
echo "Logs being written to: $LOG_FILE"
echo "----------------------------------------------------"

# 1. Pre-flight Checks
# We check for sudo upfront so we don't fail halfway through
if ! command -v sudo &> /dev/null; then
    log_error "This script requires 'sudo' which is not installed or found."
    exit 1
fi

# 2. Update Package Index
execute_step "Updating Apt Package Index" \
    "Check your internet connection and DNS settings. Ensure no other apt locks are held." \
    "sudo apt-get update"

# 3. Install Dependencies
# Added lsb-release explicitly to ensure $(lsb_release -cs) works later
execute_step "Installing Prerequisites (ca-certificates, curl, lsb-release)" \
    "Ensure your apt sources are valid. You may need to run 'dpkg --configure -a'." \
    "sudo apt-get install -y ca-certificates curl lsb-release"

# 4. Create Keyrings Directory
execute_step "Creating Keyrings Directory" \
    "Check permissions on /etc/apt. You need root privileges." \
    "sudo install -m 0755 -d /etc/apt/keyrings"

# 5. Add Docker GPG Key
execute_step "Downloading Docker GPG Key" \
    "Unable to reach download.docker.com. Check outbound firewall rules or proxy settings." \
    "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && sudo chmod a+r /etc/apt/keyrings/docker.asc"

# 6. Add Docker Repository
# Using logical substitution for architecture and codename
execute_step "Adding Docker Repository to Apt Sources" \
    "Failed to write to sources.list.d. Verify filesystem is not read-only." \
    "echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null"

# 7. Update Index with New Repo
execute_step "Updating Apt Index with Docker Repo" \
    "The Docker repository URL might be unreachable or the GPG key is invalid. Check /etc/apt/sources.list.d/docker.list." \
    "sudo apt-get update"

# 8. Install Docker Engine
execute_step "Installing Docker Engine & Plugins" \
    "Package installation failed. Check for conflicting packages or broken dependencies." \
    "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"

# 9. Verification
log_info "Verifying Docker Installation..."

if sudo docker run --rm hello-world &>> "$LOG_FILE"; then
    log_success "Docker 'hello-world' container ran successfully!"
else
    log_error "Docker is installed but failed to run the hello-world container."
    log_error "Check if the docker daemon is running: sudo systemctl status docker"
    exit 1
fi

# 10. Post-Installation Steps (User Group)
# Using ${SUDO_USER:-$USER} ensures we grab the actual user if run via sudo
TARGET_USER="${SUDO_USER:-$USER}"

log_info "Configuring non-root access for user: $TARGET_USER"
if sudo usermod -aG docker "$TARGET_USER"; then
    log_success "User $TARGET_USER added to 'docker' group."
    echo -e "${YELLOW}NOTE:${NC} You must log out and back in (or run 'newgrp docker') for group changes to take effect."
else
    log_warn "Failed to add user to docker group. You may need to do this manually: sudo usermod -aG docker $TARGET_USER"
fi

echo "----------------------------------------------------"
log_success "Installation Complete."
