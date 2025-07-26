#!/bin/bash

# ArcDeploy Setup Validation Script
# Checks if everything is configured correctly for deployment

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CLOUD_INIT_FILE="$SCRIPT_DIR/cloud-init.yaml"

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

print_check() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((CHECKS_PASSED++))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((CHECKS_FAILED++))
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((CHECKS_WARNING++))
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if required commands are available
check_dependencies() {
    print_check "Checking required dependencies..."

    if command -v curl >/dev/null 2>&1; then
        print_pass "curl is installed"
    else
        print_fail "curl is not installed"
        print_info "Install with: apt install curl (Ubuntu/Debian) or brew install curl (macOS)"
    fi

    if command -v jq >/dev/null 2>&1; then
        print_pass "jq is installed"
    else
        print_fail "jq is not installed"
        print_info "Install with: apt install jq (Ubuntu/Debian) or brew install jq (macOS)"
    fi

    if command -v ssh >/dev/null 2>&1; then
        print_pass "ssh is installed"
    else
        print_fail "ssh is not installed"
    fi

    if command -v ssh-keygen >/dev/null 2>&1; then
        print_pass "ssh-keygen is installed"
    else
        print_fail "ssh-keygen is not installed"
    fi
}

# Check cloud-init file
check_cloud_init() {
    print_check "Checking cloud-init configuration..."

    if [[ -f "$CLOUD_INIT_FILE" ]]; then
        print_pass "cloud-init.yaml exists"

        # Check for SSH key placeholder
        if grep -q "ReplaceWithYourActualEd25519PublicKey" "$CLOUD_INIT_FILE"; then
            print_fail "SSH key placeholder still present in cloud-init.yaml"
            print_info "Replace 'ReplaceWithYourActualEd25519PublicKey' with your actual SSH public key"
            print_info "Generate key with: ssh-keygen -t ed25519 -C \"your-email@example.com\""
            print_info "Get public key with: cat ~/.ssh/id_ed25519.pub"
        else
            print_pass "SSH key placeholder has been replaced"
        fi

        # Check for valid SSH key format
        if grep -q "ssh-ed25519 AAAA" "$CLOUD_INIT_FILE"; then
            print_pass "Valid ed25519 SSH key found in cloud-init.yaml"
        elif grep -q "ssh-rsa AAAA" "$CLOUD_INIT_FILE"; then
            print_warn "RSA SSH key found (ed25519 recommended for better security)"
        else
            print_warn "No recognizable SSH key format found"
        fi

        # Check YAML syntax
        if command -v python3 >/dev/null 2>&1; then
            if python3 -c "import yaml; yaml.safe_load(open('$CLOUD_INIT_FILE'))" 2>/dev/null; then
                print_pass "cloud-init.yaml has valid YAML syntax"
            else
                print_fail "cloud-init.yaml has invalid YAML syntax"
            fi
        else
            print_warn "python3 not available - cannot validate YAML syntax"
        fi
    else
        print_fail "cloud-init.yaml not found"
        print_info "File should be located at: $CLOUD_INIT_FILE"
    fi
}

