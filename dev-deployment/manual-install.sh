#!/bin/bash

# ArcDeploy Manual Installation Script
# This script automates the manual installation process from root to arcblock user
# Version: 1.0
# Date: June 8, 2025

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
ARCBLOCK_USER="arcblock"
SSH_PORT="2222"
BLOCKLET_DIR="/opt/blocklet-server"
SSH_PUBLIC_KEY=""

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

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        exit 1
    fi
}

# Function to prompt for SSH public key
get_ssh_key() {
    echo
    warning "SSH Public Key Required"
    echo "Please paste your SSH public key (starts with ssh-ed25519, ssh-rsa, etc.):"
    echo "Example: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... user@example.com"
    echo
    read -p "SSH Public Key: " SSH_PUBLIC_KEY
    
    if [[ -z "$SSH_PUBLIC_KEY" ]] || [[ ! "$SSH_PUBLIC_KEY" =~ ^ssh- ]]; then
        error "Invalid SSH public key format"
        exit 1
    fi
    
    success "SSH public key accepted"
}

# Function to confirm installation
confirm_installation() {
    echo
    warning "This script will perform the following actions:"
    echo "1. Update system packages"
    echo "2. Create arcblock user with sudo privileges"
    echo "3. Configure SSH hardening (port $SSH_PORT)"
    echo "4. Install Node.js, Nginx, Redis, and security tools"
    echo "5. Set up Blocklet Server with systemd service"
    echo "6. Configure comprehensive security hardening"
    echo
    warning "IMPORTANT: This will modify SSH configuration and firewall rules!"
    echo
    read -p "Do you want to continue? (yes/no): " confirm
    
    if [[ $confirm != "yes" ]]; then
        warning "Installation cancelled by user"
        exit 0
    fi
}

# Function to update system packages
update_system() {
    log "Updating system packages..."
    
    apt update
    apt upgrade -y
    
    apt install -y curl wget git build-essential software-properties-common \
        apt-transport-https ca-certificates gnupg lsb-release jq htop nano vim \
        unzip fail2ban ufw python3 python3-pip nginx sqlite3 redis-server \
        net-tools systemd
    
    success "System packages updated"
}

# Function to configure initial firewall
setup_initial_firewall() {
    log "Configuring initial firewall..."
    
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp comment 'SSH - temporary'
    ufw --force enable
    
    success "Initial firewall configured"
}

# Function to create arcblock user
create_arcblock_user() {
    log "Creating arcblock user..."
    
    # Create user with home directory
    useradd -m -s /bin/bash $ARCBLOCK_USER
    usermod -aG sudo $ARCBLOCK_USER
    
    # Create directory structure
    mkdir -p /home/$ARCBLOCK_USER/.ssh
    mkdir -p $BLOCKLET_DIR/{bin,data,config,logs}
    
    # Set up SSH key
    echo "$SSH_PUBLIC_KEY" > /home/$ARCBLOCK_USER/.ssh/authorized_keys
    chmod 700 /home/$ARCBLOCK_USER/.ssh
    chmod 600 /home/$ARCBLOCK_USER/.ssh/authorized_keys
    chown -R $ARCBLOCK_USER:$ARCBLOCK_USER /home/$ARCBLOCK_USER
    chown -R $ARCBLOCK_USER:$ARCBLOCK_USER $BLOCKLET_DIR
    
    success "arcblock user created and configured"
}

# Function to configure SSH hardening
configure_ssh() {
    log "Configuring SSH hardening..."
    
    # Backup original configuration
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Create new SSH configuration
    cat > /etc/ssh/sshd_config << EOF
# ArcDeploy SSH Configuration
Port $SSH_PORT
Protocol 2
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
MaxAuthTries 3
MaxSessions 10
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTunnel no
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 60
StrictModes yes
IgnoreRhosts yes
HostbasedAuthentication no
PermitEmptyPasswords no
AllowUsers $ARCBLOCK_USER
EOF

    # Update firewall for new SSH port
    ufw allow $SSH_PORT/tcp comment 'SSH - secure port'
    
    # Test SSH configuration
    sshd -t
    
    success "SSH hardening configured"
}

