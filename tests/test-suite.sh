#!/bin/bash

# ArcDeploy Comprehensive Testing Suite
# This script provides automated testing for ArcDeploy configurations and deployments

set -euo pipefail

# Test suite metadata
readonly TEST_SUITE_VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly TEST_RESULTS_DIR="$PROJECT_ROOT/test-results"
readonly TEST_CONFIGS_DIR="$SCRIPT_DIR/configs"
readonly TEST_LOGS_DIR="$TEST_RESULTS_DIR/logs"

# Colors for output (only set if not already set)
if [[ -z "${RED:-}" ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly PURPLE='\033[0;35m'
    readonly CYAN='\033[0;36m'
    readonly WHITE='\033[1;37m'
    readonly NC='\033[0m'
fi

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Test categories
declare -a TEST_CATEGORIES=(
    "unit"           # Unit tests for individual functions
    "integration"    # Integration tests for component interaction
    "security"       # Security configuration tests
    "performance"    # Performance and resource tests
    "compatibility"  # Multi-platform compatibility tests
    "deployment"     # End-to-end deployment tests
)

# Logging functions
log() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[$timestamp]${NC} $message" | tee -a "$TEST_LOGS_DIR/test-suite.log"
}

error() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR][$timestamp]${NC} $message" | tee -a "$TEST_LOGS_DIR/test-suite.log" >&2
}

success() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[SUCCESS][$timestamp]${NC} $message" | tee -a "$TEST_LOGS_DIR/test-suite.log"
}

warning() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[WARNING][$timestamp]${NC} $message" | tee -a "$TEST_LOGS_DIR/test-suite.log"
}

debug() {
    local message="$1"
    if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
        local timestamp
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo -e "${PURPLE}[DEBUG][$timestamp]${NC} $message" | tee -a "$TEST_LOGS_DIR/test-suite.log"
    fi
}

# Test result functions
test_pass() {
    local test_name="$1"
    local message="${2:-}"
    ((TESTS_PASSED++))
    echo -e "${GREEN}[PASS]${NC} $test_name${message:+ - $message}"
}

test_fail() {
    local test_name="$1"
    local message="${2:-}"
    ((TESTS_FAILED++))
    echo -e "${RED}[FAIL]${NC} $test_name${message:+ - $message}"
}

test_skip() {
    local test_name="$1"
    local reason="${2:-No reason provided}"
    ((TESTS_SKIPPED++))
    echo -e "${YELLOW}[SKIP]${NC} $test_name - $reason"
}

# Test execution wrapper
run_test() {
    local test_name="$1"
    local test_function="$2"
    local test_description="${3:-}"
    
    ((TESTS_TOTAL++))
    
    echo ""
    echo -e "${CYAN}Running test:${NC} $test_name"
    if [ -n "$test_description" ]; then
        echo -e "${WHITE}Description:${NC} $test_description"
    fi
    
    local start_time
    start_time=$(date +%s)
    
    if "$test_function"; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        test_pass "$test_name" "completed in ${duration}s"
    else
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        test_fail "$test_name" "failed after ${duration}s"
    fi
}

# Setup test environment
setup_test_environment() {
    # Set test-friendly log file location before loading anything
    export SETUP_LOG="/tmp/arcblock-test-setup.log"
    export HEALTH_LOG="/tmp/arcblock-test-health.log"
    
    # Create test directories first
    mkdir -p "$TEST_RESULTS_DIR"
    mkdir -p "$TEST_LOGS_DIR"
    mkdir -p "$TEST_CONFIGS_DIR"
    
    # Clear previous test logs
    > "$TEST_LOGS_DIR/test-suite.log"
    
    log "Setting up test environment..."
    
    # Load common library if available
    if [ -f "$PROJECT_ROOT/scripts/lib/common.sh" ]; then
        # shellcheck source=../scripts/lib/common.sh
        source "$PROJECT_ROOT/scripts/lib/common.sh"
        debug "Loaded common library"
    fi
    
    # Load configuration if available
    if [ -f "$PROJECT_ROOT/config/arcdeploy.conf" ]; then
        # shellcheck source=../config/arcdeploy.conf
        source "$PROJECT_ROOT/config/arcdeploy.conf"
        debug "Loaded configuration"
    fi
    
    success "Test environment setup completed"
}

