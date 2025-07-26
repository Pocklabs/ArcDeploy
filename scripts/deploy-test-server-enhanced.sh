#!/bin/bash

# ArcDeploy Enhanced Test Server Deployment Script
# Enhanced version with improved API handling, validation, and error recovery
# Author: PockLabs ArcDeploy Team
# Version: 2.0.0

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly CLOUD_INIT_FILE="$PROJECT_ROOT/cloud-init.yaml"
readonly API_BASE_URL="https://api.hetzner.cloud/v1"
readonly DEFAULT_IMAGE="ubuntu-22.04"
readonly HEALTH_CHECK_TIMEOUT=600  # 10 minutes
readonly HEALTH_CHECK_INTERVAL=15  # 15 seconds

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Global variables
SERVER_NAME=""
SERVER_TYPE="cx31"
LOCATION="fsn1"
SERVER_ID=""
ACTION_ID=""
SERVER_IP=""
VERBOSE=false
DRY_RUN=false

# Server type mapping with current pricing (2024)
declare -A SERVER_TYPES=(
    ["small"]="cx11"    # 1 vCPU, 4GB RAM - €4.15/month
    ["medium"]="cx21"   # 2 vCPU, 8GB RAM - €8.25/month
    ["standard"]="cx31" # 2 vCPU, 8GB RAM - €13.10/month (recommended)
    ["large"]="cx41"    # 4 vCPU, 16GB RAM - €26.20/month
    ["xlarge"]="cx51"   # 8 vCPU, 32GB RAM - €52.40/month
)

# Location mapping
declare -A LOCATIONS=(
    ["fsn1"]="Falkenstein 1, Germany"
    ["nbg1"]="Nuremberg 1, Germany"
    ["hel1"]="Helsinki 1, Finland"
    ["ash"]="Ashburn, VA, USA"
    ["hil"]="Hillsboro, OR, USA"
)

# Usage information
usage() {
    cat << EOF
Enhanced ArcDeploy Test Server Deployment Script v2.0.0

USAGE:
    $SCRIPT_NAME [OPTIONS] <server_name> [server_type] [location]

ARGUMENTS:
    server_name     Name for the test server (required)
    server_type     Server size or type (default: cx31)
    location        Datacenter location (default: fsn1)

SERVER TYPES:
    small      cx11 - 1 vCPU, 4GB RAM  (€4.15/month)
    medium     cx21 - 2 vCPU, 8GB RAM  (€8.25/month)
    standard   cx31 - 2 vCPU, 8GB RAM  (€13.10/month) [RECOMMENDED]
    large      cx41 - 4 vCPU, 16GB RAM (€26.20/month)
    xlarge     cx51 - 8 vCPU, 32GB RAM (€52.40/month)

    Or use direct types: cx11, cx21, cx31, cx41, cx51

LOCATIONS:
    fsn1    Falkenstein 1, Germany [DEFAULT]
    nbg1    Nuremberg 1, Germany
    hel1    Helsinki 1, Finland
    ash     Ashburn, VA, USA
    hil     Hillsboro, OR, USA

OPTIONS:
    --delete <name>     Delete a test server
    --list              List all test servers
    --status <name>     Check server status
    --logs <name>       Show cloud-init logs
    --verbose           Enable verbose output
    --dry-run           Show what would be done without executing
    --help              Show this help message

EXAMPLES:
    # Create standard server
    $SCRIPT_NAME my-test-server

    # Create large server in US
    $SCRIPT_NAME prod-test large ash

    # Create with specific type
    $SCRIPT_NAME dev-server cx41 nbg1

    # Management commands
    $SCRIPT_NAME --delete my-test-server
    $SCRIPT_NAME --list
    $SCRIPT_NAME --status my-test-server

ENVIRONMENT:
    HETZNER_TOKEN       Hetzner Cloud API token (required)
    ARCDEPLOY_SSH_KEY   SSH key name for server access

For more information, visit: https://github.com/Pocklabs/ArcDeploy
EOF
}

