#!/bin/bash

# ArcDeploy Configuration Generator
# This script generates cloud-init configurations for different cloud providers

set -euo pipefail

# Script metadata
readonly SCRIPT_VERSION="1.0.0"

# Only set if not already set to avoid readonly errors
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    readonly SCRIPT_DIR
fi

if [[ -z "${PROJECT_ROOT:-}" ]]; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    readonly PROJECT_ROOT
fi
readonly TEMPLATES_DIR="$PROJECT_ROOT/templates"
readonly CONFIG_DIR="$PROJECT_ROOT/config"
readonly OUTPUT_DIR="$PROJECT_ROOT/generated"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Logging functions
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

# Error handling
error_exit() {
    error "$1"
    exit 1
}

# Display usage information
usage() {
    cat << EOF
ArcDeploy Configuration Generator v$SCRIPT_VERSION

Usage: $0 [OPTIONS]

Options:
    -p, --provider PROVIDER    Target cloud provider (hetzner, aws, gcp, azure, digitalocean)
    -k, --ssh-key KEY         SSH public key content or path to key file
    -r, --region REGION       Cloud provider region (optional)
    -s, --server-type TYPE    Server/instance type (optional)
    -d, --domain DOMAIN       Domain name for SSL configuration (optional)
    -e, --email EMAIL         Email for Let's Encrypt SSL (optional)
    -o, --output FILE         Output file path (optional)
    -c, --config FILE         Custom configuration file (optional)
    -t, --template FILE       Custom template file (optional)
    -v, --validate            Validate generated configuration
    -h, --help                Show this help message

Examples:
    # Generate for Hetzner Cloud with SSH key file
    $0 -p hetzner -k ~/.ssh/id_ed25519.pub

    # Generate for AWS with inline SSH key
    $0 -p aws -k "ssh-ed25519 AAAAC3Nz..." -r us-east-1

    # Generate with custom domain and SSL
    $0 -p digitalocean -k ~/.ssh/id_ed25519.pub -d example.com -e admin@example.com

    # Generate with custom configuration
    $0 -p gcp -k ~/.ssh/id_ed25519.pub -c config/custom.conf

Supported Providers:
    hetzner      - Hetzner Cloud (default)
    aws          - Amazon Web Services
    gcp          - Google Cloud Platform
    azure        - Microsoft Azure
    digitalocean - DigitalOcean
    linode       - Linode
    vultr        - Vultr

EOF
}

# Load default configuration
load_default_config() {
    local config_file="$CONFIG_DIR/arcdeploy.conf"
    
    if [ -f "$config_file" ]; then
        # shellcheck source=../config/arcdeploy.conf
        source "$config_file"
        log "Loaded default configuration from: $config_file"
    else
        warning "Default configuration file not found: $config_file"
    fi
}

# Load cloud provider specific configuration
load_provider_config() {
    local provider="$1"
    local provider_config="$CONFIG_DIR/providers/${provider}.conf"
    
    if [ -f "$provider_config" ]; then
        # shellcheck source=/dev/null
        source "$provider_config"
        log "Loaded provider configuration: $provider_config"
    else
        log "No provider-specific configuration found for: $provider"
    fi
}

# Validate SSH key
validate_ssh_key() {
    local ssh_key="$1"
    
    # If it's a file path, read the content
    if [ -f "$ssh_key" ]; then
        ssh_key=$(cat "$ssh_key")
    fi
    
    # Basic SSH key validation
    if [[ ! "$ssh_key" =~ ^ssh-(rsa|dss|ed25519|ecdsa) ]]; then
        error_exit "Invalid SSH key format. Must start with ssh-rsa, ssh-dss, ssh-ed25519, or ssh-ecdsa"
    fi
    
    echo "$ssh_key"
}

