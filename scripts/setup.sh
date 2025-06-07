#!/bin/bash

# Arcblock Blocklet Server Setup Script
# Complete installation and configuration for Hetzner Cloud

set -euo pipefail

# Configuration
readonly SCRIPT_VERSION="2.0.0"
readonly LOG_FILE="/var/log/arcblock-setup.log"
readonly USER="arcblock"
readonly SSH_PORT="2222"

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

log "Starting Arcblock Blocklet Server setup v$SCRIPT_VERSION"

# Create user directories
log "Setting up directories"
mkdir -p /home/$USER/{blocklet-server,backups,.config/containers,.local/share/containers}
chown -R $USER:$USER /home/$USER
chmod 755 /home/$USER/blocklet-server

# Install Node.js LTS
log "Installing Node.js LTS"
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs || error_exit "Failed to install Node.js"

# Install additional packages
log "Installing additional packages"
apt-get update
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
    podman \
    python3 \
    python3-pip || error_exit "Failed to install packages"

# Configure Podman for rootless operation
log "Configuring Podman for rootless containers"
echo "$USER:100000:65536" >> /etc/subuid
echo "$USER:100000:65536" >> /etc/subgid
loginctl enable-linger $USER || error_exit "Failed to enable user linger"

# Configure Podman registries
log "Configuring container registries"
cat > /home/$USER/.config/containers/registries.conf << 'EOF'
[registries.search]
registries = ['docker.io', 'registry.fedoraproject.org', 'quay.io', 'registry.access.redhat.com']

[registries.insecure]
registries = []

[registries.block]
registries = []
EOF

cat > /home/$USER/.config/containers/storage.conf << 'EOF'
[storage]
driver = "overlay"
runroot = "/run/user/1000/containers"
graphroot = "/home/arcblock/.local/share/containers/storage"

[storage.options]
additionalimagestores = []

[storage.options.overlay]
mountopt = "nodev,metacopy=on"
EOF

chown -R $USER:$USER /home/$USER/.config

# Initialize Podman for user
log "Initializing Podman for $USER user"
sudo -u $USER podman system migrate 2>/dev/null || true
sudo -u $USER systemctl --user enable podman.socket || error_exit "Failed to enable Podman socket"
sudo -u $USER systemctl --user start podman.socket || error_exit "Failed to start Podman socket"

# Install Blocklet CLI
log "Installing Blocklet CLI"
sudo -u $USER npm install -g @blocklet/cli || warning "Blocklet CLI installation failed"

# Pull Blocklet Server image
log "Pulling Blocklet Server container image"
sudo -u $USER podman pull arcblock/blocklet-server:latest || error_exit "Failed to pull Blocklet Server image"

# Create compose configuration
log "Creating compose configuration"
cat > /home/$USER/blocklet-server/compose.yaml << 'EOF'
version: '3.8'

services:
  blocklet-server:
    image: arcblock/blocklet-server:latest
    container_name: blocklet-server
    restart: unless-stopped
    ports:
      - "8089:8089"
      - "80:80"
      - "443:443"
    volumes:
      - blocklet-data:/opt/abtnode/data
      - blocklet-config:/opt/abtnode/config
      - blocklet-logs:/opt/abtnode/logs
    environment:
      - ABT_NODE_LOG_LEVEL=info
      - ABT_NODE_ENV=production
      - ABT_NODE_HOST=0.0.0.0
      - ABT_NODE_PORT=8089
      - ABT_NODE_DATA_DIR=/opt/abtnode/data
      - ABT_NODE_CONFIG_DIR=/opt/abtnode/config
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8089/api/did"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    labels:
      - "io.containers.autoupdate=registry"

volumes:
  blocklet-data:
    driver: local
  blocklet-config:
    driver: local
  blocklet-logs:
    driver: local
EOF

chown $USER:$USER /home/$USER/blocklet-server/compose.yaml

