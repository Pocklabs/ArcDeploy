#!/bin/bash

# Hetzner Cloud Firewall Setup Script for Arcblock Blocklet Server
# This script creates and applies firewall rules via Hetzner Cloud API

set -euo pipefail

# Configuration
FIREWALL_NAME="blocklet-server-firewall"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if API token is provided
if [ -z "${HETZNER_API_TOKEN:-}" ]; then
    error "HETZNER_API_TOKEN environment variable is required"
    echo "Usage: export HETZNER_API_TOKEN='your-token-here' && ./hetzner-firewall-setup.sh [SERVER_NAME]"
    echo "Or: HETZNER_API_TOKEN='your-token' ./hetzner-firewall-setup.sh [SERVER_NAME]"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    error "jq is required but not installed. Please install jq first."
    echo "Ubuntu/Debian: sudo apt-get install jq"
    echo "CentOS/RHEL: sudo yum install jq"
    exit 1
fi

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    error "curl is required but not installed."
    exit 1
fi

# API Base URL
API_BASE="https://api.hetzner.cloud/v1"

# Function to make API calls
api_call() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    
    local curl_args=(
        -s
        -X "$method"
        -H "Authorization: Bearer $HETZNER_API_TOKEN"
        -H "Content-Type: application/json"
    )
    
    if [ -n "$data" ]; then
        curl_args+=(-d "$data")
    fi
    
    curl "${curl_args[@]}" "$API_BASE$endpoint"
}

# Check if firewall already exists
check_existing_firewall() {
    log "Checking for existing firewall: $FIREWALL_NAME"
    
    local response
    response=$(api_call "GET" "/firewalls")
    
    local firewall_id
    firewall_id=$(echo "$response" | jq -r ".firewalls[] | select(.name == \"$FIREWALL_NAME\") | .id")
    
    if [ -n "$firewall_id" ] && [ "$firewall_id" != "null" ]; then
        echo "$firewall_id"
        return 0
    else
        return 1
    fi
}

# Create firewall with rules
create_firewall() {
    log "Creating firewall: $FIREWALL_NAME"
    
    local firewall_config
    read -r -d '' firewall_config << 'EOF' || true
{
  "name": "FIREWALL_NAME_PLACEHOLDER",
  "labels": {
    "service": "blocklet-server",
    "environment": "production",
    "managed-by": "script"
  },
  "rules": [
    {
      "direction": "in",
      "port": "2222",
      "protocol": "tcp",
      "source_ips": ["0.0.0.0/0", "::/0"],
      "description": "SSH Access"
    },
    {
      "direction": "in", 
      "port": "8080",
      "protocol": "tcp",
      "source_ips": ["0.0.0.0/0", "::/0"],
      "description": "Blocklet Server HTTP Interface"
    },
    {
      "direction": "in", 
      "port": "8443",
      "protocol": "tcp",
      "source_ips": ["0.0.0.0/0", "::/0"],
      "description": "Blocklet Server HTTPS Interface"
    },
    {
      "direction": "in",
      "port": "80", 
      "protocol": "tcp",
      "source_ips": ["0.0.0.0/0", "::/0"],
      "description": "HTTP Traffic"
    },
    {
      "direction": "in",
      "port": "443",
      "protocol": "tcp", 
      "source_ips": ["0.0.0.0/0", "::/0"],
      "description": "HTTPS Traffic"
    }
  ]
}
EOF
    
    # Replace placeholder with actual firewall name
    firewall_config=$(echo "$firewall_config" | sed "s/FIREWALL_NAME_PLACEHOLDER/$FIREWALL_NAME/g")
    
    local response
    response=$(api_call "POST" "/firewalls" "$firewall_config")
    
    local firewall_id
    firewall_id=$(echo "$response" | jq -r '.firewall.id')
    
    if [ -n "$firewall_id" ] && [ "$firewall_id" != "null" ]; then
        success "Firewall created successfully with ID: $firewall_id"
        echo "$firewall_id"
        return 0
    else
        error "Failed to create firewall"
        echo "Response: $response" >&2
        return 1
    fi
}

# Get server ID by name
get_server_id() {
    local server_name="$1"
    log "Looking up server: $server_name"
    
    local response
    response=$(api_call "GET" "/servers")
    
    local server_id
    server_id=$(echo "$response" | jq -r ".servers[] | select(.name == \"$server_name\") | .id")
    
    if [ -n "$server_id" ] && [ "$server_id" != "null" ]; then
        log "Found server '$server_name' with ID: $server_id"
        echo "$server_id"
        return 0
    else
        error "Server '$server_name' not found"
        return 1
    fi
}