# ============================================================================
# UNIT TESTS
# ============================================================================

# Test configuration file parsing
test_config_parsing() {
    local config_file="$PROJECT_ROOT/config/arcdeploy.conf"
    
    if [ ! -f "$config_file" ]; then
        return 1
    fi
    
    # Test configuration loading in a subshell to avoid conflicts
    (
        # Set test-friendly log paths
        export SETUP_LOG="/tmp/test-setup.log"
        export HEALTH_LOG="/tmp/test-health.log"
        
        # shellcheck source=../config/arcdeploy.conf
        source "$config_file" 2>/dev/null
        
        if [ -z "${USER_NAME:-}" ]; then
            exit 1
        fi
        
        # Test required variables
        local required_vars=("BLOCKLET_BASE_DIR" "SSH_PORT" "BLOCKLET_HTTP_PORT")
        for var in "${required_vars[@]}"; do
            if [ -z "${!var:-}" ]; then
                exit 1
            fi
        done
        
        exit 0
    )
    
    return $?
}

# Test common library functions
test_common_library() {
    if [ ! -f "$PROJECT_ROOT/scripts/lib/common.sh" ]; then
        return 1
    fi
    
    # Test logging functions
    if ! command -v log >/dev/null 2>&1; then
        return 1
    fi
    
    # Test utility functions
    if ! command -v command_exists >/dev/null 2>&1; then
        return 1
    fi
    
    # Test error handling setup
    if ! command -v error_exit >/dev/null 2>&1; then
        return 1
    fi
    
    return 0
}

# Test template generation
test_template_generation() {
    local generator_script="$PROJECT_ROOT/scripts/generate-config.sh"
    local template_file="$PROJECT_ROOT/templates/cloud-init.yaml.template"
    
    # Check if generator script exists and is executable
    if [ ! -x "$generator_script" ]; then
        return 1
    fi
    
    # Check if template file exists
    if [ ! -f "$template_file" ]; then
        return 1
    fi
    
    # Test template variable substitution
    local test_vars="USER_NAME=testuser SSH_PORT=2222"
    if ! echo 'User: ${USER_NAME}, Port: ${SSH_PORT}' | env $test_vars envsubst | grep -q "User: testuser, Port: 2222"; then
        return 1
    fi
    
    return 0
}

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

# Test script integration
test_script_integration() {
    local scripts_dir="$PROJECT_ROOT/scripts"
    
    # Check if all required scripts exist
    local required_scripts=(
        "setup.sh"
        "validate-setup.sh"
        "debug_commands.sh"
        "generate-config.sh"
    )
    
    for script in "${required_scripts[@]}"; do
        if [ ! -f "$scripts_dir/$script" ]; then
            return 1
        fi
    done
    
    # Test script syntax
    for script in "${required_scripts[@]}"; do
        if ! bash -n "$scripts_dir/$script"; then
            return 1
        fi
    done
    
    return 0
}

# Test configuration template consistency
test_config_template_consistency() {
    local cloud_init_file="$PROJECT_ROOT/cloud-init.yaml"
    local template_file="$PROJECT_ROOT/templates/cloud-init.yaml.template"
    
    if [ ! -f "$cloud_init_file" ] || [ ! -f "$template_file" ]; then
        return 1
    fi
    
    # Test that template contains required sections
    local required_sections=("users" "packages" "write_files" "runcmd")
    for section in "${required_sections[@]}"; do
        if ! grep -q "^$section:" "$template_file"; then
            return 1
        fi
    done
    
    return 0
}

# ============================================================================
# SECURITY TESTS
# ============================================================================

# Test SSH configuration security
test_ssh_security() {
    local ssh_config="$PROJECT_ROOT/templates/cloud-init.yaml.template"
    
    if [ ! -f "$ssh_config" ]; then
        return 1
    fi
    
    # Check for secure SSH settings
    local security_checks=(
        "PermitRootLogin no"
        "PasswordAuthentication no"
        "PubkeyAuthentication yes"
    )
    
    for check in "${security_checks[@]}"; do
        if ! grep -q "$check" "$ssh_config"; then
            return 1
        fi
    done
    
    return 0
}