# Set provider-specific defaults
set_provider_defaults() {
    local provider="$1"
    
    case "$provider" in
        hetzner)
            CLOUD_PROVIDER_NAME="Hetzner Cloud"
            DEFAULT_REGION="${HETZNER_DEFAULT_LOCATION:-nbg1}"
            DEFAULT_SERVER_TYPE="${HETZNER_MIN_SERVER_TYPE:-cx31}"
            METADATA_SERVICE_URL="http://169.254.169.254/hetzner/v1/metadata"
            export METADATA_SERVICE_URL
            ;;
        aws)
            CLOUD_PROVIDER_NAME="Amazon Web Services"
            DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
            DEFAULT_SERVER_TYPE="${AWS_MIN_INSTANCE_TYPE:-t3.large}"
            METADATA_SERVICE_URL="http://169.254.169.254/latest/meta-data"
            export METADATA_SERVICE_URL
            # AWS specific packages
            ADDITIONAL_PACKAGES="
  - awscli
  - amazon-ssm-agent"
            ;;
        gcp)
            CLOUD_PROVIDER_NAME="Google Cloud Platform"
            DEFAULT_REGION="${GCP_DEFAULT_REGION:-us-central1}"
            DEFAULT_SERVER_TYPE="${GCP_MIN_INSTANCE_TYPE:-e2-standard-2}"
            METADATA_SERVICE_URL="http://metadata.google.internal/computeMetadata/v1"
            export METADATA_SERVICE_URL
            # GCP specific packages
            ADDITIONAL_PACKAGES="
  - google-cloud-sdk"
            ;;
        azure)
            CLOUD_PROVIDER_NAME="Microsoft Azure"
            DEFAULT_REGION="${AZURE_DEFAULT_REGION:-East US}"
            DEFAULT_SERVER_TYPE="${AZURE_MIN_INSTANCE_TYPE:-Standard_B2s}"
            METADATA_SERVICE_URL="http://169.254.169.254/metadata/instance"
            export METADATA_SERVICE_URL
            # Azure specific packages
            ADDITIONAL_PACKAGES="
  - azure-cli"
            ;;
        digitalocean)
            CLOUD_PROVIDER_NAME="DigitalOcean"
            DEFAULT_REGION="${DO_DEFAULT_REGION:-nyc1}"
            DEFAULT_SERVER_TYPE="${DO_MIN_DROPLET_SIZE:-s-2vcpu-4gb}"
            METADATA_SERVICE_URL="http://169.254.169.254/metadata/v1"
            export METADATA_SERVICE_URL
            ;;
        linode)
            CLOUD_PROVIDER_NAME="Linode"
            DEFAULT_REGION="${LINODE_DEFAULT_REGION:-us-east}"
            DEFAULT_SERVER_TYPE="${LINODE_MIN_INSTANCE_TYPE:-g6-standard-2}"
            METADATA_SERVICE_URL="http://169.254.169.254/linode/v1"
            export METADATA_SERVICE_URL
            ;;
        vultr)
            CLOUD_PROVIDER_NAME="Vultr"
            DEFAULT_REGION="${VULTR_DEFAULT_REGION:-ewr}"
            DEFAULT_SERVER_TYPE="${VULTR_MIN_INSTANCE_TYPE:-vc2-2c-4gb}"
            METADATA_SERVICE_URL="http://169.254.169.254/v1"
            export METADATA_SERVICE_URL
            ;;
        *)
            error_exit "Unsupported cloud provider: $provider"
            ;;
    esac
}

# Generate SSL configuration
generate_ssl_config() {
    local domain="$1"
    local email="$2"
    
    if [ -n "$domain" ]; then
        cat << EOF
      # HTTPS server block
      server {
          listen ${NGINX_HTTPS_PORT:-443} ssl http2;
          server_name $domain;

          # SSL configuration
          ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
          ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
          ssl_session_timeout 1d;
          ssl_session_cache shared:SSL:50m;
          ssl_session_tickets off;
          ssl_protocols TLSv1.2 TLSv1.3;
          ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
          ssl_prefer_server_ciphers off;

          # Security headers
          add_header Strict-Transport-Security "max-age=63072000" always;
          add_header X-Frame-Options DENY;
          add_header X-Content-Type-Options nosniff;
          add_header X-XSS-Protection "1; mode=block";

          location / {
              proxy_pass http://127.0.0.1:${BLOCKLET_HTTP_PORT:-8080};
              proxy_http_version 1.1;
              proxy_set_header Upgrade \$http_upgrade;
              proxy_set_header Connection 'upgrade';
              proxy_set_header Host \$host;
              proxy_set_header X-Real-IP \$remote_addr;
              proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto \$scheme;
              proxy_cache_bypass \$http_upgrade;
          }
      }
EOF
    fi
}

# Generate provider-specific configurations
generate_provider_configs() {
    local provider="$1"
    local region="$2"
    
    case "$provider" in
        aws)
            cat << EOF
  # AWS CloudWatch agent configuration
  - path: /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    content: |
      {
        "metrics": {
          "namespace": "ArcDeploy/BlockletServer",
          "metrics_collected": {
            "cpu": {
              "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
              "metrics_collection_interval": 60
            },
            "disk": {
              "measurement": ["used_percent"],
              "metrics_collection_interval": 60,
              "resources": ["*"]
            },
            "mem": {
              "measurement": ["mem_used_percent"],
              "metrics_collection_interval": 60
            }
          }
        },
        "logs": {
          "logs_collected": {
            "files": {
              "collect_list": [
                {
                  "file_path": "/opt/blocklet-server/logs/*.log",
                  "log_group_name": "/arcdeploy/blocklet-server",
                  "log_stream_name": "{instance_id}/application.log"
                }
              ]
            }
          }
        }
      }
    owner: root:root
    permissions: '0644'