# Apply firewall to server
apply_firewall_to_server() {
    local firewall_id="$1"
    local server_id="$2"
    
    log "Applying firewall to server..."
    
    local apply_config
    apply_config=$(cat << EOF
{
  "resources": [
    {
      "server": {
        "id": $server_id
      },
      "type": "server"
    }
  ]
}
EOF
)
    
    local response
    response=$(api_call "POST" "/firewalls/$firewall_id/actions/apply_to_resources" "$apply_config")
    
    local action_id
    action_id=$(echo "$response" | jq -r '.action.id // .actions[0].id // empty')
    
    if [ -n "$action_id" ] && [ "$action_id" != "null" ]; then
        success "Firewall application initiated. Action ID: $action_id"
        
        # Wait for action to complete
        wait_for_action "$action_id"
    else
        error "Failed to apply firewall to server"
        echo "Response: $response" >&2
        return 1
    fi
}

# Wait for action to complete
wait_for_action() {
    local action_id="$1"
    log "Waiting for action $action_id to complete..."
    
    local attempts=0
    local max_attempts=30
    
    while [ $attempts -lt $max_attempts ]; do
        local response
        response=$(api_call "GET" "/actions/$action_id")
        
        local status
        status=$(echo "$response" | jq -r '.action.status')
        
        case "$status" in
            "success")
                success "Action completed successfully"
                return 0
                ;;
            "error")
                error "Action failed"
                echo "Response: $response" >&2
                return 1
                ;;
            "running")
                log "Action still running... (attempt $((attempts + 1))/$max_attempts)"
                sleep 5
                attempts=$((attempts + 1))
                ;;
            *)
                warning "Unknown action status: $status"
                sleep 5
                attempts=$((attempts + 1))
                ;;
        esac
    done
    
    error "Action did not complete within expected time"
    return 1
}

# List servers
list_servers() {
    log "Available servers:"
    
    local response
    response=$(api_call "GET" "/servers")
    
    echo "$response" | jq -r '.servers[] | "  - \(.name) (ID: \(.id), IP: \(.public_net.ipv4.ip))"'
}

# Show firewall status
show_firewall_status() {
    local firewall_id="$1"
    
    log "Firewall configuration:"
    
    local response
    response=$(api_call "GET" "/firewalls/$firewall_id")
    
    echo "$response" | jq -r '
        "Name: " + .firewall.name,
        "ID: " + (.firewall.id | tostring),
        "Rules:",
        (.firewall.rules[] | "  - " + .direction + " " + .protocol + "/" + .port + " from " + (.source_ips | join(", ")) + " (" + .description + ")"),
        "Applied to servers:",
        (if .firewall.applied_to | length > 0 then
            (.firewall.applied_to[] | "  - " + .server.name + " (" + (.server.id | tostring) + ")")
        else
            "  - No servers"
        end)
    '
}

# Create restrictive SSH firewall
create_restrictive_firewall() {
    local your_ip="$1"
    log "Creating restrictive firewall for IP: $your_ip"
    
    local firewall_config
    read -r -d '' firewall_config << EOF || true
{
  "name": "${FIREWALL_NAME}-restrictive",
  "labels": {
    "service": "blocklet-server",
    "environment": "production", 
    "managed-by": "script",
    "access": "restrictive"
  },
  "rules": [
    {
      "direction": "in",
      "port": "2222", 
      "protocol": "tcp",
      "source_ips": ["$your_ip/32"],
      "description": "SSH Access - Restricted IP"
    },
    {
      "direction": "in",
      "port": "8080",
      "protocol": "tcp", 
      "source_ips": ["0.0.0.0/0", "::/0"],
      "description": "Blocklet Server HTTP Interface"
    },
    {
      "direction": "in",
      "port": "8443",
      "protocol": "tcp", 
      "source_ips": ["0.0.0.0/0", "::/0"],
      "description": "Blocklet Server HTTPS Interface"
    },
    {
      "direction": "in",
      "port": "80",
      "protocol": "tcp",
      "source_ips": ["0.0.0.0/0", "::/0"],
      "description": "HTTP Traffic"
    },
    {
      "direction": "in",
      "port": "443",
      "protocol": "tcp",
      "source_ips": ["0.0.0.0/0", "::/0"],
      "description": "HTTPS Traffic"
    }
  ]
}
EOF
    
    local response
    response=$(api_call "POST" "/firewalls" "$firewall_config")
    
    local firewall_id
    firewall_id=$(echo "$response" | jq -r '.firewall.id')
    
    if [ -n "$firewall_id" ] && [ "$firewall_id" != "null" ]; then
        success "Restrictive firewall created successfully with ID: $firewall_id"
        echo "$firewall_id"
        return 0
    else
        error "Failed to create restrictive firewall"
        echo "Response: $response" >&2
        return 1
    fi
}