# Test firewall configuration
test_firewall_config() {
    local template_file="$PROJECT_ROOT/templates/cloud-init.yaml.template"
    
    if [ ! -f "$template_file" ]; then
        return 1
    fi
    
    # Check for UFW configuration
    if ! grep -q "ufw --force enable" "$template_file"; then
        return 1
    fi
    
    # Check for default deny policy
    if ! grep -q "ufw default deny incoming" "$template_file"; then
        return 1
    fi
    
    return 0
}

# Test fail2ban configuration
test_fail2ban_config() {
    local template_file="$PROJECT_ROOT/templates/cloud-init.yaml.template"
    
    if [ ! -f "$template_file" ]; then
        return 1
    fi
    
    # Check for fail2ban configuration
    if ! grep -q "fail2ban" "$template_file"; then
        return 1
    fi
    
    # Check for jail configuration
    if ! grep -q "jail.local" "$template_file"; then
        return 1
    fi
    
    return 0
}

# ============================================================================
# PERFORMANCE TESTS
# ============================================================================

# Test script execution time
test_script_performance() {
    local validation_script="$PROJECT_ROOT/scripts/validate-setup.sh"
    
    if [ ! -x "$validation_script" ]; then
        return 1
    fi
    
    # Time the validation script (should complete quickly)
    local start_time
    start_time=$(date +%s)
    
    # Run validation with minimal checks
    timeout 30s bash -n "$validation_script" >/dev/null 2>&1
    local exit_code=$?
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Should complete syntax check in under 5 seconds
    if [ $exit_code -ne 0 ] || [ $duration -gt 5 ]; then
        return 1
    fi
    
    return 0
}

# Test configuration generation performance
test_config_generation_performance() {
    local generator_script="$PROJECT_ROOT/scripts/generate-config.sh"
    
    if [ ! -x "$generator_script" ]; then
        return 1
    fi
    
    # Create temporary SSH key for testing
    local temp_key_file
    temp_key_file=$(mktemp)
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITest12345678901234567890123456789012 test@example.com" > "$temp_key_file"
    
    # Time the configuration generation
    local start_time
    start_time=$(date +%s)
    
    local temp_output
    temp_output=$(mktemp)
    
    # Test generation with timeout
    if timeout 10s "$generator_script" -p hetzner -k "$temp_key_file" -o "$temp_output" >/dev/null 2>&1; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        # Cleanup
        rm -f "$temp_key_file" "$temp_output"
        
        # Should complete in under 5 seconds
        if [ $duration -gt 5 ]; then
            return 1
        fi
        
        return 0
    else
        # Cleanup on failure
        rm -f "$temp_key_file" "$temp_output"
        return 1
    fi
}

# ============================================================================
# COMPATIBILITY TESTS
# ============================================================================

# Test YAML syntax validation
test_yaml_syntax() {
    local yaml_files=(
        "$PROJECT_ROOT/cloud-init.yaml"
        "$PROJECT_ROOT/templates/cloud-init.yaml.template"
    )
    
    for file in "${yaml_files[@]}"; do
        if [ -f "$file" ]; then
            # Test with Python YAML parser if available
            if command -v python3 >/dev/null 2>&1; then
                if ! python3 -c "
import yaml
import sys
try:
    with open('$file', 'r') as f:
        content = f.read()
        # Skip template files with substitution variables
        if '\${' not in content:
            yaml.safe_load(content)
    print('YAML syntax validation: PASSED')
except yaml.YAMLError as e:
    print('YAML syntax validation: FAILED - ' + str(e))
    sys.exit(1)
except Exception as e:
    print('Validation error: ' + str(e))
    sys.exit(1)
" 2>/dev/null; then
                    return 1
                fi
            fi
        fi
    done
    
    return 0
}