# Logging functions
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
    [[ "$VERBOSE" == true ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
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

print_verbose() {
    [[ "$VERBOSE" == true ]] && echo -e "${BLUE}[VERBOSE]${NC} $1"
}

# Enhanced API call function with retry logic
api_call() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local max_retries=3
    local retry_count=0
    local base_delay=2

    if [[ -z "$HETZNER_TOKEN" ]]; then
        print_error "HETZNER_TOKEN environment variable is not set"
        print_error "Please set your Hetzner Cloud API token:"
        print_error "  export HETZNER_TOKEN=your-token-here"
        exit 1
    fi

    while [ $retry_count -lt $max_retries ]; do
        print_verbose "API Call: $method $endpoint (attempt $((retry_count + 1))/$max_retries)"

        local curl_args=(
            -s
            -w "HTTPSTATUS:%{http_code}"
            -H "Authorization: Bearer $HETZNER_TOKEN"
            -H "Content-Type: application/json"
            -H "User-Agent: ArcDeploy-Enhanced/2.0.0"
            -X "$method"
        )

        if [[ -n "$data" ]]; then
            curl_args+=(-d "$data")
        fi

        local response
        response=$(curl "${curl_args[@]}" "$API_BASE_URL$endpoint" 2>/dev/null || echo "HTTPSTATUS:000")

        local http_code
        http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
        local body
        body=$(echo "$response" | sed -E 's/HTTPSTATUS:[0-9]*$//')

        print_verbose "HTTP Status: $http_code"

        case "$http_code" in
            200|201|204)
                echo "$body"
                return 0
                ;;
            429)
                print_warning "Rate limit exceeded, retrying in $((base_delay * (retry_count + 1))) seconds..."
                sleep $((base_delay * (retry_count + 1)))
                ;;
            5[0-9][0-9])
                print_warning "Server error ($http_code), retrying in $((base_delay * (retry_count + 1))) seconds..."
                sleep $((base_delay * (retry_count + 1)))
                ;;
            000)
                print_warning "Network error, retrying in $((base_delay * (retry_count + 1))) seconds..."
                sleep $((base_delay * (retry_count + 1)))
                ;;
            *)
                print_error "API request failed with HTTP $http_code"
                if echo "$body" | jq -e '.error' > /dev/null 2>&1; then
                    echo "$body" | jq -r '.error.message'
                else
                    echo "$body"
                fi
                return 1
                ;;
        esac

        retry_count=$((retry_count + 1))
    done

    print_error "API request failed after $max_retries attempts"
    return 1
}

# Enhanced dependency checking
check_dependencies() {
    local missing_deps=()

    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi

    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi

    if ! command -v ssh &> /dev/null; then
        missing_deps+=("ssh")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_error "Please install them:"
        print_error "  Ubuntu/Debian: apt-get install ${missing_deps[*]}"
        print_error "  MacOS: brew install ${missing_deps[*]}"
        exit 1
    fi

    print_verbose "All dependencies satisfied"
}

# Validate cloud-init file size and format
validate_cloud_init() {
    if [[ ! -f "$CLOUD_INIT_FILE" ]]; then
        print_error "Cloud-init file not found: $CLOUD_INIT_FILE"
        print_error "Please ensure the cloud-init.yaml file exists in the project root"
        exit 1
    fi

    local file_size
    file_size=$(wc -c < "$CLOUD_INIT_FILE")
    local max_size=65536  # 64KB limit for Hetzner Cloud

    if [ "$file_size" -gt "$max_size" ]; then
        print_error "Cloud-init file too large: ${file_size} bytes (max: ${max_size})"
        print_error "Please reduce the cloud-init configuration size"
        exit 1
    fi

    # Check if file starts with #cloud-config
    if ! head -n1 "$CLOUD_INIT_FILE" | grep -q "^#cloud-config"; then
        print_warning "Cloud-init file should start with '#cloud-config'"
    fi

    # Validate YAML syntax
    if command -v python3 &> /dev/null; then
        if ! python3 -c "import yaml; yaml.safe_load(open('$CLOUD_INIT_FILE'))" 2>/dev/null; then
            print_error "Invalid YAML syntax in cloud-init file"
            exit 1
        fi
    fi

    print_success "Cloud-init file validated (${file_size} bytes)"
}