# Function to install Node.js
install_nodejs() {
    log "Installing Node.js LTS..."
    
    curl -fsSL https://deb.nodesource.com/setup_lts.x -o /tmp/nodesource_setup.sh
    bash /tmp/nodesource_setup.sh
    apt-get install -y nodejs
    rm /tmp/nodesource_setup.sh
    
    success "Node.js installed: $(node --version)"
}

# Function to install Blocklet CLI
install_blocklet_cli() {
    log "Installing Blocklet CLI..."
    
    npm install -g @blocklet/cli
    
    success "Blocklet CLI installed: $(blocklet --version)"
}

# Function to configure Redis
configure_redis() {
    log "Configuring Redis..."
    
    systemctl enable redis-server
    systemctl start redis-server
    
    success "Redis configured and started"
}

# Function to configure Nginx
configure_nginx() {
    log "Configuring Nginx..."
    
    # Create Blocklet Server site configuration
    cat > /etc/nginx/sites-available/blocklet-server << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }
}
EOF

    # Enable the site
    rm -f /etc/nginx/sites-enabled/default
    ln -sf /etc/nginx/sites-available/blocklet-server /etc/nginx/sites-enabled/
    
    # Test and start Nginx
    nginx -t
    systemctl enable nginx
    systemctl start nginx
    
    success "Nginx configured and started"
}

# Function to configure firewall for web services
configure_web_firewall() {
    log "Configuring firewall for web services..."
    
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    ufw allow 8080/tcp comment 'Blocklet Server HTTP'
    ufw allow 8443/tcp comment 'Blocklet Server HTTPS'
    
    success "Web firewall rules added"
}

