#!/bin/bash

# ArcDeploy Native Installation Setup Script
# Complete native installation and configuration for Blocklet Server

set -euo pipefail

# Configuration
readonly SCRIPT_VERSION="4.0.0"
readonly LOG_FILE="/var/log/arcblock-setup.log"
readonly USER="arcblock"
readonly SSH_PORT="2222"
readonly BLOCKLET_DIR="/opt/blocklet-server"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    error "$1"
    exit 1
}

# Trap errors
trap 'error_exit "Script failed at line $LINENO"' ERR

log "Starting ArcDeploy Native Installation v$SCRIPT_VERSION"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error_exit "This script must be run as root"
fi

# Create arcblock user if it doesn't exist
if ! id "$USER" &>/dev/null; then
    log "Creating $USER user"
    useradd -m -G users,admin,sudo -s /bin/bash "$USER"
    echo "$USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USER"
fi

# Create user directories
log "Setting up directories"
mkdir -p "$BLOCKLET_DIR"/{bin,data,config,logs}
chown -R "$USER:$USER" "$BLOCKLET_DIR"
chmod 755 "$BLOCKLET_DIR"

# Update system packages
log "Updating system packages"
apt-get update || error_exit "Failed to update package list"
apt-get upgrade -y || error_exit "Failed to upgrade packages"

# Install Node.js LTS
log "Installing Node.js LTS"
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs || error_exit "Failed to install Node.js"

# Install additional packages
log "Installing additional packages"
apt-get install -y \
    git \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    jq \
    htop \
    nano \
    vim \
    unzip \
    fail2ban \
    ufw \
    python3 \
    python3-pip \
    nginx \
    sqlite3 \
    redis-server \
    curl \
    wget || error_exit "Failed to install packages"

# Install Blocklet CLI
log "Installing Blocklet CLI"
npm install -g @blocklet/cli || error_exit "Failed to install @blocklet/cli"

# Verify installations
log "Verifying installations"
node --version || error_exit "Node.js verification failed"
npm --version || error_exit "npm verification failed"
blocklet --version || error_exit "Blocklet CLI verification failed"

# Configure Redis
log "Configuring Redis"
systemctl enable redis-server
systemctl start redis-server || error_exit "Failed to start Redis"

# Configure Nginx
log "Configuring Nginx"
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

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/blocklet-server /etc/nginx/sites-enabled/
nginx -t || error_exit "Nginx configuration test failed"
systemctl enable nginx
systemctl start nginx || error_exit "Failed to start Nginx"

# Initialize Blocklet Server
log "Initializing Blocklet Server"
sudo -u "$USER" blocklet server init "$BLOCKLET_DIR" || warning "Server init failed, using manual setup"
sudo -u "$USER" mkdir -p "$BLOCKLET_DIR"/{bin,data,config,logs}
sudo -u "$USER" blocklet server config set dataDir "$BLOCKLET_DIR/data" || true
sudo -u "$USER" blocklet server config set port 8080 || true

# Create systemd service
log "Creating systemd service"
cat > /etc/systemd/system/blocklet-server.service << 'EOF'
[Unit]
Description=Arcblock Blocklet Server
After=network-online.target redis.service
Wants=network-online.target
Requires=redis.service

[Service]
Type=simple
User=arcblock
Group=arcblock
WorkingDirectory=/opt/blocklet-server
Environment=NODE_ENV=production
Environment=BLOCKLET_LOG_LEVEL=info
Environment=BLOCKLET_HOST=0.0.0.0
Environment=BLOCKLET_PORT=8080
Environment=BLOCKLET_DATA_DIR=/opt/blocklet-server/data
Environment=BLOCKLET_CONFIG_DIR=/opt/blocklet-server/config
ExecStart=/usr/local/bin/blocklet server start --config-dir /opt/blocklet-server/config
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=blocklet-server
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Configure SSH hardening
log "Configuring SSH security"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

cat > /etc/ssh/sshd_config << 'EOF'
# Enhanced SSH Configuration for Security
Port 2222
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
AllowUsers arcblock
EOF

# Configure fail2ban
log "Configuring fail2ban"
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
backend = systemd