# Validate server type against available options
validate_server_type() {
    local type="$1"

    print_status "Validating server type: $type"

    # Check if it's a mapped type first
    if [[ -n "${SERVER_TYPES[$type]:-}" ]]; then
        SERVER_TYPE="${SERVER_TYPES[$type]}"
        print_verbose "Mapped '$type' to '$SERVER_TYPE'"
        return 0
    fi

    # If it's already a direct type, validate against API
    local response
    response=$(api_call GET "/server_types")

    if ! echo "$response" | jq -e '.server_types' > /dev/null; then
        print_error "Failed to fetch server types from API"
        return 1
    fi

    local available_types
    available_types=$(echo "$response" | jq -r '.server_types[].name')

    if ! echo "$available_types" | grep -q "^${type}$"; then
        print_error "Server type '$type' not available"
        print_error "Available mapped types: ${!SERVER_TYPES[*]}"
        print_error "Available direct types:"
        echo "$available_types" | sed 's/^/  /'
        return 1
    fi

    SERVER_TYPE="$type"
    print_success "Server type '$type' validated"
}

# Validate location
validate_location() {
    local location="$1"

    print_status "Validating location: $location"

    local response
    response=$(api_call GET "/locations")

    if ! echo "$response" | jq -e '.locations' > /dev/null; then
        print_error "Failed to fetch locations from API"
        return 1
    fi

    local available_locations
    available_locations=$(echo "$response" | jq -r '.locations[].name')

    if ! echo "$available_locations" | grep -q "^${location}$"; then
        print_error "Location '$location' not available"
        print_error "Available locations:"
        echo "$response" | jq -r '.locations[] | "  \(.name) - \(.description)"'
        return 1
    fi

    print_success "Location '$location' validated"
}

# Check if server name is unique
check_server_name() {
    print_status "Checking server name uniqueness: $SERVER_NAME"

    local response
    response=$(api_call GET "/servers?name=${SERVER_NAME}")

    if ! echo "$response" | jq -e '.servers' > /dev/null; then
        print_error "Failed to check existing servers"
        return 1
    fi

    local server_count
    server_count=$(echo "$response" | jq '.servers | length')

    if [[ "$server_count" -gt 0 ]]; then
        print_error "Server with name '$SERVER_NAME' already exists"
        print_error "Please choose a different name or delete the existing server"
        return 1
    fi

    print_success "Server name '$SERVER_NAME' is available"
}

# Create server with enhanced error handling
create_server() {
    print_status "Creating server '$SERVER_NAME' with type '$SERVER_TYPE' in location '$LOCATION'..."

    if [[ "$DRY_RUN" == true ]]; then
        print_warning "DRY RUN - Would create server with following configuration:"
        echo "  Name: $SERVER_NAME"
        echo "  Type: $SERVER_TYPE"
        echo "  Location: $LOCATION"
        echo "  Image: $DEFAULT_IMAGE"
        echo "  Cloud-init: $CLOUD_INIT_FILE"
        return 0
    fi

    # Read cloud-init data
    local cloud_init_data
    cloud_init_data=$(cat "$CLOUD_INIT_FILE")

    # Prepare SSH keys array
    local ssh_keys_json="[]"
    if [[ -n "${ARCDEPLOY_SSH_KEY:-}" ]]; then
        ssh_keys_json=$(jq -n --arg key "$ARCDEPLOY_SSH_KEY" '[$key]')
        print_verbose "Using SSH key: $ARCDEPLOY_SSH_KEY"
    fi

    # Create JSON payload
    local payload
    payload=$(jq -n \
        --arg name "$SERVER_NAME" \
        --arg server_type "$SERVER_TYPE" \
        --arg location "$LOCATION" \
        --arg image "$DEFAULT_IMAGE" \
        --arg user_data "$cloud_init_data" \
        --argjson ssh_keys "$ssh_keys_json" \
        '{
            name: $name,
            server_type: $server_type,
            location: $location,
            image: $image,
            user_data: $user_data,
            ssh_keys: $ssh_keys,
            start_after_create: true,
            labels: {
                "created-by": "arcdeploy-enhanced",
                "project": "arcdeploy",
                "environment": "test",
                "version": "2.0.0"
            },
            public_net: {
                enable_ipv4: true,
                enable_ipv6: true
            }
        }')

    print_verbose "Payload prepared, making API request..."

    local response
    response=$(api_call POST "/servers" "$payload")

    if ! echo "$response" | jq -e '.server.id' > /dev/null; then
        print_error "Failed to create server - invalid response"
        echo "$response" | jq -r '.error.message // .'
        return 1
    fi

    SERVER_ID=$(echo "$response" | jq -r '.server.id')
    ACTION_ID=$(echo "$response" | jq -r '.action.id')

    print_success "Server creation initiated"
    print_success "  Server ID: $SERVER_ID"
    print_success "  Action ID: $ACTION_ID"
}

