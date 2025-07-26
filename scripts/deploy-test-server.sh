#!/bin/bash

# ArcDeploy Test Server Deployment Script
# Automatically deploys a test server to Hetzner Cloud using cloud-init
#
# Usage:
#   ./deploy-test-server.sh [server_name] [server_type] [location]
#
# Environment Variables Required:
#   HETZNER_TOKEN - Your Hetzner Cloud API token
#
# Example:
#   export HETZNER_TOKEN="your-token-here"
#   ./deploy-test-server.sh my-test-server cx31 fsn1

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CLOUD_INIT_FILE="${SCRIPT_DIR}/cloud-init.yaml"
readonly DEFAULT_SERVER_NAME="arcdeploy-test-$(date +%s)"
readonly DEFAULT_SERVER_TYPE="cx31"
readonly DEFAULT_LOCATION="fsn1"
readonly DEFAULT_IMAGE="ubuntu-22.04"
readonly API_BASE_URL="https://api.hetzner.cloud/v1"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Parse command line arguments
SERVER_NAME="${1:-$DEFAULT_SERVER_NAME}"
SERVER_TYPE="${2:-$DEFAULT_SERVER_TYPE}"
LOCATION="${3:-$DEFAULT_LOCATION}"

# Global variables
SERVER_ID=""
SERVER_IP=""
ACTION_ID=""

# Function to print colored output
print_status() {
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

# Function to make API calls
api_call() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [[ -z "$HETZNER_TOKEN" ]]; then
        print_error "HETZNER_TOKEN environment variable is not set"
        exit 1
    fi

    local curl_args=(
        -s
        -H "Authorization: Bearer $HETZNER_TOKEN"
        -H "Content-Type: application/json"
        -X "$method"
    )

    if [[ -n "$data" ]]; then
        curl_args+=(-d "$data")
    fi

    curl "${curl_args[@]}" "$API_BASE_URL$endpoint"
}

# Function to check if jq is available
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        print_error "jq is required but not installed. Please install jq:"
        print_error "  Ubuntu/Debian: apt-get install jq"
        print_error "  MacOS: brew install jq"
        print_error "  Other: https://stedolan.github.io/jq/download/"
        exit 1
    fi

    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed."
        exit 1
    fi
}

# Function to validate cloud-init file
validate_cloud_init() {
    if [[ ! -f "$CLOUD_INIT_FILE" ]]; then
        print_error "Cloud-init file not found: $CLOUD_INIT_FILE"
        exit 1
    fi

    # Check if SSH key placeholder is still present
    if grep -q "ReplaceWithYourActualEd25519PublicKey" "$CLOUD_INIT_FILE"; then
        print_error "SSH key placeholder found in cloud-init.yaml"
        print_error "Please replace 'ReplaceWithYourActualEd25519PublicKey' with your actual SSH public key"
        print_error ""
        print_error "Generate a new SSH key with:"
        print_error "  ssh-keygen -t ed25519 -C \"your-email@example.com\""
        print_error "  cat ~/.ssh/id_ed25519.pub"
        exit 1
    fi

    print_success "Cloud-init file validated"
}

# Function to check server type availability
check_server_type() {
    print_status "Checking server type availability..."

    local response
    response=$(api_call GET "/server_types")

    if ! echo "$response" | jq -r '.server_types[].name' | grep -q "^${SERVER_TYPE}$"; then
        print_error "Server type '$SERVER_TYPE' not found"
        print_error "Available server types:"
        echo "$response" | jq -r '.server_types[] | "  \(.name) - \(.description) (\(.cores) vCPU, \(.memory)GB RAM, \(.disk)GB disk)"'
        exit 1
    fi

    print_success "Server type '$SERVER_TYPE' is available"
}

# Function to check location availability
check_location() {
    print_status "Checking location availability..."

    local response
    response=$(api_call GET "/locations")

    if ! echo "$response" | jq -r '.locations[].name' | grep -q "^${LOCATION}$"; then
        print_error "Location '$LOCATION' not found"
        print_error "Available locations:"
        echo "$response" | jq -r '.locations[] | "  \(.name) - \(.description)"'
        exit 1
    fi

    print_success "Location '$LOCATION' is available"
}

# Function to check if server name is unique
check_server_name() {
    print_status "Checking server name uniqueness..."

    local response
    response=$(api_call GET "/servers?name=${SERVER_NAME}")

    local server_count
    server_count=$(echo "$response" | jq '.servers | length')

    if [[ "$server_count" -gt 0 ]]; then
        print_error "Server with name '$SERVER_NAME' already exists"
        print_error "Please choose a different name or delete the existing server"
        exit 1
    fi

    print_success "Server name '$SERVER_NAME' is available"
}