EOF
            ;;
        gcp)
            cat << EOF
  # Google Cloud Ops Agent configuration
  - path: /etc/google-cloud-ops-agent/config.yaml
    content: |
      metrics:
        receivers:
          hostmetrics:
            type: hostmetrics
            collection_interval: 60s
        service:
          pipelines:
            default_pipeline:
              receivers: [hostmetrics]
      logging:
        receivers:
          blocklet_server_logs:
            type: files
            include_paths:
              - /opt/blocklet-server/logs/*.log
        service:
          pipelines:
            default_pipeline:
              receivers: [blocklet_server_logs]
    owner: root:root
    permissions: '0644'
EOF
            ;;
        azure)
            cat << EOF
  # Azure Monitor agent configuration
  - path: /etc/opt/microsoft/azuremonitoragent/config/settings.json
    content: |
      {
        "workspaceId": "\${AZURE_WORKSPACE_ID}",
        "workspaceKey": "\${AZURE_WORKSPACE_KEY}",
        "enableSyslog": true,
        "enableCustomLogs": true,
        "customLogPaths": [
          "/opt/blocklet-server/logs/*.log"
        ]
      }
    owner: root:root
    permissions: '0644'
EOF
            ;;
        *)
            echo ""
            ;;
    esac
}

# Generate provider-specific commands
generate_provider_commands() {
    local provider="$1"
    local domain="$2"
    local email="$3"
    
    case "$provider" in
        aws)
            cat << EOF
  # Install and configure AWS CloudWatch agent
  - wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
  - dpkg -i amazon-cloudwatch-agent.deb
  - systemctl enable amazon-cloudwatch-agent
  - systemctl start amazon-cloudwatch-agent
EOF
            ;;
        gcp)
            cat << EOF
  # Install Google Cloud Ops Agent
  - curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
  - bash add-google-cloud-ops-agent-repo.sh --also-install
  - systemctl enable google-cloud-ops-agent
  - systemctl start google-cloud-ops-agent
EOF
            ;;
        azure)
            cat << EOF
  # Install Azure Monitor agent
  - wget https://aka.ms/azcmagent -O /tmp/install_linux_azcmagent.sh
  - bash /tmp/install_linux_azcmagent.sh
EOF
            ;;
        *)
            echo ""
            ;;
    esac
    
    # Add SSL setup commands if domain is provided
    if [ -n "$domain" ] && [ -n "$email" ]; then
        cat << EOF
  # Install and configure Let's Encrypt SSL
  - apt-get install -y certbot python3-certbot-nginx
  - systemctl stop nginx
  - certbot certonly --standalone -d $domain --email $email --agree-tos --non-interactive
  - systemctl start nginx
  - echo "0 3 * * * certbot renew --quiet" | crontab -
EOF
    fi
}

# Substitute variables in template
substitute_variables() {
    local template_file="$1"
    local output_file="$2"
    
    log "Substituting variables in template..."
    
    # Use envsubst to replace environment variables
    envsubst < "$template_file" > "$output_file"
    
    success "Template processing completed: $output_file"
}

# Validate generated configuration
validate_config() {
    local config_file="$1"
    
    log "Validating generated configuration..."
    
    # Check if file exists and is not empty
    if [ ! -s "$config_file" ]; then
        error_exit "Generated configuration file is empty or does not exist"
    fi
    
    # Basic YAML syntax validation using python
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
import yaml
import sys
try:
    with open('$config_file', 'r') as f:
        yaml.safe_load(f)
    print('YAML syntax validation: PASSED')
except yaml.YAMLError as e:
    print(f'YAML syntax validation: FAILED - {e}')
    sys.exit(1)
except Exception as e:
    print(f'Validation error: {e}')
    sys.exit(1)
" || error_exit "YAML validation failed"
    fi
    
    # Check for required sections
    local required_sections=("users" "packages" "write_files" "runcmd")
    for section in "${required_sections[@]}"; do
        if ! grep -q "^$section:" "$config_file"; then
            error_exit "Required section missing: $section"
        fi
    done
    
    success "Configuration validation passed"
}

# Main function
main() {
    local provider=""
    local ssh_key=""
    local region=""
    local server_type=""
    local domain=""
    local email=""
    local output_file=""
    local config_file=""
    local template_file=""
    local validate_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--provider)
                provider="$2"
                shift 2
                ;;
            -k|--ssh-key)
                ssh_key="$2"
                shift 2
                ;;
            -r|--region)
                region="$2"
                shift 2
                ;;
            -s|--server-type)
                server_type="$2"
                shift 2
                ;;
            -d|--domain)
                domain="$2"
                shift 2
                ;;
            -e|--email)
                email="$2"
                shift 2
                ;;
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -c|--config)
                config_file="$2"
                shift 2
                ;;
            -t|--template)
                template_file="$2"
                shift 2
                ;;
            -v|--validate)
                validate_only=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Check required parameters
    if [ -z "$provider" ]; then
        error "Provider is required. Use -p or --provider"
        usage
        exit 1
    fi
    
    if [ -z "$ssh_key" ]; then
        error "SSH key is required. Use -k or --ssh-key"
        usage
        exit 1
    fi
    
    # Set default values
    local default_template="$TEMPLATES_DIR/cloud-init.yaml.template"
    local default_output="$OUTPUT_DIR/${provider}-cloud-init.yaml"
    template_file="${template_file:-$default_template}"
    output_file="${output_file:-$default_output}"
    
    # Create output directory
    local output_dir
    output_dir="$(dirname "$output_file")"
    mkdir -p "$output_dir"
    
    log "Starting ArcDeploy configuration generation..."
    log "Provider: $provider"
    log "Template: $template_file"
    log "Output: $output_file"
    
    # Load configurations
    load_default_config
    
    if [ -n "$config_file" ]; then
        if [ -f "$config_file" ]; then
            # shellcheck source=/dev/null
            source "$config_file"
            log "Loaded custom configuration: $config_file"
        else
            error_exit "Custom configuration file not found: $config_file"
        fi
    fi
    
    load_provider_config "$provider"
    
    # Validate and process SSH key
    SSH_PUBLIC_KEY=$(validate_ssh_key "$ssh_key")
    export SSH_PUBLIC_KEY
    
    # Set provider-specific defaults
    set_provider_defaults "$provider"
    
    # Set region and server type
    export CLOUD_PROVIDER="$provider"
    export CLOUD_PROVIDER_NAME
    export REGION="${region:-$DEFAULT_REGION}"
    export SERVER_TYPE="${server_type:-$DEFAULT_SERVER_TYPE}"
    export DOMAIN="$domain"
    export SSL_EMAIL="$email"
    
    # Generate optional configurations
    if [ -n "$domain" ]; then
        export SERVER_NAME="$domain"
        NGINX_HTTPS_CONFIG=$(generate_ssl_config "$domain" "$email")
        export NGINX_HTTPS_CONFIG
        export ENABLE_SSL="true"
    else
        export SERVER_NAME="_"
        export NGINX_HTTPS_CONFIG=""
        export ENABLE_SSL="false"
    fi
    
    # Set additional configurations
    export ADDITIONAL_PACKAGES="${ADDITIONAL_PACKAGES:-}"
    CLOUD_PROVIDER_CONFIGS=$(generate_provider_configs "$provider" "$region")
    export CLOUD_PROVIDER_CONFIGS
    CLOUD_PROVIDER_COMMANDS=$(generate_provider_commands "$provider" "$domain" "$email")
    export CLOUD_PROVIDER_COMMANDS
    export ADDITIONAL_UFW_RULES=""
    export ADDITIONAL_SSH_KEYS=""
    
    # Add timestamp and metadata
    GENERATED_TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
    export GENERATED_TIMESTAMP
    export GENERATOR_VERSION="$SCRIPT_VERSION"
    
    # Process template
    if [ ! -f "$template_file" ]; then
        error_exit "Template file not found: $template_file"
    fi
    
    substitute_variables "$template_file" "$output_file"
    
    # Add metadata header
    {
        echo "# Generated by ArcDeploy Configuration Generator v$SCRIPT_VERSION"
        echo "# Timestamp: $GENERATED_TIMESTAMP"
        echo "# Provider: $CLOUD_PROVIDER_NAME ($provider)"
        echo "# Region: $REGION"
        echo "# Server Type: $SERVER_TYPE"
        [ -n "$domain" ] && echo "# Domain: $domain"
        echo ""
        cat "$output_file"
    } > "${output_file}.tmp" && mv "${output_file}.tmp" "$output_file"
    
    # Validate if requested
    if [ "$validate_only" = true ]; then
        validate_config "$output_file"
    fi
    
    success "Configuration generated successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Review the generated configuration: $output_file"
    echo "2. Deploy to $CLOUD_PROVIDER_NAME using the cloud-init configuration"
    echo "3. Access your server via SSH: ssh -p ${SSH_PORT:-2222} ${USER_NAME:-arcblock}@YOUR_SERVER_IP"
    echo "4. Access web interface: http://YOUR_SERVER_IP:${BLOCKLET_HTTP_PORT:-8080}"
    
    if [ -n "$domain" ]; then
        echo "5. Access via domain: https://$domain"
    fi
}

# Run main function
main "$@"