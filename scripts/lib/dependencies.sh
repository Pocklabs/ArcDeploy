#!/bin/bash

# ArcDeploy Dependency Management System
# This library manages software dependencies, versions, and compatibility checks

readonly DEPS_LIB_VERSION="1.0.0"
# Only set if not already set to avoid readonly errors
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    readonly SCRIPT_DIR
fi

if [[ -z "${PROJECT_ROOT:-}" ]]; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    readonly PROJECT_ROOT
fi
readonly DEPS_CACHE_DIR="/tmp/arcdeploy-deps-cache"
readonly DEPS_LOG_FILE="/var/log/arcdeploy-dependencies.log"
export DEPS_LOG_FILE

# Load common library if available
if [ -f "$SCRIPT_DIR/common.sh" ]; then
    # shellcheck source=./common.sh
    source "$SCRIPT_DIR/common.sh"
fi

# ============================================================================
# DEPENDENCY DEFINITIONS
# ============================================================================

# Core system dependencies
declare -A SYSTEM_DEPS=(
    ["curl"]="required:7.0.0:latest:HTTP client for downloads"
    ["wget"]="required:1.19.0:latest:Alternative HTTP client"
    ["git"]="required:2.20.0:latest:Version control system"
    ["systemctl"]="required:systemd:latest:Service management"
    ["ufw"]="required:0.36.0:latest:Firewall management"
    ["nginx"]="required:1.18.0:latest:Web server and reverse proxy"
    ["redis-server"]="required:5.0.0:latest:In-memory data store"
    ["fail2ban"]="optional:0.11.0:latest:Intrusion prevention system"
    ["python3"]="required:3.8.0:latest:Python runtime"
    ["jq"]="required:1.6.0:latest:JSON processor"
)

# Node.js ecosystem dependencies
declare -A NODEJS_DEPS=(
    ["node"]="required:16.0.0:lts:JavaScript runtime"
    ["npm"]="required:8.0.0:latest:Node package manager"
    ["@blocklet/cli"]="required:1.0.0:latest:Blocklet CLI tool"
)

# Cloud provider specific dependencies
declare -A CLOUD_DEPS=(
    ["aws"]="optional:2.0.0:latest:AWS CLI"
    ["gcloud"]="optional:400.0.0:latest:Google Cloud CLI"
    ["az"]="optional:2.30.0:latest:Azure CLI"
    ["doctl"]="optional:1.70.0:latest:DigitalOcean CLI"
)
export CLOUD_DEPS

# Security and monitoring tools
declare -A SECURITY_DEPS=(
    ["certbot"]="optional:1.20.0:latest:SSL certificate management"
    ["htop"]="optional:3.0.0:latest:System monitoring"
    ["netstat"]="required:net-tools:latest:Network utilities"
    ["ss"]="required:iproute2:latest:Socket statistics"
)

# ============================================================================
# DEPENDENCY MANAGEMENT FUNCTIONS
# ============================================================================

# Initialize dependency cache
init_deps_cache() {
    mkdir -p "$DEPS_CACHE_DIR"
    debug "Dependency cache initialized: $DEPS_CACHE_DIR"
}

# Parse dependency specification
parse_dep_spec() {
    local dep_spec="$1"
    local priority min_version max_version description
    
    IFS=':' read -r priority min_version max_version description <<< "$dep_spec"
    
    echo "$priority|$min_version|$max_version|$description"
}

# Check if command exists and get version
get_command_version() {
    local command="$1"
    local version_output
    
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "not_installed"
        return 1
    fi
    
    # Try common version flags
    for flag in "--version" "-v" "-V" "version"; do
        if version_output=$($command $flag 2>/dev/null); then
            # Extract version number using various patterns
            echo "$version_output" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1
            if [[ ${PIPESTATUS[1]} -eq 0 ]]; then
                return 0
            fi
        fi
    done
    
    # Special cases for specific commands
    case "$command" in
        "systemctl")
            if systemctl --version >/dev/null 2>&1; then
                systemctl --version | grep -oE '[0-9]+' | head -n1
                return 0
            fi
            ;;
        "nginx")
            if nginx -v 2>&1 | grep -q "nginx"; then
                nginx -v 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?'
                return 0
            fi
            ;;
        "redis-server")
            if redis-server --version 2>/dev/null | grep -q "Redis"; then
                redis-server --version | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?'
                return 0
            fi
            ;;
    esac
    
    echo "unknown"
    return 0
}