# Function to create server
create_server() {
    print_status "Creating server '$SERVER_NAME'..."

    # Read and encode cloud-init file
    local cloud_init_data
    cloud_init_data=$(cat "$CLOUD_INIT_FILE")

    # Create JSON payload
    local payload
    payload=$(jq -n \
        --arg name "$SERVER_NAME" \
        --arg server_type "$SERVER_TYPE" \
        --arg location "$LOCATION" \
        --arg image "$DEFAULT_IMAGE" \
        --arg user_data "$cloud_init_data" \
        '{
            name: $name,
            server_type: $server_type,
            location: $location,
            image: $image,
            user_data: $user_data,
            start_after_create: true,
            labels: {
                "created-by": "arcdeploy-test-script",
                "project": "arcdeploy",
                "environment": "test"
            }
        }')

    local response
    response=$(api_call POST "/servers" "$payload")

    # Check for errors
    if echo "$response" | jq -e '.error' > /dev/null; then
        print_error "Failed to create server:"
        echo "$response" | jq -r '.error.message'
        exit 1
    fi

    SERVER_ID=$(echo "$response" | jq -r '.server.id')
    ACTION_ID=$(echo "$response" | jq -r '.action.id')

    print_success "Server creation initiated (ID: $SERVER_ID, Action: $ACTION_ID)"
}

# Function to wait for action completion
wait_for_action() {
    local action_id="$1"
    local description="$2"

    print_status "Waiting for $description..."

    local status="running"
    local progress=0
    local start_time
    start_time=$(date +%s)

    while [[ "$status" == "running" ]]; do
        local response
        response=$(api_call GET "/actions/$action_id")

        status=$(echo "$response" | jq -r '.action.status')
        progress=$(echo "$response" | jq -r '.action.progress // 0')

        local current_time
        current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        printf "\r${BLUE}[INFO]${NC} %s... %d%% (%ds elapsed)" "$description" "$progress" "$elapsed"

        if [[ "$status" == "success" ]]; then
            printf "\n"
            print_success "$description completed successfully"
            return 0
        elif [[ "$status" == "error" ]]; then
            printf "\n"
            print_error "$description failed:"
            echo "$response" | jq -r '.action.error.message'
            return 1
        fi

        sleep 5
    done
}

# Function to get server information
get_server_info() {
    print_status "Retrieving server information..."

    local response
    response=$(api_call GET "/servers/$SERVER_ID")

    SERVER_IP=$(echo "$response" | jq -r '.server.public_net.ipv4.ip')
    local status
    status=$(echo "$response" | jq -r '.server.status')

    print_success "Server information retrieved:"
    echo "  Name: $SERVER_NAME"
    echo "  ID: $SERVER_ID"
    echo "  IP: $SERVER_IP"
    echo "  Status: $status"
    echo "  Type: $SERVER_TYPE"
    echo "  Location: $LOCATION"
}

# Function to test SSH connectivity
test_ssh_connection() {
    print_status "Testing SSH connectivity..."

    local max_attempts=30
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -p 2222 "arcblock@$SERVER_IP" "echo 'SSH connection successful'" 2>/dev/null; then
            print_success "SSH connection successful"
            return 0
        fi

        printf "\r${BLUE}[INFO]${NC} SSH attempt %d/%d..." "$attempt" "$max_attempts"
        attempt=$((attempt + 1))
        sleep 10
    done

    printf "\n"
    print_warning "SSH connection could not be established"
    print_warning "The server may still be initializing. You can try connecting manually:"
    print_warning "  ssh -p 2222 arcblock@$SERVER_IP"
}

# Function to check cloud-init status
check_cloud_init_status() {
    print_status "Checking cloud-init status..."

    if ssh -o ConnectTimeout=30 -o StrictHostKeyChecking=no -p 2222 "arcblock@$SERVER_IP" "sudo cloud-init status --long" 2>/dev/null; then
        print_success "Cloud-init status retrieved"
    else
        print_warning "Could not retrieve cloud-init status"
        print_warning "You can check manually with:"
        print_warning "  ssh -p 2222 arcblock@$SERVER_IP"
        print_warning "  sudo cloud-init status --long"
    fi
}