# Check Hetzner token
check_hetzner_token() {
    print_check "Checking Hetzner Cloud API token..."

    if [[ -n "${HETZNER_TOKEN:-}" ]]; then
        print_pass "HETZNER_TOKEN environment variable is set"

        # Validate token format (should be 64 characters)
        if [[ ${#HETZNER_TOKEN} -eq 64 ]]; then
            print_pass "Token has correct length (64 characters)"
        else
            print_warn "Token length is ${#HETZNER_TOKEN} characters (expected 64)"
        fi

        # Test API access
        if command -v curl >/dev/null 2>&1; then
            print_check "Testing API access..."
            local response
            response=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $HETZNER_TOKEN" \
                "https://api.hetzner.cloud/v1/server_types" -o /dev/null)

            if [[ "$response" == "200" ]]; then
                print_pass "API access successful"
            elif [[ "$response" == "401" ]]; then
                print_fail "API access denied - invalid token"
            else
                print_warn "API access returned HTTP $response"
            fi
        fi
    else
        print_fail "HETZNER_TOKEN environment variable not set"
        print_info "Get your token from: https://console.hetzner.cloud/"
        print_info "Set with: export HETZNER_TOKEN=\"your-token-here\""
    fi
}

# Check SSH key availability
check_ssh_keys() {
    print_check "Checking SSH key configuration..."

    local ssh_dir="$HOME/.ssh"
    if [[ -d "$ssh_dir" ]]; then
        print_pass "SSH directory exists: $ssh_dir"

        # Check for common key files
        local found_keys=0
        for key_type in id_ed25519 id_rsa id_ecdsa; do
            if [[ -f "$ssh_dir/$key_type" ]]; then
                print_pass "Found private key: $key_type"
                ((found_keys++))

                if [[ -f "$ssh_dir/$key_type.pub" ]]; then
                    print_pass "Found public key: $key_type.pub"

                    # Show the public key for reference
                    print_info "Public key content:"
                    echo "    $(cat "$ssh_dir/$key_type.pub")"
                else
                    print_warn "Missing public key: $key_type.pub"
                fi
            fi
        done

        if [[ $found_keys -eq 0 ]]; then
            print_warn "No SSH keys found in $ssh_dir"
            print_info "Generate with: ssh-keygen -t ed25519 -C \"your-email@example.com\""
        fi
    else
        print_warn "SSH directory not found: $ssh_dir"
        print_info "Create keys with: ssh-keygen -t ed25519 -C \"your-email@example.com\""
    fi
}

# Check network connectivity
check_connectivity() {
    print_check "Checking network connectivity..."

    # Test Hetzner API
    if curl -s --connect-timeout 10 "https://api.hetzner.cloud/v1/server_types" >/dev/null; then
        print_pass "Can reach Hetzner Cloud API"
    else
        print_fail "Cannot reach Hetzner Cloud API"
        print_info "Check your internet connection and firewall settings"
    fi

    # Test general internet
    if curl -s --connect-timeout 5 "https://www.google.com" >/dev/null; then
        print_pass "Internet connectivity working"
    else
        print_warn "Limited internet connectivity"
    fi
}

# Check script permissions
check_permissions() {
    print_check "Checking script permissions..."

    local deploy_script="$SCRIPT_DIR/deploy-test-server.sh"
    local quick_script="$SCRIPT_DIR/quick-deploy.sh"

    for script in "$deploy_script" "$quick_script"; do
        if [[ -f "$script" ]]; then
            if [[ -x "$script" ]]; then
                print_pass "$(basename "$script") is executable"
            else
                print_warn "$(basename "$script") is not executable"
                print_info "Fix with: chmod +x $script"
            fi
        else
            print_warn "$(basename "$script") not found"
        fi
    done
}

# Check system requirements
check_system() {
    print_check "Checking system requirements..."

    # Check OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        print_pass "Running on Linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        print_pass "Running on macOS"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        print_warn "Running on Windows (WSL/Cygwin detected)"
        print_info "Ensure you're using a proper bash environment"
    else
        print_warn "Unknown operating system: $OSTYPE"
    fi

    # Check bash version
    if [[ ${BASH_VERSION%%.*} -ge 4 ]]; then
        print_pass "Bash version: $BASH_VERSION"
    else
        print_warn "Old bash version: $BASH_VERSION (4.0+ recommended)"
    fi
}

# Show recommendations
show_recommendations() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Recommendations"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [[ $CHECKS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ Your setup looks good! You're ready to deploy.${NC}"
        echo ""
        echo "Quick start:"
        echo "  ./quick-deploy.sh"
        echo ""
        echo "Or with full options:"
        echo "  ./deploy-test-server.sh my-server cx31 fsn1"
    else
        echo -e "${RED}✗ Please fix the failed checks before deploying.${NC}"
        echo ""
        echo "Common fixes:"
        echo "1. Install missing dependencies: apt install curl jq (Ubuntu) or brew install curl jq (macOS)"
        echo "2. Set Hetzner token: export HETZNER_TOKEN=\"your-token-here\""
        echo "3. Configure SSH key in cloud-init.yaml"
        echo "4. Generate SSH key if needed: ssh-keygen -t ed25519 -C \"your-email@example.com\""
    fi

    if [[ $CHECKS_WARNING -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}⚠ Warnings detected - review them for optimal experience.${NC}"
    fi
}

# Show summary
show_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Setup Validation Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local total=$((CHECKS_PASSED + CHECKS_FAILED + CHECKS_WARNING))

    echo -e "Total checks: $total"
    echo -e "${GREEN}Passed: $CHECKS_PASSED${NC}"
    echo -e "${RED}Failed: $CHECKS_FAILED${NC}"
    echo -e "${YELLOW}Warnings: $CHECKS_WARNING${NC}"

    if [[ $CHECKS_FAILED -eq 0 ]]; then
        echo ""
        echo -e "${GREEN}🚀 Ready to deploy!${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}❌ Setup incomplete${NC}"
        return 1
    fi
}

# Main function
main() {
    echo "🔍 ArcDeploy Setup Validation"
    echo "============================="
    echo ""

    check_system
    echo ""
    check_dependencies
    echo ""
    check_hetzner_token
    echo ""
    check_cloud_init
    echo ""
    check_ssh_keys
    echo ""
    check_permissions
    echo ""
    check_connectivity

    show_summary
    show_recommendations
}

# Handle help
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    cat << EOF
ArcDeploy Setup Validation Script

USAGE:
    $0

DESCRIPTION:
    Validates your local setup for deploying ArcDeploy test servers.
    Checks dependencies, configuration, and connectivity.

CHECKS PERFORMED:
    ✓ Required tools (curl, jq, ssh)
    ✓ Hetzner Cloud API token
    ✓ Cloud-init configuration
    ✓ SSH key setup
    ✓ Script permissions
    ✓ Network connectivity

EXIT CODES:
    0 - All checks passed, ready to deploy
    1 - One or more critical checks failed

EXAMPLES:
    # Run validation
    $0

    # Fix common issues, then re-run
    apt install curl jq                           # Install dependencies
    export HETZNER_TOKEN="your-token"            # Set API token
    ssh-keygen -t ed25519 -C "your@email.com"    # Generate SSH key
    # Edit cloud-init.yaml with your public key
    $0                                            # Re-validate

For more help, visit: https://github.com/Pocklabs/ArcDeploy
EOF
    exit 0
fi

main "$@"
