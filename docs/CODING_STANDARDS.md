# ArcDeploy Coding Standards

[![Version](https://img.shields.io/badge/Version-1.0.0-blue.svg)](https://github.com/Pocklabs/ArcDeploy)
[![Shell](https://img.shields.io/badge/Shell-Bash%205.0+-green.svg)](https://www.gnu.org/software/bash/)
[![Standards](https://img.shields.io/badge/Standards-Enforced-brightgreen.svg)](docs/CODING_STANDARDS.md)

## 📋 Overview

This document defines the coding standards and best practices for the ArcDeploy project. These standards ensure consistency, maintainability, and reliability across all scripts and configurations.

## 🎯 Core Principles

1. **Safety First**: All scripts must handle errors gracefully
2. **Clarity Over Cleverness**: Code should be readable and self-documenting
3. **Consistency**: Follow established patterns throughout the codebase
4. **Testability**: Code must be testable and include appropriate test coverage
5. **Security**: Always consider security implications

## 🐚 Shell Script Standards

### Basic Script Structure

```bash
#!/bin/bash

# Script Description: Brief description of what this script does
# Version: 1.0.0
# Author: ArcDeploy Team
# Last Modified: YYYY-MM-DD

# Enable strict error handling
set -euo pipefail

# Script metadata
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "$0")"

# Directory setup (separate declare and assign)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly PROJECT_ROOT

# Load common libraries
if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
    source "$SCRIPT_DIR/lib/common.sh"
fi

# Main function
main() {
    # Script logic here
    log "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
    
    # Your code here
    
    success "$SCRIPT_NAME completed successfully"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### Variable and Function Naming

#### Variables
```bash
# Constants: UPPER_CASE with readonly
readonly MAX_ATTEMPTS=3
readonly CONFIG_FILE="/etc/arcdeploy.conf"

# Global variables: UPPER_CASE
CURRENT_USER=""
SYSTEM_STATUS=""

# Local variables: lower_case
local user_name="arcblock"
local config_path="/opt/config"

# Environment variables: UPPER_CASE with export
export DEBUG_MODE="false"
export LOG_LEVEL="info"
```

#### Functions
```bash
# Function names: snake_case with descriptive names
check_system_requirements() {
    local min_memory="$1"
    local min_disk="$2"
    
    # Function implementation
}

# Private functions: prefix with underscore
_internal_helper_function() {
    # Internal use only
}

# Validation functions: prefix with validate_
validate_ssh_key() {
    local key_file="$1"
    # Validation logic
}
```

### Error Handling

#### Strict Mode Requirements
```bash
# MANDATORY: Enable strict error handling at script start
set -euo pipefail

# For functions that may legitimately fail
set +e  # Temporarily disable
some_command_that_might_fail
local exit_code=$?
set -e  # Re-enable

if [[ $exit_code -ne 0 ]]; then
    warning "Command failed with exit code $exit_code"
fi
```

#### Error Handling Patterns
```bash
# Good: Check command success explicitly
if ! command -v docker >/dev/null 2>&1; then
    error "Docker is not installed"
    return 1
fi

# Good: Handle potential failures
if ! mkdir -p "$directory"; then
    error "Failed to create directory: $directory"
    return 1
fi

# Good: Use error_exit for critical failures
if [[ ! -f "$required_file" ]]; then
    error_exit "Required file not found: $required_file"
fi
```

### Variable Handling

#### Declare and Assign Separately
```bash
# Good: Separate declaration and assignment
local config_content
config_content="$(cat "$config_file")"

local timestamp
timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

# Bad: Combined declaration and assignment (masks return values)
local config_content="$(cat "$config_file")"
```

#### Quoting and Parameter Expansion
```bash
# Good: Always quote variables
if [[ -f "$config_file" ]]; then
    echo "Config file: $config_file"
fi

# Good: Use parameter expansion for defaults
local timeout="${TIMEOUT:-30}"
local user="${USER_NAME:-arcblock}"

# Good: Array handling
local required_packages=("curl" "wget" "git")
for package in "${required_packages[@]}"; do
    install_package "$package"
done
```

### Logging and Output

#### Standard Logging Functions
```bash
# Use common library logging functions
log "Informational message"
success "Operation completed successfully"
warning "Non-critical issue occurred"
error "Error occurred but script continues"
debug "Debug information (only shown in debug mode)"

# For critical errors that should stop execution
error_exit "Critical error - stopping execution"
```

#### Output Formatting
```bash
# Good: Structured output
echo "=== Configuration Summary ==="
echo "User: $USER_NAME"
echo "Port: $SSH_PORT"
echo "Domain: ${DOMAIN:-not set}"
echo "=========================="

# Good: Progress indicators
log "Step 1/3: Downloading packages..."
log "Step 2/3: Installing software..."
log "Step 3/3: Configuring services..."
```

### Function Documentation

```bash
# Function documentation template
#
# Description: Brief description of what the function does
# Parameters:
#   $1 - parameter_name (type): description
#   $2 - parameter_name (type): description
# Returns:
#   0 - success
#   1 - error condition 1
#   2 - error condition 2
# Example:
#   check_port_available "8080" "web server"
#
check_port_available() {
    local port="$1"
    local description="${2:-service}"
    
    if netstat -tuln | grep -q ":$port "; then
        error "Port $port is already in use (needed for $description)"
        return 1
    fi
    
    log "Port $port is available for $description"
    return 0
}
```

## 📁 File Organization

### Directory Structure
```
scripts/
├── lib/                    # Shared libraries
│   ├── common.sh          # Core utility functions
│   ├── dependencies.sh    # Dependency management
│   └── validation.sh      # Validation functions
├── providers/             # Cloud provider specific scripts
├── setup/                 # Installation and setup scripts
└── tools/                 # Development and debugging tools

config/
├── arcdeploy.conf         # Main configuration
├── providers/             # Provider-specific configs
└── templates/             # Configuration templates

tests/
├── unit/                  # Unit tests
├── integration/           # Integration tests
├── data/                  # Test data and fixtures
└── test-suite.sh          # Main test runner
```

### File Naming Conventions
```bash
# Scripts: kebab-case with .sh extension
generate-config.sh
validate-setup.sh
debug-commands.sh

# Configuration files: kebab-case with .conf extension
arcdeploy.conf
provider-config.conf

# Documentation: UPPERCASE for important docs, kebab-case for others
README.md
CHANGELOG.md
installation-guide.md

# Test files: test- prefix
test-config-generation.sh
test-validation-suite.sh
```

## 🧪 Testing Standards

### Test Function Structure
```bash
# Test function naming: test_description_of_what_is_tested
test_config_validation_with_valid_input() {
    local test_config="$TEST_DATA_DIR/valid-config.conf"
    
    # Setup
    setup_test_environment
    
    # Execute
    if validate_config "$test_config"; then
        pass_test "Config validation succeeded with valid input"
    else
        fail_test "Config validation failed with valid input"
    fi
    
    # Cleanup
    cleanup_test_environment
}
```

### Test Data Management
```bash
# Test data in dedicated directory
readonly TEST_DATA_DIR="$SCRIPT_DIR/test-data"

# Use descriptive test data file names
valid-ssh-key.pub
invalid-malformed-key.pub
config-missing-required-fields.conf
config-with-special-characters.conf
```

## 🔒 Security Standards

### Input Validation
```bash
# Always validate input parameters
validate_ssh_key() {
    local key_file="$1"
    
    # Check if file exists
    if [[ ! -f "$key_file" ]]; then
        error "SSH key file not found: $key_file"
        return 1
    fi
    
    # Check file permissions
    local perms
    perms="$(stat -c '%a' "$key_file")"
    if [[ "$perms" != "600" ]]; then
        warning "SSH key file has incorrect permissions: $perms (should be 600)"
    fi
    
    # Validate key format
    if ! ssh-keygen -l -f "$key_file" >/dev/null 2>&1; then
        error "Invalid SSH key format in: $key_file"
        return 1
    fi
    
    return 0
}
```

### Secure Defaults
```bash
# Good: Secure defaults
readonly SSH_PORT="${SSH_PORT:-2222}"  # Non-standard port
readonly MAX_AUTH_TRIES="${MAX_AUTH_TRIES:-3}"  # Limited attempts
readonly ENABLE_PASSWORD_AUTH="${ENABLE_PASSWORD_AUTH:-false}"  # Key-only auth

# Good: Validate security-critical settings
if [[ "$SSH_PORT" == "22" ]]; then
    warning "Using default SSH port 22 - consider changing for security"
fi
```

### Path Safety
```bash
# Good: Validate paths to prevent injection
validate_path() {
    local path="$1"
    
    # Check for path traversal attempts
    if [[ "$path" =~ \.\./|\.\. ]]; then
        error "Path traversal detected in: $path"
        return 1
    fi
    
    # Ensure path is within expected directory
    local canonical_path
    canonical_path="$(realpath "$path" 2>/dev/null)" || {
        error "Invalid path: $path"
        return 1
    }
    
    return 0
}
```

## 📊 Performance Standards

### Efficient Operations
```bash
# Good: Cache expensive operations
get_system_info() {
    local cache_file="/tmp/arcdeploy-system-info.cache"
    local cache_age=300  # 5 minutes
    
    if [[ -f "$cache_file" ]] && [[ $(($(date +%s) - $(stat -c %Y "$cache_file"))) -lt $cache_age ]]; then
        cat "$cache_file"
        return 0
    fi
    
    # Expensive operation
    local system_info
    system_info="$(uname -a; free -h; df -h)"
    echo "$system_info" | tee "$cache_file"
}

# Good: Minimize external command calls
# Instead of multiple calls:
# host=$(hostname)
# os=$(uname -s)
# arch=$(uname -m)

# Do this:
read -r host os arch < <(printf '%s %s %s\n' "$(hostname)" "$(uname -s)" "$(uname -m)")
```

### Resource Management
```bash
# Good: Clean up temporary files
cleanup_temp_files() {
    local temp_files=("$@")
    
    for file in "${temp_files[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            debug "Cleaned up temporary file: $file"
        fi
    done
}

# Good: Use trap for cleanup
temp_file="$(mktemp)"
trap 'rm -f "$temp_file"' EXIT
```

## 🔧 Configuration Standards

### Configuration File Format
```bash
# Use consistent format in .conf files
# Comments start with # and are descriptive
# GROUP SETTINGS in sections

# ============================================================================
# Core Configuration
# ============================================================================

# User account settings
USER_NAME="arcblock"
USER_GROUP="arcblock"
USER_HOME="/home/arcblock"

# Network settings
SSH_PORT="2222"
BLOCKLET_HTTP_PORT="8080"
BLOCKLET_HTTPS_PORT="8443"

# ============================================================================
# Security Configuration
# ============================================================================

# SSH security settings
ENABLE_PASSWORD_AUTH="false"
SSH_MAX_AUTH_TRIES="3"
SSH_LOGIN_GRACE_TIME="60"

# Feature flags (use lowercase true/false)
ENABLE_SSL="false"
ENABLE_FIREWALL="true"
ENABLE_FAIL2BAN="true"
```

### Environment Variable Handling
```bash
# Good: Provide defaults and validation
load_config() {
    local config_file="${1:-$PROJECT_ROOT/config/arcdeploy.conf}"
    
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    fi
    
    # Apply defaults for required variables
    USER_NAME="${USER_NAME:-arcblock}"
    SSH_PORT="${SSH_PORT:-2222}"
    BLOCKLET_HTTP_PORT="${BLOCKLET_HTTP_PORT:-8080}"
    
    # Validate critical settings
    if ! [[ "$SSH_PORT" =~ ^[0-9]+$ ]] || [[ "$SSH_PORT" -lt 1024 ]] || [[ "$SSH_PORT" -gt 65535 ]]; then
        error_exit "Invalid SSH_PORT: $SSH_PORT (must be 1024-65535)"
    fi
}
```

## 🚀 Deployment Standards

### Version Management
```bash
# Include version in all scripts
readonly SCRIPT_VERSION="1.2.0"

# Version comparison function
version_compare() {
    local version1="$1"
    local version2="$2"
    
    if [[ "$(printf '%s\n' "$version1" "$version2" | sort -V | head -n1)" == "$version1" ]]; then
        echo "less_or_equal"
    else
        echo "greater"
    fi
}
```

### Backward Compatibility
```bash
# Good: Support deprecated settings with warnings
if [[ -n "${OLD_SETTING_NAME:-}" ]]; then
    warning "OLD_SETTING_NAME is deprecated, use NEW_SETTING_NAME instead"
    NEW_SETTING_NAME="${NEW_SETTING_NAME:-$OLD_SETTING_NAME}"
fi
```

## 📖 Documentation Standards

### Inline Comments
```bash
# Good: Explain why, not what
# Increase timeout for slow networks in cloud environments
readonly NETWORK_TIMEOUT=60

# Good: Document complex logic
# Check if we're running in a container by looking for .dockerenv
# or checking if PID 1 is not init/systemd
is_container() {
    [[ -f /.dockerenv ]] || [[ "$(ps -o comm= 1)" != "systemd" ]]
}
```

### Function Headers
```bash
# Use consistent function documentation
#
# Downloads and validates a file from a URL
# 
# Parameters:
#   $1 - url (string): The URL to download from
#   $2 - output_file (string): Local file path to save to
#   $3 - expected_hash (string, optional): SHA256 hash for validation
#
# Returns:
#   0 - Success
#   1 - Download failed
#   2 - Hash validation failed
#
# Example:
#   download_file "https://example.com/file.tar.gz" "/tmp/file.tar.gz" "abc123..."
#
download_file() {
    # Implementation here
}
```

## ✅ Quality Assurance

### Pre-commit Checks
```bash
# All scripts must pass these checks:
shellcheck script.sh                    # Static analysis
bash -n script.sh                      # Syntax check
./tests/test-script.sh                 # Unit tests
```

### Code Review Checklist
- [ ] Script follows error handling standards
- [ ] Variables are properly quoted and declared
- [ ] Functions are documented
- [ ] Input validation is present
- [ ] Security considerations are addressed
- [ ] Performance is acceptable
- [ ] Tests are included and passing
- [ ] Documentation is updated

## 🔄 Continuous Improvement

### Metrics to Track
- ShellCheck warnings: Target 0
- Test coverage: Target 95%+
- Documentation coverage: All public functions
- Performance benchmarks: Track regression

### Regular Reviews
- Monthly review of coding standards
- Quarterly security audit
- Annual performance optimization review

---

## 📞 Support

For questions about these coding standards:
- Create an issue with the `coding-standards` label
- Refer to the [Style Guide Examples](examples/style-guide/)
- Check the [FAQ](docs/FAQ.md#coding-standards)

## 📄 License

This document is part of the ArcDeploy project and is licensed under the MIT License.

---

**"Code is read more often than it is written."** - Follow these standards to make ArcDeploy maintainable for everyone.