# Main execution
main() {
    local server_name="${1:-}"
    local mode="${2:-open}"
    
    echo "=================================================="
    echo "Hetzner Cloud Firewall Setup for Blocklet Server"
    echo "=================================================="
    echo
    
    # Show usage if no server name provided
    if [ -z "$server_name" ]; then
        echo "Usage: $0 <server_name> [mode]"
        echo
        echo "Modes:"
        echo "  open        - Allow access from anywhere (default)"
        echo "  restrictive - Restrict SSH to your current IP"
        echo "  list        - List available servers"
        echo "  status      - Show firewall status"
        echo
        echo "Examples:"
        echo "  $0 blocklet-server"
        echo "  $0 blocklet-server restrictive"
        echo "  $0 list"
        echo
        exit 1
    fi
    
    # Handle special modes
    case "$server_name" in
        "list")
            list_servers
            exit 0
            ;;
        "status")
            if firewall_id=$(check_existing_firewall); then
                show_firewall_status "$firewall_id"
            else
                warning "No firewall found with name: $FIREWALL_NAME"
            fi
            exit 0
            ;;
    esac
    
    # Get server ID
    local server_id
    if ! server_id=$(get_server_id "$server_name"); then
        echo
        echo "Available servers:"
        list_servers
        exit 1
    fi
    
    # Check for existing firewall
    local firewall_id
    if firewall_id=$(check_existing_firewall); then
        warning "Firewall '$FIREWALL_NAME' already exists with ID: $firewall_id"
        
        # Check if already applied to server
        local response
        response=$(api_call "GET" "/firewalls/$firewall_id")
        
        local applied_servers
        applied_servers=$(echo "$response" | jq -r ".firewall.applied_to[] | select(.server.id == $server_id) | .server.name")
        
        if [ -n "$applied_servers" ]; then
            success "Firewall is already applied to server '$server_name'"
            show_firewall_status "$firewall_id"
            exit 0
        else
            log "Applying existing firewall to server..."
            apply_firewall_to_server "$firewall_id" "$server_id"
        fi
    else
        # Create new firewall based on mode
        case "$mode" in
            "restrictive")
                log "Getting your current IP address..."
                local your_ip
                your_ip=$(curl -s https://ipv4.icanhazip.com || curl -s https://api.ipify.org)
                
                if [ -n "$your_ip" ]; then
                    log "Your IP address: $your_ip"
                    FIREWALL_NAME="${FIREWALL_NAME}-restrictive"
                    firewall_id=$(create_restrictive_firewall "$your_ip")
                else
                    error "Could not determine your IP address"
                    exit 1
                fi
                ;;
            "open"|*)
                firewall_id=$(create_firewall)
                ;;
        esac
        
        if [ -n "$firewall_id" ]; then
            apply_firewall_to_server "$firewall_id" "$server_id"
        else
            error "Failed to create firewall"
            exit 1
        fi
    fi
    
    echo
    success "Firewall setup completed successfully!"
    echo
    show_firewall_status "$firewall_id"
    
    echo
    echo "Next steps:"
    echo "1. Test SSH access: ssh -p 2222 arcblock@$(api_call "GET" "/servers/$server_id" | jq -r '.server.public_net.ipv4.ip')"
    echo "2. Access Blocklet Server HTTP: http://$(api_call "GET" "/servers/$server_id" | jq -r '.server.public_net.ipv4.ip'):8080"
    echo "3. Access Blocklet Server HTTPS: https://$(api_call "GET" "/servers/$server_id" | jq -r '.server.public_net.ipv4.ip'):8443"
    echo "4. Monitor firewall: $0 status"
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n${YELLOW}Script interrupted by user${NC}"; exit 130' INT

# Run main function with all arguments
main "$@"