# Create systemd service
log "Creating systemd service"
cat > /etc/systemd/system/blocklet-server.service << 'EOF'
[Unit]
Description=Arcblock Blocklet Server
After=network-online.target
Wants=network-online.target
RequiresMountsFor=/home/arcblock

[Service]
Type=oneshot
RemainAfterExit=yes
User=arcblock
Group=arcblock
WorkingDirectory=/home/arcblock/blocklet-server
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=PODMAN_SYSTEMD_UNIT=%n
ExecStartPre=/usr/bin/podman compose down --remove-orphans
ExecStart=/usr/bin/podman compose up -d
ExecStop=/usr/bin/podman compose down --timeout 30
ExecReload=/usr/bin/podman compose restart
TimeoutStartSec=300
TimeoutStopSec=120

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

[blocklet-server]
enabled = true
port = 8089,80,443
filter = blocklet-server
logpath = /home/arcblock/blocklet-server/logs/*.log
maxretry = 5
bantime = 3600
EOF

cat > /etc/fail2ban/filter.d/blocklet-server.conf << 'EOF'
[Definition]
failregex = ^.*\[.*\] .*Failed login attempt from <HOST>.*$
            ^.*\[.*\] .*Unauthorized access from <HOST>.*$
            ^.*\[.*\] .*Invalid authentication from <HOST>.*$
            ^.*\[.*\] .*Blocked request from <HOST>.*$
            ^.*\s+<HOST>\s+.*"(GET|POST|PUT|DELETE).*" (401|403|429)
ignoreregex = ^.*\[.*\] .*Valid login from <HOST>.*$
              ^.*\s+<HOST>\s+.*"(GET|POST|PUT|DELETE).*" (200|201|202|204)
EOF

# Configure firewall
log "Configuring UFW firewall"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow $SSH_PORT/tcp comment 'SSH'
ufw allow 8089/tcp comment 'Blocklet Server'
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

# Container networking
net.ipv4.ip_forward = 1

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
cat > /home/$USER/blocklet-server/healthcheck.sh << 'EOF'
#!/bin/bash
set -euo pipefail

readonly LOGFILE="/home/arcblock/blocklet-server/logs/health.log"
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
        if curl -sf --max-time 5 http://localhost:8089/api/did >/dev/null 2>&1; then
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

# Check container
if podman ps --filter "name=blocklet-server" --format "{{.Status}}" | grep -q "Up"; then
    log "INFO: Blocklet Server container is running"
else
    log "ERROR: Blocklet Server container is not running"
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
readonly DISK_USAGE=$(df /home/arcblock | awk 'NR==2 {print $(NF-1)}' | sed 's/%//')
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

chmod +x /home/$USER/blocklet-server/healthcheck.sh
chown $USER:$USER /home/$USER/blocklet-server/healthcheck.sh

# Create backup script
log "Creating backup script"
cat > /home/$USER/blocklet-server/backup.sh << 'EOF'
#!/bin/bash
set -euo pipefail

readonly BACKUP_DIR="/home/arcblock/backups"
readonly TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
readonly BACKUP_FILE="blocklet-backup-${TIMESTAMP}.tar.gz"
readonly LOG_FILE="/home/arcblock/blocklet-server/logs/backup.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

mkdir -p "$BACKUP_DIR"
log "INFO: Starting backup process"

# Stop container for consistent backup
log "INFO: Stopping container for consistent backup"
if ! podman stop blocklet-server 2>/dev/null; then
    log "WARN: Failed to stop container gracefully, continuing with backup"
fi

# Create backup
if tar -czf "${BACKUP_DIR}/${BACKUP_FILE}" \
    -C /home/arcblock \
    .local/share/containers/storage/volumes/blocklet-server_blocklet-data \
    .local/share/containers/storage/volumes/blocklet-server_blocklet-config \
    blocklet-server/compose.yaml 2>/dev/null; then
    log "INFO: Backup created successfully: ${BACKUP_DIR}/${BACKUP_FILE}"
else
    log "ERROR: Backup creation failed"
fi

# Restart container
log "INFO: Restarting container"
if ! systemctl start blocklet-server; then
    log "ERROR: Failed to restart Blocklet Server service"
    exit 1
fi

# Remove old backups
find "$BACKUP_DIR" -name "blocklet-backup-*.tar.gz" -mtime +7 -delete 2>/dev/null || true
log "INFO: Cleanup completed - removed backups older than 7 days"
log "INFO: Backup process completed successfully"
EOF

chmod +x /home/$USER/blocklet-server/backup.sh
chown $USER:$USER /home/$USER/blocklet-server/backup.sh

# Configure log rotation
log "Configuring log rotation"
cat > /etc/logrotate.d/blocklet-server << 'EOF'
/home/arcblock/blocklet-server/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    copytruncate
    su arcblock arcblock
    postrotate
        systemctl reload blocklet-server 2>/dev/null || true
    endscript
}
EOF

# Setup cron jobs
log "Setting up monitoring cron jobs"
echo "*/5 * * * * /home/arcblock/blocklet-server/healthcheck.sh >/dev/null 2>&1" | sudo -u $USER crontab -
echo "0 2 * * 0 /home/arcblock/blocklet-server/backup.sh >/dev/null 2>&1" | sudo -u $USER crontab -

