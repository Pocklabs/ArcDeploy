#!/bin/bash

# ArcDeploy Quick Deploy Script
# Simple wrapper for deploying test servers with sensible defaults

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DEPLOY_SCRIPT="$SCRIPT_DIR/deploy-test-server.sh"

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

check_token() {
    if [[ -z "${HETZNER_TOKEN:-}" ]]; then
        print_error "HETZNER_TOKEN not set!"
        echo ""
        echo "Please set your Hetzner Cloud API token:"
        echo "  export HETZNER_TOKEN=\"your-token-here\""
        echo ""
        echo "Get your token from: https://console.hetzner.cloud/"
        echo "  1. Go to Hetzner Cloud Console"
        echo "  2. Select your project"
        echo "  3. Go to Security → API Tokens"
        echo "  4. Generate new token"
        exit 1
    fi
}

main() {
    echo "🚀 ArcDeploy Quick Deploy"
    echo "========================"
    echo ""

    # Check for token
    check_token

    # Check if main script exists
    if [[ ! -f "$DEPLOY_SCRIPT" ]]; then
        print_error "Deploy script not found: $DEPLOY_SCRIPT"
        exit 1
    fi

    # Make script executable
    chmod +x "$DEPLOY_SCRIPT"

    case "${1:-deploy}" in
        deploy|"")
            print_info "Deploying with optimal defaults..."
            print_info "Server type: cx31 (2 vCPU, 8GB RAM) - Perfect for testing"
            print_info "Location: fsn1 (Germany) - Fast and reliable"
            echo ""

            # Generate a friendly server name
            local server_name="arcdeploy-$(date +%m%d-%H%M)"

            exec "$DEPLOY_SCRIPT" "$server_name" "cx31" "fsn1"
            ;;

        small)
            print_info "Deploying minimal test server..."
            print_info "Server type: cx11 (1 vCPU, 4GB RAM) - Cheapest option"
            echo ""

            local server_name="arcdeploy-small-$(date +%m%d-%H%M)"
            exec "$DEPLOY_SCRIPT" "$server_name" "cx11" "fsn1"
            ;;

        large)
            print_info "Deploying large test server..."
            print_info "Server type: cx41 (4 vCPU, 16GB RAM) - For heavy testing"
            echo ""

            local server_name="arcdeploy-large-$(date +%m%d-%H%M)"
            exec "$DEPLOY_SCRIPT" "$server_name" "cx41" "fsn1"
            ;;

        us)
            print_info "Deploying to US location..."
            print_info "Location: ash (Ashburn, VA)"
            echo ""

            local server_name="arcdeploy-us-$(date +%m%d-%H%M)"
            exec "$DEPLOY_SCRIPT" "$server_name" "cx31" "ash"
            ;;

        delete)
            if [[ -z "${2:-}" ]]; then
                print_error "Server name required for deletion"
                echo "Usage: $0 delete <server_name>"
                exit 1
            fi
            exec "$DEPLOY_SCRIPT" --delete "$2"
            ;;

        list)
            print_info "Listing ArcDeploy test servers..."

            if command -v curl >/dev/null && command -v jq >/dev/null; then
                curl -s -H "Authorization: Bearer $HETZNER_TOKEN" \
                    "https://api.hetzner.cloud/v1/servers?label_selector=created-by=arcdeploy-test-script" | \
                jq -r '.servers[] | "  \(.name) (\(.id)) - \(.public_net.ipv4.ip) - \(.status)"'
            else
                print_warning "curl and jq required for listing servers"
                print_info "Install with: apt install curl jq"
            fi
            ;;

        help|--help|-h)
            cat << EOF
ArcDeploy Quick Deploy

USAGE:
    $0 [COMMAND] [ARGS]

COMMANDS:
    deploy, (default)  Deploy standard test server (cx31, Germany)
    small              Deploy minimal server (cx11, cheapest)
    large              Deploy large server (cx41, for heavy testing)
    us                 Deploy to US location (Ashburn, VA)
    delete <name>      Delete a test server
    list               List all ArcDeploy test servers
    help               Show this help

EXAMPLES:
    # Quick deploy with defaults
    export HETZNER_TOKEN="your-token"
    $0

    # Deploy different sizes
    $0 small     # Minimal server
    $0 large     # High-performance server
    $0 us        # Deploy to US

    # Manage servers
    $0 list                    # List all test servers
    $0 delete my-server-name   # Delete specific server

REQUIREMENTS:
    - Hetzner Cloud API token in HETZNER_TOKEN
    - SSH key configured in cloud-init.yaml
    - curl and jq installed

For advanced options, use deploy-test-server.sh directly.
EOF
            ;;

        *)
            print_error "Unknown command: $1"
            echo ""
            echo "Available commands: deploy, small, large, us, delete, list, help"
            echo "Run '$0 help' for more information"
            exit 1
            ;;
    esac
}

main "$@"