# Test shell script compatibility
test_shell_compatibility() {
    local script_files=(
        "$PROJECT_ROOT/scripts/setup.sh"
        "$PROJECT_ROOT/scripts/validate-setup.sh"
        "$PROJECT_ROOT/scripts/debug_commands.sh"
    )
    
    for script in "${script_files[@]}"; do
        if [ -f "$script" ]; then
            # Test bash syntax
            if ! bash -n "$script" 2>/dev/null; then
                return 1
            fi
            
            # Test for common compatibility issues
            if grep -q "#!/bin/sh" "$script" && grep -qE "\[\[|\$\(|local " "$script"; then
                # Uses bash features but declares sh shebang
                return 1
            fi
        fi
    done
    
    return 0
}

# ============================================================================
# DEPLOYMENT TESTS
# ============================================================================

# Test cloud-init configuration structure
test_cloud_init_structure() {
    local cloud_init_file="$PROJECT_ROOT/cloud-init.yaml"
    
    if [ ! -f "$cloud_init_file" ]; then
        return 1
    fi
    
    # Check for required cloud-init sections
    local required_sections=(
        "users"
        "packages"
        "write_files"
        "runcmd"
    )
    
    for section in "${required_sections[@]}"; do
        if ! grep -q "^$section:" "$cloud_init_file"; then
            return 1
        fi
    done
    
    # Check for proper YAML structure
    if ! grep -q "^#cloud-config" "$cloud_init_file"; then
        return 1
    fi
    
    return 0
}

# Test documentation completeness
test_documentation() {
    local doc_files=(
        "$PROJECT_ROOT/README.md"
        "$PROJECT_ROOT/QUICK_START.md"
        "$PROJECT_ROOT/docs/TROUBLESHOOTING.md"
        "$PROJECT_ROOT/docs/SECURITY_ASSESSMENT.md"
    )
    
    for doc in "${doc_files[@]}"; do
        if [ ! -f "$doc" ]; then
            return 1
        fi
        
        # Check that files are not empty
        if [ ! -s "$doc" ]; then
            return 1
        fi
    done
    
    return 0
}

# ============================================================================
# TEST EXECUTION ENGINE
# ============================================================================

# Run tests by category
run_test_category() {
    local category="$1"
    
    echo ""
    echo -e "${WHITE}===========================================${NC}"
    echo -e "${WHITE}Running $category tests${NC}"
    echo -e "${WHITE}===========================================${NC}"
    
    case "$category" in
        "unit")
            run_test "config_parsing" "test_config_parsing" "Test configuration file parsing"
            run_test "common_library" "test_common_library" "Test common library functions"
            run_test "template_generation" "test_template_generation" "Test template generation system"
            ;;
        "integration")
            run_test "script_integration" "test_script_integration" "Test script file integration"
            run_test "config_template_consistency" "test_config_template_consistency" "Test config-template consistency"
            ;;
        "security")
            run_test "ssh_security" "test_ssh_security" "Test SSH security configuration"
            run_test "firewall_config" "test_firewall_config" "Test firewall configuration"
            run_test "fail2ban_config" "test_fail2ban_config" "Test fail2ban configuration"
            ;;
        "performance")
            run_test "script_performance" "test_script_performance" "Test script execution performance"
            run_test "config_generation_performance" "test_config_generation_performance" "Test config generation performance"
            ;;
        "compatibility")
            run_test "yaml_syntax" "test_yaml_syntax" "Test YAML syntax validation"
            run_test "shell_compatibility" "test_shell_compatibility" "Test shell script compatibility"
            ;;
        "deployment")
            run_test "cloud_init_structure" "test_cloud_init_structure" "Test cloud-init structure"
            run_test "documentation" "test_documentation" "Test documentation completeness"
            ;;
        *)
            error "Unknown test category: $category"
            return 1
            ;;
    esac
}

# Generate test report
generate_test_report() {
    local report_file="$TEST_RESULTS_DIR/test-report-$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "ArcDeploy Test Suite Report"
        echo "=========================="
        echo "Date: $(date)"
        echo "Test Suite Version: $TEST_SUITE_VERSION"
        echo ""
        echo "Test Summary:"
        echo "  Total Tests: $TESTS_TOTAL"
        echo "  Passed: $TESTS_PASSED"
        echo "  Failed: $TESTS_FAILED"
        echo "  Skipped: $TESTS_SKIPPED"
        echo ""
        
        local success_rate=0
        if [ $TESTS_TOTAL -gt 0 ]; then
            success_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
        fi
        echo "  Success Rate: $success_rate%"
        echo ""
        
        if [ $TESTS_FAILED -gt 0 ]; then
            echo "Result: FAILED"
        else
            echo "Result: PASSED"
        fi
        echo ""
        echo "Detailed logs available in: $TEST_LOGS_DIR/"
    } > "$report_file"
    
    # Also display summary
    cat "$report_file"
    
    success "Test report generated: $report_file"
}