# Enhanced server status monitoring
wait_for_server() {
    print_status "Waiting for server to become ready..."

    local start_time
    start_time=$(date +%s)
    local max_wait=$HEALTH_CHECK_TIMEOUT

    while true; do
        local current_time
        current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        if [ $elapsed -gt $max_wait ]; then
            print_error "Timeout waiting for server (${max_wait}s)"
            return 1
        fi

        local response
        response=$(api_call GET "/servers/$SERVER_ID")

        if ! echo "$response" | jq -e '.server' > /dev/null; then
            print_error "Failed to check server status"
            return 1
        fi

        local status
        status=$(echo "$response" | jq -r '.server.status')

        local progress=$((elapsed * 100 / max_wait))
        echo -ne "\r${BLUE}[INFO]${NC} Server status: $status (${elapsed}s elapsed, ${progress}% of timeout)"

        case "$status" in
            "running")
                echo ""
                SERVER_IP=$(echo "$response" | jq -r '.server.public_net.ipv4.ip')
                print_success "Server is running!"
                print_success "  Public IP: $SERVER_IP"
                return 0
                ;;
            "initializing"|"starting")
                sleep $HEALTH_CHECK_INTERVAL
                ;;
            "error")
                echo ""
                print_error "Server creation failed"
                return 1
                ;;
            *)
                echo ""
                print_warning "Unknown server status: $status"
                sleep $HEALTH_CHECK_INTERVAL
                ;;
        esac
    done
}

# Test SSH connectivity
test_ssh_connection() {
    if [[ -z "$SERVER_IP" ]]; then
        print_error "No server IP available for SSH test"
        return 1
    fi

    print_status "Testing SSH connectivity to $SERVER_IP..."

    local ssh_port=2222  # ArcDeploy uses custom SSH port
    local max_attempts=12
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))

        if timeout 10 ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $ssh_port arcblock@$SERVER_IP "echo 'SSH test successful'" 2>/dev/null; then
            print_success "SSH connection successful!"
            return 0
        fi

        echo -ne "\r${BLUE}[INFO]${NC} SSH test attempt $attempt/$max_attempts..."
        sleep 15
    done

    echo ""
    print_warning "SSH connection test failed, but server may still be initializing"
    print_warning "Try connecting manually: ssh -p $ssh_port arcblock@$SERVER_IP"
}

# List all test servers
list_servers() {
    print_status "Fetching test servers..."

    local response
    response=$(api_call GET "/servers?label_selector=created-by=arcdeploy-enhanced")

    if ! echo "$response" | jq -e '.servers' > /dev/null; then
        print_error "Failed to fetch servers"
        return 1
    fi

    local server_count
    server_count=$(echo "$response" | jq '.servers | length')

    if [ "$server_count" -eq 0 ]; then
        print_warning "No ArcDeploy test servers found"
        return 0
    fi

    print_success "Found $server_count ArcDeploy test server(s):"
    echo ""
    printf "%-20s %-10s %-15s %-15s %-10s\n" "NAME" "TYPE" "LOCATION" "IP" "STATUS"
    printf "%-20s %-10s %-15s %-15s %-10s\n" "----" "----" "--------" "--" "------"

    echo "$response" | jq -r '.servers[] | "\(.name)|\(.server_type.name)|\(.datacenter.location.name)|\(.public_net.ipv4.ip // "pending")|\(.status)"' | \
    while IFS='|' read -r name type location ip status; do
        printf "%-20s %-10s %-15s %-15s %-10s\n" "$name" "$type" "$location" "$ip" "$status"
    done
}