# Configure auto-updates
log "Configuring container auto-updates"
cat > /etc/systemd/system/podman-auto-update.timer << 'EOF'
[Unit]
Description=Podman auto-update timer

[Timer]
OnCalendar=daily
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOF

cat > /etc/systemd/system/podman-auto-update.service << 'EOF'
[Unit]
Description=Podman auto-update service

[Service]
Type=oneshot
User=arcblock
Group=arcblock
Environment=XDG_RUNTIME_DIR=/run/user/1000
ExecStart=/usr/bin/podman auto-update
ExecStartPost=/usr/bin/systemctl restart blocklet-server
EOF

# Enable and start services
log "Enabling and starting services"
systemctl enable fail2ban
systemctl start fail2ban
systemctl daemon-reload
systemctl enable blocklet-server
systemctl enable podman-auto-update.timer
systemctl start podman-auto-update.timer

# Start Blocklet Server
log "Starting Blocklet Server"
sudo -u $USER systemctl --user start podman.socket
systemctl start blocklet-server

# Wait for service to be ready
log "Waiting for Blocklet Server to become ready..."
attempts=0
max_attempts=24

while [ $attempts -lt $max_attempts ]; do
    if curl -sf --max-time 10 http://localhost:8089/api/did >/dev/null 2>&1; then
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
sudo -u $USER podman ps | grep -q blocklet-server || warning "Blocklet Server container may still be starting"

# Create completion marker
touch /home/$USER/blocklet-server/.setup-complete
chown $USER:$USER /home/$USER/blocklet-server/.setup-complete

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

success "Arcblock Blocklet Server setup completed successfully!"
log "Server IP: $SERVER_IP"
log "SSH Access: ssh -p $SSH_PORT $USER@$SERVER_IP"
log "Web Interface: http://$SERVER_IP:8089"
log "Setup completed at: $(date)"

echo ""
echo "=========================================="
echo "Arcblock Blocklet Server Setup Complete!"
echo "=========================================="
echo ""
echo "Access Information:"
echo "- SSH: ssh -p $SSH_PORT $USER@$SERVER_IP"
echo "- Web Interface: http://$SERVER_IP:8089"
echo "- Health Check: sudo -u $USER /home/$USER/blocklet-server/healthcheck.sh"
echo ""
echo "Services Status:"
echo "- Blocklet Server: $(systemctl is-active blocklet-server)"
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
echo "- Health logs: /home/$USER/blocklet-server/logs/health.log"
echo "=========================================="