# Function to provide usage instructions
show_usage_instructions() {
    print_success "Server deployment completed!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 ArcDeploy Test Server Ready"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📋 Server Details:"
    echo "   Name: $SERVER_NAME"
    echo "   IP: $SERVER_IP"
    echo "   SSH Port: 2222"
    echo "   User: arcblock"
    echo ""
    echo "🔐 Access Commands:"
    echo "   SSH: ssh -p 2222 arcblock@$SERVER_IP"
    echo "   Web Interface: http://$SERVER_IP:8080"
    echo "   Admin Panel: http://$SERVER_IP:8080/.well-known/server/admin/"
    echo ""
    echo "📊 Monitoring Commands:"
    echo "   Check cloud-init: ssh -p 2222 arcblock@$SERVER_IP 'sudo cloud-init status --long'"
    echo "   Check service: ssh -p 2222 arcblock@$SERVER_IP 'sudo systemctl status blocklet-server'"
    echo "   View logs: ssh -p 2222 arcblock@$SERVER_IP 'sudo journalctl -u blocklet-server -f'"
    echo "   Health check: ssh -p 2222 arcblock@$SERVER_IP '/opt/blocklet-server/healthcheck.sh'"
    echo ""
    echo "🗑️  Cleanup (when done testing):"
    echo "   ./deploy-test-server.sh --delete $SERVER_NAME"
    echo "   # Or manually: curl -X DELETE -H \"Authorization: Bearer \$HETZNER_TOKEN\" \\\"
    echo "     \"https://api.hetzner.cloud/v1/servers/$SERVER_ID\""
    echo ""
    echo "💡 Next Steps:"
    echo "   1. Wait 5-10 minutes for full installation"
    echo "   2. Access the web interface to complete setup"
    echo "   3. Test blocklet functionality"
    echo "   4. Review logs for any issues"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Function to delete server
delete_server() {
    local server_name="$1"

    print_status "Looking up server '$server_name'..."

    local response
    response=$(api_call GET "/servers?name=${server_name}")

    local server_count
    server_count=$(echo "$response" | jq '.servers | length')

    if [[ "$server_count" -eq 0 ]]; then
        print_error "Server '$server_name' not found"
        exit 1
    fi

    local server_id
    server_id=$(echo "$response" | jq -r '.servers[0].id')

    print_warning "This will permanently delete server '$server_name' (ID: $server_id)"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deletion cancelled"
        exit 0
    fi

    print_status "Deleting server..."

    local delete_response
    delete_response=$(api_call DELETE "/servers/$server_id")

    if echo "$delete_response" | jq -e '.error' > /dev/null; then
        print_error "Failed to delete server:"
        echo "$delete_response" | jq -r '.error.message'
        exit 1
    fi

    print_success "Server deletion initiated"

    if echo "$delete_response" | jq -e '.action' > /dev/null; then
        local delete_action_id
        delete_action_id=$(echo "$delete_response" | jq -r '.action.id')
        wait_for_action "$delete_action_id" "Server deletion"
    fi

    print_success "Server '$server_name' deleted successfully"
}

# Function to show help
show_help() {
    cat << EOF
ArcDeploy Test Server Deployment Script

USAGE:
    $0 [OPTIONS] [server_name] [server_type] [location]
    $0 --delete <server_name>
    $0 --help

DESCRIPTION:
    Automatically deploys a test server to Hetzner Cloud using the ArcDeploy
    cloud-init configuration. The script handles server creation, monitors
    the deployment process, and provides connection details.

ARGUMENTS:
    server_name     Name for the test server (default: arcdeploy-test-<timestamp>)
    server_type     Hetzner server type (default: cx31)
    location        Hetzner location (default: fsn1)

OPTIONS:
    --delete <name> Delete a previously created test server
    --help          Show this help message

ENVIRONMENT VARIABLES:
    HETZNER_TOKEN   Required. Your Hetzner Cloud API token
                    Get it from: https://console.hetzner.cloud/

EXAMPLES:
    # Deploy with defaults
    export HETZNER_TOKEN="your-token-here"
    $0

    # Deploy with custom settings
    $0 my-test-server cx41 nbg1

    # Delete a test server
    $0 --delete my-test-server

PREREQUISITES:
    1. Hetzner Cloud account and API token
    2. SSH key configured in cloud-init.yaml (replace placeholder)
    3. jq and curl installed
    4. Network access to Hetzner Cloud API

COMMON SERVER TYPES:
    cx11    (1 vCPU, 4GB RAM, 40GB disk)   - €4.15/month
    cx21    (2 vCPU, 8GB RAM, 80GB disk)   - €8.30/month
    cx31    (2 vCPU, 8GB RAM, 80GB disk)   - €13.10/month  [RECOMMENDED]
    cx41    (4 vCPU, 16GB RAM, 160GB disk) - €26.20/month
    cx51    (8 vCPU, 32GB RAM, 320GB disk) - €52.40/month

COMMON LOCATIONS:
    fsn1    Falkenstein, Germany
    nbg1    Nuremberg, Germany
    hel1    Helsinki, Finland
    ash     Ashburn, Virginia, USA
    hil     Hillsboro, Oregon, USA

For more information, visit: https://github.com/Pocklabs/ArcDeploy
EOF
}

# Main function
main() {
    # Handle special arguments
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --delete)
            if [[ -z "${2:-}" ]]; then
                print_error "Server name required for deletion"
                print_error "Usage: $0 --delete <server_name>"
                exit 1
            fi
            check_dependencies
            delete_server "$2"
            exit 0
            ;;
    esac

    # Print header
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 ArcDeploy Test Server Deployment"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Configuration:"
    echo "  Server Name: $SERVER_NAME"
    echo "  Server Type: $SERVER_TYPE"
    echo "  Location: $LOCATION"
    echo "  Image: $DEFAULT_IMAGE"
    echo ""

    # Run deployment steps
    check_dependencies
    validate_cloud_init
    check_server_type
    check_location
    check_server_name
    create_server

    # Wait for server creation
    if ! wait_for_action "$ACTION_ID" "Server creation"; then
        print_error "Server creation failed"
        exit 1
    fi

    get_server_info

    # Wait a bit for the server to fully start
    print_status "Waiting for server to finish booting..."
    sleep 30

    test_ssh_connection
    check_cloud_init_status
    show_usage_instructions
}

# Run main function with all arguments
main "$@"