# Function to configure Fail2ban
configure_fail2ban() {
    log "Configuring Fail2ban..."
    
    # Create jail configuration
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
backend = systemd

[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
banaction = iptables-multiport

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 6

[blocklet-server]
enabled = true
port = 8080
filter = blocklet-server
logpath = $BLOCKLET_DIR/logs/*.log
maxretry = 5
bantime = 3600
EOF

    # Create Blocklet Server filter
    cat > /etc/fail2ban/filter.d/blocklet-server.conf << 'EOF'
[Definition]
failregex = ^.*\[.*\] .*Failed login attempt from <HOST>.*$
            ^.*\[.*\] .*Unauthorized access from <HOST>.*$
            ^.*\[.*\] .*Invalid authentication from <HOST>.*$
            ^.*\[.*\] .*Blocked request from <HOST>.*$
ignoreregex = ^.*\[.*\] .*Valid login from <HOST>.*$
EOF

    systemctl enable fail2ban
    systemctl start fail2ban
    
    success "Fail2ban configured and started"
}

# Function to configure system hardening
configure_system_hardening() {
    log "Configuring system hardening..."
    
    # Configure system limits
    cat >> /etc/security/limits.conf << EOF
$ARCBLOCK_USER soft nofile 65536
$ARCBLOCK_USER hard nofile 65536
$ARCBLOCK_USER soft nproc 32768
$ARCBLOCK_USER hard nproc 32768
* soft core 0
* hard core 0
EOF

    # Configure kernel parameters
    cat >> /etc/sysctl.conf << 'EOF'
# Network security and performance
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 65536 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.core.netdev_max_backlog = 5000
net.ipv4.ip_forward = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
EOF

    sysctl -p
    
    success "System hardening configured"
}

# Function to initialize Blocklet Server
initialize_blocklet_server() {
    log "Initializing Blocklet Server..."
    
    # Initialize as arcblock user
    sudo -u $ARCBLOCK_USER bash << EOF
cd $BLOCKLET_DIR
blocklet server init $BLOCKLET_DIR || echo "Manual initialization required"
mkdir -p $BLOCKLET_DIR/{bin,data,config,logs}
blocklet server config set dataDir $BLOCKLET_DIR/data || true
blocklet server config set port 8080 || true
blocklet server config set host 0.0.0.0 || true
EOF

    success "Blocklet Server initialized"
}

# Function to create systemd service
create_systemd_service() {
    log "Creating systemd service..."
    
    cat > /etc/systemd/system/blocklet-server.service << EOF
[Unit]
Description=Arcblock Blocklet Server
After=network-online.target redis.service
Wants=network-online.target
Requires=redis.service

[Service]
Type=simple
User=$ARCBLOCK_USER
Group=$ARCBLOCK_USER
WorkingDirectory=$BLOCKLET_DIR
Environment=NODE_ENV=production
Environment=BLOCKLET_LOG_LEVEL=info
Environment=BLOCKLET_HOST=0.0.0.0
Environment=BLOCKLET_PORT=8080
Environment=BLOCKLET_DATA_DIR=$BLOCKLET_DIR/data
Environment=BLOCKLET_CONFIG_DIR=$BLOCKLET_DIR/config
ExecStart=/usr/local/bin/blocklet server start --config-dir $BLOCKLET_DIR/config
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=blocklet-server
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable blocklet-server
    
    success "Systemd service created and enabled"
}

# Function to create health check script
create_health_check() {
    log "Creating health check script..."
    
    cat > $BLOCKLET_DIR/healthcheck.sh << 'EOF'
#!/bin/bash
set -euo pipefail

readonly LOGFILE="/opt/blocklet-server/logs/health.log"
readonly TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
readonly MAX_ATTEMPTS=12
readonly SLEEP_INTERVAL=10

log() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOGFILE"
}

mkdir -p "$(dirname "$LOGFILE")"

wait_for_service() {
    local attempts=0
    log "INFO: Waiting for Blocklet Server to become ready..."

    while [ $attempts -lt $MAX_ATTEMPTS ]; do
        if curl -sf --max-time 10 http://localhost:8080 >/dev/null 2>&1; then
            log "INFO: Blocklet Server is ready and responding"
            return 0
        fi

        attempts=$((attempts + 1))
        log "INFO: Attempt $attempts/$MAX_ATTEMPTS - waiting ${SLEEP_INTERVAL}s..."
        sleep $SLEEP_INTERVAL
    done

    log "ERROR: Blocklet Server did not become ready within $((MAX_ATTEMPTS * SLEEP_INTERVAL)) seconds"
    return 1
}

# Check systemd service
if systemctl is-active --quiet blocklet-server; then
    log "INFO: Blocklet Server systemd service is active"
else
    log "ERROR: Blocklet Server systemd service is not active"
    systemctl restart blocklet-server 2>/dev/null || log "ERROR: Failed to restart service"
    exit 1
fi

# Check HTTP endpoint
if wait_for_service; then
    log "INFO: Blocklet Server health check passed"
else
    log "ERROR: Blocklet Server health check failed"
    exit 1
fi

# Check disk space
readonly DISK_USAGE=$(df /opt/blocklet-server | awk 'NR==2 {print $(NF-1)}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 85 ]; then
    log "WARN: High disk usage: ${DISK_USAGE}%"
else
    log "INFO: Disk usage: ${DISK_USAGE}%"
fi

# Check memory usage
readonly MEM_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [ "$MEM_USAGE" -gt 85 ]; then
    log "WARN: High memory usage: ${MEM_USAGE}%"
else
    log "INFO: Memory usage: ${MEM_USAGE}%"
fi

log "INFO: Health check completed successfully"
EOF

    chmod 755 $BLOCKLET_DIR/healthcheck.sh
    chown $ARCBLOCK_USER:$ARCBLOCK_USER $BLOCKLET_DIR/healthcheck.sh
    
    success "Health check script created"
}

# Function to start services
start_services() {
    log "Starting Blocklet Server service..."
    
    systemctl start blocklet-server
    sleep 10
    
    if systemctl is-active --quiet blocklet-server; then
        success "Blocklet Server service started successfully"
    else
        warning "Blocklet Server service may still be starting..."
    fi
}

# Function to configure health monitoring
configure_health_monitoring() {
    log "Configuring health monitoring..."
    
    # Add cron job for health monitoring
    sudo -u $ARCBLOCK_USER bash << 'EOF'
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/blocklet-server/healthcheck.sh >/dev/null 2>&1") | crontab -
EOF

    success "Health monitoring configured"
}

# Function to restart SSH
restart_ssh() {
    log "Restarting SSH service..."
    
    systemctl restart ssh
    
    warning "SSH service restarted. New SSH port is $SSH_PORT"
    warning "Test SSH access before closing this session!"
}

# Function to remove old SSH firewall rule
cleanup_firewall() {
    log "Cleaning up firewall rules..."
    
    ufw delete allow 22/tcp 2>/dev/null || true
    
    success "Firewall cleanup completed"
}

# Function to create completion marker
create_completion_marker() {
    log "Creating installation completion marker..."
    
    touch $BLOCKLET_DIR/.manual-install-complete
    echo "Manual installation completed on $(date)" > $BLOCKLET_DIR/.manual-install-complete
    chown $ARCBLOCK_USER:$ARCBLOCK_USER $BLOCKLET_DIR/.manual-install-complete
    
    success "Installation completion marker created"
}

# Function to perform final cleanup
final_cleanup() {
    log "Performing final cleanup..."
    
    apt autoremove -y
    apt autoclean
    
    success "System cleanup completed"
}

# Function to display final information
display_final_info() {
    echo
    success "ArcDeploy Manual Installation Completed Successfully!"
    echo
    warning "IMPORTANT: Test SSH access before closing this session!"
    echo
    echo "SSH Access:"
    echo "  ssh -p $SSH_PORT $ARCBLOCK_USER@$(hostname -I | awk '{print $1}')"
    echo
    echo "Web Interfaces:"
    echo "  Blocklet Server: http://$(hostname -I | awk '{print $1}'):8080"
    echo "  Nginx Proxy:     http://$(hostname -I | awk '{print $1}'):80"
    echo
    echo "Service Management:"
    echo "  Status: sudo systemctl status blocklet-server"
    echo "  Logs:   sudo journalctl -u blocklet-server -f"
    echo "  Health: $BLOCKLET_DIR/healthcheck.sh"
    echo
    echo "Security Features:"
    echo "  ✅ SSH hardened (port $SSH_PORT, key-only auth)"
    echo "  ✅ UFW firewall enabled"
    echo "  ✅ Fail2ban protection active"
    echo "  ✅ Non-root service execution"
    echo "  ✅ System hardening applied"
    echo "  ✅ Health monitoring configured"
    echo
    warning "Next Steps:"
    echo "1. Test SSH access: ssh -p $SSH_PORT $ARCBLOCK_USER@$(hostname -I | awk '{print $1}')"
    echo "2. Verify web interface: http://$(hostname -I | awk '{print $1}'):8080"
    echo "3. Run validation: curl -fsSL https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/scripts/validate-setup.sh | bash"
    echo "4. Configure SSL/TLS certificates (optional)"
    echo "5. Set up monitoring and backups"
    echo
}

# Main installation function
main() {
    echo "=============================================="
    echo "ArcDeploy Manual Installation Script"
    echo "Version: 1.0 | Date: June 8, 2025"
    echo "=============================================="
    echo
    
    check_root
    get_ssh_key
    confirm_installation
    
    log "Starting ArcDeploy manual installation..."
    
    # Phase 1: System preparation
    update_system
    setup_initial_firewall
    
    # Phase 2: User and SSH setup
    create_arcblock_user
    configure_ssh
    
    # Phase 3: Application stack
    install_nodejs
    install_blocklet_cli
    configure_redis
    configure_nginx
    configure_web_firewall
    
    # Phase 4: Security hardening
    configure_fail2ban
    configure_system_hardening
    
    # Phase 5: Blocklet Server setup
    initialize_blocklet_server
    create_systemd_service
    create_health_check
    start_services
    configure_health_monitoring
    
    # Phase 6: Finalization
    restart_ssh
    cleanup_firewall
    create_completion_marker
    final_cleanup
    
    display_final_info
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n${YELLOW}Installation interrupted by user${NC}"; exit 130' INT

# Run main function
main "$@"