[sshd]
enabled = true
port = 2222
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
logpath = /opt/blocklet-server/logs/*.log
maxretry = 5
bantime = 3600
EOF

cat > /etc/fail2ban/filter.d/blocklet-server.conf << 'EOF'
[Definition]
failregex = ^.*\[.*\] .*Failed login attempt from <HOST>.*$
            ^.*\[.*\] .*Unauthorized access from <HOST>.*$
            ^.*\[.*\] .*Invalid authentication from <HOST>.*$
            ^.*\[.*\] .*Blocked request from <HOST>.*$
ignoreregex = ^.*\[.*\] .*Valid login from <HOST>.*$
EOF

# Configure firewall
log "Configuring UFW firewall"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow "$SSH_PORT"/tcp comment 'SSH'
ufw allow 8080/tcp comment 'Blocklet Server HTTP'
ufw allow 8443/tcp comment 'Blocklet Server HTTPS'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw --force enable

# Configure system limits
log "Configuring system limits"
cat >> /etc/security/limits.conf << 'EOF'
# Limits for Blocklet Server performance
arcblock soft nofile 65536
arcblock hard nofile 65536
arcblock soft nproc 32768
arcblock hard nproc 32768
* soft core 0
* hard core 0
EOF

# Configure sysctl
log "Configuring system parameters"
cat >> /etc/sysctl.conf << 'EOF'
# Network performance tuning for Blocklet Server
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 65536 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.core.netdev_max_backlog = 5000

# Security hardening
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

# Create health check script
log "Creating health check script"
cat > "$BLOCKLET_DIR/healthcheck.sh" << 'EOF'
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
        if curl -sf --max-time 5 http://localhost:8080 >/dev/null 2>&1; then
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

chmod +x "$BLOCKLET_DIR/healthcheck.sh"
chown "$USER:$USER" "$BLOCKLET_DIR/healthcheck.sh"

# Setup cron jobs
log "Setting up monitoring cron jobs"
echo "*/5 * * * * $BLOCKLET_DIR/healthcheck.sh >/dev/null 2>&1" | sudo -u "$USER" crontab -

# Enable and start services
log "Enabling and starting services"
systemctl enable fail2ban
systemctl start fail2ban
systemctl daemon-reload
systemctl enable blocklet-server

# Start Blocklet Server
log "Starting Blocklet Server"
systemctl start blocklet-server

# Wait for service to be ready
log "Waiting for Blocklet Server to become ready..."
attempts=0
max_attempts=24

while [ $attempts -lt $max_attempts ]; do
    if curl -sf --max-time 10 http://localhost:8080 >/dev/null 2>&1; then
        success "Blocklet Server is ready and responding!"
        break
    fi
    
    attempts=$((attempts + 1))
    log "Attempt $attempts/$max_attempts - waiting 15 seconds..."
    sleep 15
    
    if ! systemctl is-active --quiet blocklet-server; then
        log "Service stopped unexpectedly, restarting..."
        systemctl restart blocklet-server
    fi
done

if [ $attempts -eq $max_attempts ]; then
    warning "Blocklet Server did not become ready within expected time"
    log "Check logs: journalctl -u blocklet-server --no-pager"
fi

# Final cleanup
log "Performing final cleanup"
apt-get autoremove -y
apt-get autoclean

# Final verification
log "Performing final verification"
systemctl is-active --quiet blocklet-server || error_exit "Blocklet Server service is not active"
systemctl is-active --quiet nginx || error_exit "Nginx service is not active"
systemctl is-active --quiet redis-server || error_exit "Redis service is not active"

# Create completion marker
touch "$BLOCKLET_DIR/.native-install-complete"
chown "$USER:$USER" "$BLOCKLET_DIR/.native-install-complete"

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

success "ArcDeploy Native Installation completed successfully!"
log "Server IP: $SERVER_IP"
log "SSH Access: ssh -p $SSH_PORT $USER@$SERVER_IP"
log "Web Interface: http://$SERVER_IP:8080"
log "Setup completed at: $(date)"

echo ""
echo "=========================================="
echo "ArcDeploy Native Installation Complete!"
echo "=========================================="
echo ""
echo "Access Information:"
echo "- SSH: ssh -p $SSH_PORT $USER@$SERVER_IP"
echo "- Web Interface (Direct): http://$SERVER_IP:8080"
echo "- Web Interface (Nginx): http://$SERVER_IP"
echo "- HTTPS Interface: https://$SERVER_IP:8443"
echo ""
echo "Services Status:"
echo "- Blocklet Server: $(systemctl is-active blocklet-server)"
echo "- Nginx: $(systemctl is-active nginx)"
echo "- Redis: $(systemctl is-active redis-server)"
echo "- Fail2ban: $(systemctl is-active fail2ban)"
echo "- UFW Firewall: $(ufw status | head -1)"
echo ""
echo "Next Steps:"
echo "1. Access the web interface to complete initial setup"
echo "2. Configure your domain name (optional)"
echo "3. Set up SSL certificates (optional)"
echo "4. Install your first blocklet!"
echo ""
echo "For support, check the logs:"
echo "- Setup log: $LOG_FILE"
echo "- Service logs: journalctl -u blocklet-server -f"
echo "- Health logs: $BLOCKLET_DIR/logs/health.log"
echo "- Nginx logs: tail -f /var/log/nginx/access.log"
echo ""
echo "🔗 For support: https://github.com/Pocklabs/ArcDeploy"
echo "=========================================="