# Display usage information
usage() {
    cat << EOF
ArcDeploy Test Suite v$TEST_SUITE_VERSION

Usage: $0 [OPTIONS] [CATEGORIES...]

Options:
    -h, --help        Show this help message
    -v, --verbose     Enable verbose output
    -d, --debug       Enable debug mode
    -q, --quiet       Suppress non-essential output
    -r, --report      Generate detailed test report
    -f, --fail-fast   Stop on first test failure

Categories:
    unit             Unit tests for individual functions
    integration      Integration tests for component interaction
    security         Security configuration tests
    performance      Performance and resource tests
    compatibility    Multi-platform compatibility tests
    deployment       End-to-end deployment tests
    all              Run all test categories (default)

Examples:
    $0                      # Run all tests
    $0 unit security        # Run only unit and security tests
    $0 -v --report          # Run all tests with verbose output and report
    $0 -f integration       # Run integration tests, stop on first failure

EOF
}

# Main function
main() {
    local categories=()
    local verbose=false
    local debug_mode=false
    local quiet=false
    local generate_report=false
    local fail_fast=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -d|--debug)
                debug_mode=true
                export DEBUG_MODE=true
                shift
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            -r|--report)
                generate_report=true
                shift
                ;;
            -f|--fail-fast)
                fail_fast=true
                shift
                ;;
            *)
                if [[ " ${TEST_CATEGORIES[*]} " == *" $1 "* ]] || [ "$1" = "all" ]; then
                    categories+=("$1")
                else
                    error "Unknown option or category: $1"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Set default category if none specified
    if [ ${#categories[@]} -eq 0 ]; then
        categories=("all")
    fi
    
    # If "all" is specified, run all categories
    if [[ " ${categories[*]} " == *" all "* ]]; then
        categories=("${TEST_CATEGORIES[@]}")
    fi
    
    # Setup test environment
    setup_test_environment
    
    echo ""
    echo -e "${WHITE}============================================${NC}"
    echo -e "${WHITE}ArcDeploy Test Suite v$TEST_SUITE_VERSION${NC}"
    echo -e "${WHITE}============================================${NC}"
    echo ""
    
    # Only log after setup is complete
    if [ -f "$TEST_LOGS_DIR/test-suite.log" ]; then
        log "Starting test execution..."
        log "Categories to run: ${categories[*]}"
    fi
    
    # Run tests by category
    for category in "${categories[@]}"; do
        run_test_category "$category"
        
        # Stop on first failure if fail-fast is enabled
        if [ "$fail_fast" = true ] && [ $TESTS_FAILED -gt 0 ]; then
            error "Test failure detected, stopping execution (fail-fast mode)"
            break
        fi
    done
    
    # Display final summary
    echo ""
    echo -e "${WHITE}============================================${NC}"
    echo -e "${WHITE}Test Execution Complete${NC}"
    echo -e "${WHITE}============================================${NC}"
    echo ""
    echo -e "Total Tests: ${WHITE}$TESTS_TOTAL${NC}"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    echo -e "Skipped: ${YELLOW}$TESTS_SKIPPED${NC}"
    echo ""
    
    local success_rate=0
    if [ $TESTS_TOTAL -gt 0 ]; then
        success_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
    fi
    
    echo -e "Success Rate: ${WHITE}$success_rate%${NC}"
    echo ""
    
    # Generate report if requested
    if [ "$generate_report" = true ]; then
        generate_test_report
    fi
    
    # Exit with appropriate code
    if [ $TESTS_FAILED -gt 0 ]; then
        error "Some tests failed"
        exit 1
    else
        success "All tests passed!"
        exit 0
    fi
}

# Run main function with all arguments
main "$@"