# Compare version strings
version_compare() {
    local version1="$1"
    local operator="$2"
    local version2="$3"
    
    # Handle special cases
    if [ "$version1" = "not_installed" ] || [ "$version2" = "not_installed" ]; then
        return 1
    fi
    
    if [ "$version1" = "unknown" ] || [ "$version2" = "unknown" ]; then
        warning "Cannot compare unknown version"
        return 0  # Assume compatible for unknown versions
    fi
    
    # Convert versions to comparable format
    local v1_normalized v2_normalized
    v1_normalized=$(echo "$version1" | awk -F. '{printf "%03d%03d%03d", $1, $2, $3}')
    v2_normalized=$(echo "$version2" | awk -F. '{printf "%03d%03d%03d", $1, $2, $3}')
    
    case "$operator" in
        ">=")
            [ "$v1_normalized" -ge "$v2_normalized" ]
            ;;
        "<=")
            [ "$v1_normalized" -le "$v2_normalized" ]
            ;;
        ">")
            [ "$v1_normalized" -gt "$v2_normalized" ]
            ;;
        "<")
            [ "$v1_normalized" -lt "$v2_normalized" ]
            ;;
        "="|"==")
            [ "$v1_normalized" -eq "$v2_normalized" ]
            ;;
        *)
            error "Unknown version comparison operator: $operator"
            return 1
            ;;
    esac
}

# Check single dependency
check_dependency() {
    local dep_name="$1"
    local dep_spec="$2"
    local result_var="$3"
    
    local priority min_version max_version description
    IFS='|' read -r priority min_version max_version description <<< "$(parse_dep_spec "$dep_spec")"
    
    local current_version status message
    current_version=$(get_command_version "$dep_name")
    
    case "$current_version" in
        "not_installed")
            if [ "$priority" = "required" ]; then
                status="missing_required"
                message="Required dependency not installed: $dep_name"
            else
                status="missing_optional"
                message="Optional dependency not installed: $dep_name"
            fi
            ;;
        "unknown")
            status="version_unknown"
            message="Cannot determine version for: $dep_name"
            ;;
        *)
            # Check version compatibility
            local version_ok=true
            
            if [ "$min_version" != "latest" ] && [ "$min_version" != "systemd" ] && [ "$min_version" != "net-tools" ] && [ "$min_version" != "iproute2" ]; then
                if ! version_compare "$current_version" ">=" "$min_version"; then
                    version_ok=false
                fi
            fi
            
            if [ "$max_version" != "latest" ] && [ "$version_ok" = true ]; then
                if ! version_compare "$current_version" "<=" "$max_version"; then
                    version_ok=false
                fi
            fi
            
            if [ "$version_ok" = true ]; then
                status="satisfied"
                message="Dependency satisfied: $dep_name v$current_version"
            else
                if [ "$priority" = "required" ]; then
                    status="version_mismatch_required"
                    message="Version mismatch for required dependency: $dep_name (current: $current_version, required: $min_version-$max_version)"
                else
                    status="version_mismatch_optional"
                    message="Version mismatch for optional dependency: $dep_name (current: $current_version, recommended: $min_version-$max_version)"
                fi
            fi
            ;;
    esac
    
    # Store result in associative array format
    if [ -n "$result_var" ]; then
        eval "${result_var}[name]=\"$dep_name\""
        eval "${result_var}[status]=\"$status\""
        eval "${result_var}[current_version]=\"$current_version\""
        eval "${result_var}[min_version]=\"$min_version\""
        eval "${result_var}[max_version]=\"$max_version\""
        eval "${result_var}[priority]=\"$priority\""
        eval "${result_var}[description]=\"$description\""
        eval "${result_var}[message]=\"$message\""
    fi
    
    # Log result
    case "$status" in
        "satisfied")
            debug "$message"
            return 0
            ;;
        "missing_optional"|"version_mismatch_optional"|"version_unknown")
            warning "$message"
            return 0
            ;;
        "missing_required"|"version_mismatch_required")
            error "$message"
            return 1
            ;;
    esac
}

