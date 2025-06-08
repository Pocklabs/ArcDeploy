#!/bin/bash

# ArcDeploy Common Functions Library
# This file contains shared functions used across all ArcDeploy scripts

# Version and metadata
readonly COMMON_LIB_VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load configuration if available
if [ -f "$PROJECT_ROOT/config/arcdeploy.conf" ]; then
    # shellcheck source=../../config/arcdeploy.conf
    source "$PROJECT_ROOT/config/arcdeploy.conf"
fi

# ============================================================================
# LOGGING AND OUTPUT FUNCTIONS
# ============================================================================

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Log file (use config if available, otherwise default)
readonly LOG_FILE="${SETUP_LOG:-/var/log/arcblock-setup.log}"

# Logging functions
log() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[$timestamp]${NC} $message" | tee -a "$LOG_FILE"
}

error() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR][$timestamp]${NC} $message" | tee -a "$LOG_FILE" >&2
}

success() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[SUCCESS][$timestamp]${NC} $message" | tee -a "$LOG_FILE"
}

warning() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[WARNING][$timestamp]${NC} $message" | tee -a "$LOG_FILE"
}

info() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${CYAN}[INFO][$timestamp]${NC} $message" | tee -a "$LOG_FILE"
}

debug() {
    local message="$1"
    if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
        local timestamp
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo -e "${PURPLE}[DEBUG][$timestamp]${NC} $message" | tee -a "$LOG_FILE"
    fi
}

# Progress indicators
show_progress() {
    local current="$1"
    local total="$2"
    local description="$3"
    local percentage=$((current * 100 / total))
    printf "\r${BLUE}[%3d%%]${NC} %s" "$percentage" "$description"
    if [ "$current" -eq "$total" ]; then
        echo ""
    fi
}