# Delete server
delete_server() {
    local server_name="$1"

    print_status "Searching for server: $server_name"

    local response
    response=$(api_call GET "/servers?name=${server_name}")

    if ! echo "$response" | jq -e '.servers[0]' > /dev/null; then
        print_error "Server '$server_name' not found"
        return 1
    fi

    local server_id
    server_id=$(echo "$response" | jq -r '.servers[0].id')

    print_warning "This will permanently delete server '$server_name' (ID: $server_id)"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deletion cancelled"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_warning "DRY RUN - Would delete server '$server_name' (ID: $server_id)"
        return 0
    fi

    print_status "Deleting server..."

    local delete_response
    delete_response=$(api_call DELETE "/servers/$server_id")

    if echo "$delete_response" | jq -e '.action' > /dev/null; then
        print_success "Server deletion initiated"
    else
        print_error "Failed to delete server"
        return 1
    fi
}

# Show server status
show_server_status() {
    local server_name="$1"

    print_status "Fetching status for server: $server_name"

    local response
    response=$(api_call GET "/servers?name=${server_name}")

    if ! echo "$response" | jq -e '.servers[0]' > /dev/null; then
        print_error "Server '$server_name' not found"
        return 1
    fi

    local server
    server=$(echo "$response" | jq '.servers[0]')

    print_success "Server Status:"
    echo ""
    echo "$server" | jq -r '"Name: \(.name)
Type: \(.server_type.name) (\(.server_type.cores) vCPU, \(.server_type.memory)GB RAM)
Status: \(.status)
Location: \(.datacenter.location.description)
IPv4: \(.public_net.ipv4.ip // "none")
IPv6: \(.public_net.ipv6.ip // "none")
Created: \(.created)"'
}

# Main function
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                usage
                exit 0
                ;;
            --delete)
                if [[ -z "${2:-}" ]]; then
                    print_error "--delete requires a server name"
                    exit 1
                fi
                delete_server "$2"
                exit $?
                ;;
            --list)
                list_servers
                exit $?
                ;;
            --status)
                if [[ -z "${2:-}" ]]; then
                    print_error "--status requires a server name"
                    exit 1
                fi
                show_server_status "$2"
                exit $?
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --*)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                # Positional arguments
                if [[ -z "$SERVER_NAME" ]]; then
                    SERVER_NAME="$1"
                elif [[ -z "$SERVER_TYPE" || "$SERVER_TYPE" == "cx31" ]]; then
                    SERVER_TYPE="$1"
                elif [[ -z "$LOCATION" || "$LOCATION" == "fsn1" ]]; then
                    LOCATION="$1"
                else
                    print_error "Too many arguments"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$SERVER_NAME" ]]; then
        print_error "Server name is required"
        usage
        exit 1
    fi

    # Run all validations
    check_dependencies
    validate_cloud_init
    validate_server_type "$SERVER_TYPE"
    validate_location "$LOCATION"
    check_server_name

    # Create and deploy server
    create_server

    if [[ "$DRY_RUN" == true ]]; then
        exit 0
    fi

    wait_for_server
    test_ssh_connection

    # Print final summary
    echo ""
    print_success "🎉 Server deployment completed!"
    print_success "Server Details:"
    echo "  Name: $SERVER_NAME"
    echo "  Type: $SERVER_TYPE"
    echo "  Location: $LOCATION"
    echo "  IP: $SERVER_IP"
    echo ""
    print_success "Connection Information:"
    echo "  SSH: ssh -p 2222 arcblock@$SERVER_IP"
    echo "  Web Interface: http://$SERVER_IP:8080"
    echo "  Secure Web: https://$SERVER_IP:8443"
    echo ""
    print_success "Management Commands:"
    echo "  Check status: $SCRIPT_NAME --status $SERVER_NAME"
    echo "  Delete server: $SCRIPT_NAME --delete $SERVER_NAME"
    echo "  List all: $SCRIPT_NAME --list"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