# Check all dependencies in a category
check_dependency_category() {
    local category_name="$1"
    local deps_array_name="$2"
    local results_var="$3"
    
    log "Checking $category_name dependencies..."
    
    local -n deps_ref="$deps_array_name"
    local dep_name dep_spec
    local checked=0 satisfied=0 missing_required=0 missing_optional=0 version_issues=0
    
    for dep_name in "${!deps_ref[@]}"; do
        dep_spec="${deps_ref[$dep_name]}"
        
        local -A result
        if check_dependency "$dep_name" "$dep_spec" "result"; then
            case "${result[status]}" in
                "satisfied")
                    ((satisfied++))
                    ;;
                "missing_optional"|"version_mismatch_optional")
                    ((missing_optional++))
                    ;;
                "version_unknown")
                    ((version_issues++))
                    ;;
            esac
        else
            case "${result[status]}" in
                "missing_required")
                    ((missing_required++))
                    ;;
                "version_mismatch_required")
                    ((version_issues++))
                    ;;
            esac
        fi
        
        ((checked++))
        
        # Store individual results if results_var is provided
        if [ -n "$results_var" ]; then
            local result_key="${results_var}[${category_name}_${dep_name}]"
            for key in "${!result[@]}"; do
                eval "${result_key}_${key}=\"${result[$key]}\""
            done
        fi
    done
    
    # Summary
    log "$category_name summary: $checked checked, $satisfied satisfied, $missing_required missing (required), $missing_optional missing (optional), $version_issues version issues"
    
    return $missing_required
}

# Install missing system packages
install_system_package() {
    local package="$1"
    local description="${2:-$package}"
    
    log "Installing $description..."
    
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -qq
        apt-get install -y "$package" || {
            error "Failed to install $package via apt-get"
            return 1
        }
    elif command -v yum >/dev/null 2>&1; then
        yum install -y "$package" || {
            error "Failed to install $package via yum"
            return 1
        }
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y "$package" || {
            error "Failed to install $package via dnf"
            return 1
        }
    elif command -v pacman >/dev/null 2>&1; then
        pacman -S --noconfirm "$package" || {
            error "Failed to install $package via pacman"
            return 1
        }
    else
        error "No supported package manager found"
        return 1
    fi
    
    success "$description installed successfully"
    return 0
}

# Install Node.js dependencies
install_nodejs_deps() {
    log "Installing Node.js dependencies..."
    
    # Install Node.js LTS if not present
    if ! command -v node >/dev/null 2>&1; then
        log "Installing Node.js LTS..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
        install_system_package "nodejs" "Node.js LTS"
    fi
    
    # Install global npm packages
    for dep_name in "${!NODEJS_DEPS[@]}"; do
        if [[ "$dep_name" == "@"* ]]; then
            # Global npm package
            local current_version
            current_version=$(npm list -g "$dep_name" --depth=0 2>/dev/null | grep "$dep_name" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "not_installed")
            
            if [ "$current_version" = "not_installed" ]; then
                log "Installing global npm package: $dep_name"
                npm install -g "$dep_name" || {
                    error "Failed to install $dep_name"
                    return 1
                }
                success "$dep_name installed successfully"
            fi
        fi
    done
    
    return 0
}

# Auto-fix dependency issues
auto_fix_dependencies() {
    local category="$1"
    local fix_optional="${2:-false}"
    
    log "Auto-fixing dependencies for category: $category"
    
    case "$category" in
        "system")
            for dep_name in "${!SYSTEM_DEPS[@]}"; do
                local dep_spec="${SYSTEM_DEPS[$dep_name]}"
                local -A result
                
                if ! check_dependency "$dep_name" "$dep_spec" "result"; then
                    if [ "${result[priority]}" = "required" ] || [ "$fix_optional" = "true" ]; then
                        case "${result[status]}" in
                            "missing_required"|"missing_optional")
                                install_system_package "$dep_name" "${result[description]}"
                                ;;
                        esac
                    fi
                fi
            done
            ;;
        "nodejs")
            install_nodejs_deps
            ;;
        "security")
            for dep_name in "${!SECURITY_DEPS[@]}"; do
                local dep_spec="${SECURITY_DEPS[$dep_name]}"
                local -A result
                
                if ! check_dependency "$dep_name" "$dep_spec" "result"; then
                    if [ "${result[priority]}" = "required" ] || [ "$fix_optional" = "true" ]; then
                        case "${result[status]}" in
                            "missing_required"|"missing_optional")
                                install_system_package "$dep_name" "${result[description]}"
                                ;;
                        esac
                    fi
                fi
            done
            ;;
    esac
}