# Section headers
section_header() {
    local title="$1"
    local width=60
    local padding=$(( (width - ${#title}) / 2 ))
    
    echo ""
    echo -e "${WHITE}$(printf '=%.0s' $(seq 1 $width))${NC}"
    echo -e "${WHITE}$(printf '%*s' $padding '')$title$(printf '%*s' $padding '')${NC}"
    echo -e "${WHITE}$(printf '=%.0s' $(seq 1 $width))${NC}"
    echo ""
}

# ============================================================================
# ERROR HANDLING FUNCTIONS
# ============================================================================

# Error handling
error_exit() {
    local message="$1"
    local exit_code="${2:-1}"
    error "$message"
    exit "$exit_code"
}

# Trap error handler
trap_error() {
    local line_number="$1"
    local command="$2"
    local exit_code="$3"
    error "Script failed at line $line_number: '$command' (exit code: $exit_code)"
}

# Set up error trapping
setup_error_handling() {
    set -euo pipefail
    trap 'trap_error ${LINENO} "$BASH_COMMAND" $?' ERR
}

# Cleanup function
cleanup() {
    local temp_files=("$@")
    for file in "${temp_files[@]}"; do
        if [ -f "$file" ]; then
            rm -f "$file"
            debug "Cleaned up temporary file: $file"
        fi
    done
}

# ============================================================================
# SYSTEM VALIDATION FUNCTIONS
# ============================================================================

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "This script must be run as root"
    fi
}

# Check if running as specific user
check_user() {
    local required_user="$1"
    local current_user
    current_user=$(whoami)
    if [ "$current_user" != "$required_user" ]; then
        error_exit "This script must be run as user: $required_user (current: $current_user)"
    fi
}

# Check system requirements
check_system_requirements() {
    local min_ram_gb="${MIN_RAM_GB:-4}"
    local min_disk_gb="${MIN_DISK_GB:-40}"
    local min_cpu_cores="${MIN_CPU_CORES:-2}"
    
    # Check RAM
    local total_ram_gb
    total_ram_gb=$(free -g | awk 'NR==2{print $2}')
    if [ "$total_ram_gb" -lt "$min_ram_gb" ]; then
        warning "RAM: ${total_ram_gb}GB (minimum: ${min_ram_gb}GB)"
    else
        success "RAM: ${total_ram_gb}GB (meets requirements)"
    fi
    
    # Check disk space
    local total_disk_gb
    total_disk_gb=$(df / | awk 'NR==2 {print int($2/1024/1024)}')
    if [ "$total_disk_gb" -lt "$min_disk_gb" ]; then
        warning "Disk: ${total_disk_gb}GB (minimum: ${min_disk_gb}GB)"
    else
        success "Disk: ${total_disk_gb}GB (meets requirements)"
    fi
    
    # Check CPU cores
    local cpu_cores
    cpu_cores=$(nproc)
    if [ "$cpu_cores" -lt "$min_cpu_cores" ]; then
        warning "CPU cores: $cpu_cores (minimum: $min_cpu_cores)"
    else
        success "CPU cores: $cpu_cores (meets requirements)"
    fi
}

# Check if command exists
command_exists() {
    local command="$1"
    command -v "$command" >/dev/null 2>&1
}

# Check if service exists
service_exists() {
    local service="$1"
    systemctl list-unit-files | grep -q "^$service"
}

# Check if port is available
port_available() {
    local port="$1"
    ! netstat -tlnp 2>/dev/null | grep -q ":$port "
}

# Check if port is listening
port_listening() {
    local port="$1"
    netstat -tlnp 2>/dev/null | grep -q ":$port "
}

# ============================================================================
# PACKAGE MANAGEMENT FUNCTIONS
# ============================================================================

# Update package lists
update_packages() {
    log "Updating package lists..."
    if command_exists apt-get; then
        apt-get update || error_exit "Failed to update package lists"
    elif command_exists yum; then
        yum update -y || error_exit "Failed to update package lists"
    else
        error_exit "Unsupported package manager"
    fi
    success "Package lists updated"
}

# Install package
install_package() {
    local package="$1"
    local description="${2:-$package}"
    
    log "Installing $description..."
    if command_exists apt-get; then
        apt-get install -y "$package" || error_exit "Failed to install $package"
    elif command_exists yum; then
        yum install -y "$package" || error_exit "Failed to install $package"
    else
        error_exit "Unsupported package manager"
    fi
    success "$description installed"
}

# Install multiple packages
install_packages() {
    local packages=("$@")
    log "Installing packages: ${packages[*]}"
    
    if command_exists apt-get; then
        apt-get install -y "${packages[@]}" || error_exit "Failed to install packages"
    elif command_exists yum; then
        yum install -y "${packages[@]}" || error_exit "Failed to install packages"
    else
        error_exit "Unsupported package manager"
    fi
    success "All packages installed"
}

# ============================================================================
# SERVICE MANAGEMENT FUNCTIONS
# ============================================================================

# Enable and start service
enable_start_service() {
    local service="$1"
    log "Enabling and starting $service service..."
    
    systemctl enable "$service" || error_exit "Failed to enable $service"
    systemctl start "$service" || error_exit "Failed to start $service"
    
    success "$service service enabled and started"
}

# Check service status
check_service_status() {
    local service="$1"
    local description="${2:-$service}"
    
    if systemctl is-active --quiet "$service"; then
        success "$description service is running"
        return 0
    else
        error "$description service is not running"
        return 1
    fi
}

# Wait for service to be ready
wait_for_service() {
    local service="$1"
    local max_attempts="${2:-30}"
    local sleep_interval="${3:-2}"
    local description="${4:-$service}"
    
    log "Waiting for $description to be ready..."
    
    local attempts=0
    while [ $attempts -lt $max_attempts ]; do
        if systemctl is-active --quiet "$service"; then
            success "$description is ready"
            return 0
        fi
        
        attempts=$((attempts + 1))
        debug "Attempt $attempts/$max_attempts - waiting ${sleep_interval}s..."
        sleep "$sleep_interval"
    done
    
    error "$description did not become ready within $((max_attempts * sleep_interval)) seconds"
    return 1
}

# ============================================================================
# NETWORK FUNCTIONS
# ============================================================================

# Test HTTP endpoint
test_http_endpoint() {
    local url="$1"
    local timeout="${2:-10}"
    local description="${3:-$url}"
    
    if curl -sf --max-time "$timeout" "$url" >/dev/null 2>&1; then
        success "$description is responding"
        return 0
    else
        error "$description is not responding"
        return 1
    fi
}

# Wait for HTTP endpoint
wait_for_http_endpoint() {
    local url="$1"
    local max_attempts="${2:-30}"
    local sleep_interval="${3:-5}"
    local timeout="${4:-10}"
    local description="${5:-$url}"
    
    log "Waiting for $description to respond..."
    
    local attempts=0
    while [ $attempts -lt $max_attempts ]; do
        if curl -sf --max-time "$timeout" "$url" >/dev/null 2>&1; then
            success "$description is responding"
            return 0
        fi
        
        attempts=$((attempts + 1))
        debug "Attempt $attempts/$max_attempts - waiting ${sleep_interval}s..."
        sleep "$sleep_interval"
    done
    
    error "$description did not respond within $((max_attempts * sleep_interval)) seconds"
    return 1
}

# Get server IP
get_server_ip() {
    hostname -I | awk '{print $1}' || echo "127.0.0.1"
}

# ============================================================================
# USER MANAGEMENT FUNCTIONS
# ============================================================================

# Create user if not exists
create_user_if_not_exists() {
    local username="$1"
    local groups="${2:-users}"
    local shell="${3:-/bin/bash}"
    
    if ! id "$username" &>/dev/null; then
        log "Creating user: $username"
        useradd -m -G "$groups" -s "$shell" "$username" || error_exit "Failed to create user: $username"
        success "User $username created"
    else
        info "User $username already exists"
    fi
}

# Set user sudo privileges
set_user_sudo() {
    local username="$1"
    local sudo_rule="${2:-ALL=(ALL) NOPASSWD:ALL}"
    
    echo "$username $sudo_rule" > "/etc/sudoers.d/$username" || error_exit "Failed to set sudo privileges for $username"
    success "Sudo privileges set for $username"
}

# ============================================================================
# FILE SYSTEM FUNCTIONS
# ============================================================================

# Create directory with proper ownership
create_directory_with_ownership() {
    local dir_path="$1"
    local owner="${2:-root:root}"
    local permissions="${3:-755}"
    
    mkdir -p "$dir_path" || error_exit "Failed to create directory: $dir_path"
    chown "$owner" "$dir_path" || error_exit "Failed to set ownership for: $dir_path"
    chmod "$permissions" "$dir_path" || error_exit "Failed to set permissions for: $dir_path"
    
    debug "Created directory: $dir_path ($owner, $permissions)"
}

# Backup file
backup_file() {
    local file_path="$1"
    local backup_suffix="${2:-.backup.$(date +%Y%m%d_%H%M%S)}"
    
    if [ -f "$file_path" ]; then
        cp "$file_path" "${file_path}${backup_suffix}" || error_exit "Failed to backup $file_path"
        info "Backed up $file_path to ${file_path}${backup_suffix}"
    fi
}

# ============================================================================
# CONFIGURATION FUNCTIONS
# ============================================================================

# Load environment variables from config
load_config() {
    local config_file="${1:-$PROJECT_ROOT/config/arcdeploy.conf}"
    
    if [ -f "$config_file" ]; then
        # shellcheck source=/dev/null
        source "$config_file"
        debug "Loaded configuration from: $config_file"
    else
        warning "Configuration file not found: $config_file"
    fi
}

# Validate configuration
validate_config() {
    local required_vars=(
        "USER_NAME"
        "BLOCKLET_BASE_DIR"
        "SSH_PORT"
        "BLOCKLET_HTTP_PORT"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            error_exit "Required configuration variable not set: $var"
        fi
    done
    
    success "Configuration validation passed"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Generate random string
generate_random_string() {
    local length="${1:-32}"
    openssl rand -hex "$((length/2))" 2>/dev/null || head -c "$length" /dev/urandom | base64 | tr -d '=+/' | cut -c1-"$length"
}

# Check if value is in array
in_array() {
    local value="$1"
    shift
    local array=("$@")
    
    for item in "${array[@]}"; do
        if [ "$item" = "$value" ]; then
            return 0
        fi
    done
    return 1
}

# Retry command with backoff
retry_with_backoff() {
    local max_attempts="$1"
    local delay="$2"
    local command=("${@:3}")
    
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        if "${command[@]}"; then
            return 0
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            warning "Command failed (attempt $attempt/$max_attempts), retrying in ${delay}s..."
            sleep "$delay"
            delay=$((delay * 2))  # Exponential backoff
        fi
        
        attempt=$((attempt + 1))
    done
    
    error "Command failed after $max_attempts attempts: ${command[*]}"
    return 1
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# Initialize common library
init_common_lib() {
    # Ensure log directory exists
    local log_dir
    log_dir=$(dirname "$LOG_FILE")
    mkdir -p "$log_dir" 2>/dev/null || true
    
    # Set up error handling if not disabled
    if [[ "${DISABLE_ERROR_HANDLING:-false}" != "true" ]]; then
        setup_error_handling
    fi
    
    # Load configuration
    load_config
    
    debug "Common library v$COMMON_LIB_VERSION initialized"
}

# Auto-initialize when sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    init_common_lib
fi