# Generate dependency report
generate_dependency_report() {
    local output_file="${1:-$DEPS_CACHE_DIR/dependency-report.txt}"
    local include_optional="${2:-true}"
    
    log "Generating dependency report..."
    mkdir -p "$(dirname "$output_file")"
    
    {
        echo "ArcDeploy Dependency Report"
        echo "=========================="
        echo "Generated: $(date)"
        echo "System: $(uname -a)"
        echo ""
        
        # Check all dependency categories
        local categories=("SYSTEM_DEPS" "NODEJS_DEPS" "SECURITY_DEPS")
        local category_names=("System Dependencies" "Node.js Dependencies" "Security Dependencies")
        
        for i in "${!categories[@]}"; do
            local category="${categories[$i]}"
            local category_name="${category_names[$i]}"
            
            echo "$category_name:"
            printf '=%.0s' $(seq 1 ${#category_name})
            echo
            
            local -n deps_ref="$category"
            for dep_name in "${!deps_ref[@]}"; do
                local dep_spec="${deps_ref[$dep_name]}"
                local -A result
                
                check_dependency "$dep_name" "$dep_spec" "result"
                
                # Skip optional dependencies if not requested
                if [ "$include_optional" = "false" ] && [ "${result[priority]}" = "optional" ]; then
                    continue
                fi
                
                printf "  %-20s: %s\n" "$dep_name" "${result[message]}"
            done
            echo ""
        done
        
        # System information
        echo "System Information:"
        echo "=================="
        echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || uname -s)"
        echo "Kernel: $(uname -r)"
        echo "Architecture: $(uname -m)"
        echo "Memory: $(free -h | awk 'NR==2{print $2}')"
        echo "Disk: $(df -h / | awk 'NR==2{print $2}')"
        echo ""
        
    } > "$output_file"
    
    success "Dependency report generated: $output_file"
    return 0
}

# Check system compatibility
check_system_compatibility() {
    log "Checking system compatibility..."
    
    # Check OS compatibility
    local os_info
    if command -v lsb_release >/dev/null 2>&1; then
        os_info=$(lsb_release -si 2>/dev/null)
    else
        os_info=$(uname -s)
    fi
    
    case "$os_info" in
        "Ubuntu"|"Debian")
            success "Compatible OS detected: $os_info"
            ;;
        "CentOS"|"RHEL"|"Rocky"|"AlmaLinux")
            warning "Limited support for: $os_info"
            ;;
        *)
            warning "Untested OS: $os_info"
            ;;
    esac
    
    # Check architecture
    local arch
    arch=$(uname -m)
    case "$arch" in
        "x86_64"|"amd64")
            success "Compatible architecture: $arch"
            ;;
        "aarch64"|"arm64")
            warning "Limited support for architecture: $arch"
            ;;
        *)
            warning "Untested architecture: $arch"
            ;;
    esac
    
    # Check minimum system requirements
    local total_ram_gb
    total_ram_gb=$(free -g | awk 'NR==2{print $2}')
    if [ "$total_ram_gb" -ge 4 ]; then
        success "Memory requirement met: ${total_ram_gb}GB"
    else
        error "Insufficient memory: ${total_ram_gb}GB (minimum: 4GB)"
        return 1
    fi
    
    # Check disk space
    local total_disk_gb
    total_disk_gb=$(df / | awk 'NR==2 {print int($2/1024/1024)}')
    if [ "$total_disk_gb" -ge 40 ]; then
        success "Disk requirement met: ${total_disk_gb}GB"
    else
        error "Insufficient disk space: ${total_disk_gb}GB (minimum: 40GB)"
        return 1
    fi
    
    return 0
}

# Main dependency check function
check_all_dependencies() {
    local auto_fix="${1:-false}"
    local include_optional="${2:-true}"
    
    init_deps_cache
    
    log "Starting comprehensive dependency check..."
    
    local overall_status=0
    
    # Check system compatibility first
    if ! check_system_compatibility; then
        overall_status=1
    fi
    
    # Check each category
    if ! check_dependency_category "System" "SYSTEM_DEPS"; then
        overall_status=1
        if [ "$auto_fix" = "true" ]; then
            auto_fix_dependencies "system" "$include_optional"
        fi
    fi
    
    if ! check_dependency_category "Node.js" "NODEJS_DEPS"; then
        overall_status=1
        if [ "$auto_fix" = "true" ]; then
            auto_fix_dependencies "nodejs" "$include_optional"
        fi
    fi
    
    if ! check_dependency_category "Security" "SECURITY_DEPS"; then
        if [ "$include_optional" = "true" ]; then
            # Don't fail on security tools for main check
            warning "Some security tools are missing"
        fi
        if [ "$auto_fix" = "true" ]; then
            auto_fix_dependencies "security" "$include_optional"
        fi
    fi
    
    # Generate report
    generate_dependency_report "$DEPS_CACHE_DIR/last-check-report.txt" "$include_optional"
    
    if [ $overall_status -eq 0 ]; then
        success "All critical dependencies satisfied"
    else
        error "Some critical dependencies are missing or incompatible"
    fi
    
    return $overall_status
}

# Export main functions
export -f check_all_dependencies
export -f check_dependency
export -f generate_dependency_report
export -f auto_fix_dependencies
export -f check_system_compatibility

debug "Dependency management library v$DEPS_LIB_VERSION loaded"