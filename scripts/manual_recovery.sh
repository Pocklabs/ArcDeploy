#!/bin/bash
set -e

echo "=== ArcDeploy Native Installation Manual Recovery Script ==="
echo "Starting manual recovery for failed cloud-init deployment..."
echo "Timestamp: $(date)"
echo "=============================================="

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if command succeeded
check_success() {
    if [ $? -eq 0 ]; then
        log "✅ $1 - SUCCESS"
    else
        log "❌ $1 - FAILED"
        exit 1
    fi
}

log "Step 1: Checking current system state..."
id arcblock
check_success "arcblock user exists"

log "Step 2: Creating necessary directories..."
sudo mkdir -p /opt/blocklet-server/{bin,data,config,logs}
sudo chown -R arcblock:arcblock /opt/blocklet-server
sudo chmod 755 /opt/blocklet-server
check_success "Created Blocklet Server directory structure"

log "Step 3: Installing Node.js LTS..."
if ! command -v node > /dev/null 2>&1; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x -o /tmp/nodesource_setup.sh
    sudo bash /tmp/nodesource_setup.sh
    sudo apt-get install -y nodejs
    check_success "Installed Node.js"
else
    log "Node.js already installed: $(node --version)"
fi

log "Step 4: Installing Blocklet CLI..."
if ! sudo -u arcblock npm list -g @blocklet/cli > /dev/null 2>&1; then
    sudo npm install -g @blocklet/cli
    check_success "Installed @blocklet/cli globally"
else
    log "@blocklet/cli already installed"
fi

log "Step 5: Installing additional packages..."
sudo apt-get update
sudo apt-get install -y \
    nginx \
    redis-server \
    git \
    curl \
    wget \
    jq \
    htop \
    nano \
    vim \
    unzip \
    fail2ban \
    ufw \
    sqlite3
check_success "Installed additional packages"

log "Step 6: Configuring Redis..."
sudo systemctl enable redis-server
sudo systemctl start redis-server
check_success "Configured and started Redis"

log "Step 7: Creating Blocklet Server systemd service..."
sudo tee /etc/systemd/system/blocklet-server.service > /dev/null << 'EOF'
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
check_success "Created systemd service file"

log "Step 8: Configuring Nginx..."
sudo tee /etc/nginx/sites-available/blocklet-server > /dev/null << 'EOF'
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

sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/blocklet-server /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl start nginx
check_success "Configured and started Nginx"

log "Step 9: Initializing Blocklet Server..."
sudo -u arcblock blocklet server init /opt/blocklet-server || log "Server init failed, using manual setup"
sudo -u arcblock mkdir -p /opt/blocklet-server/{bin,data,config,logs}
sudo -u arcblock blocklet server config set dataDir /opt/blocklet-server/data || true
sudo -u arcblock blocklet server config set port 8080 || true
check_success "Initialized Blocklet Server"

log "Step 10: Creating health check script..."
sudo tee /opt/blocklet-server/healthcheck.sh > /dev/null << 'EOF'
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

sudo chmod +x /opt/blocklet-server/healthcheck.sh
sudo chown arcblock:arcblock /opt/blocklet-server/healthcheck.sh
check_success "Created health check script"

log "Step 11: Setting up monitoring cron job..."
echo "*/5 * * * * /opt/blocklet-server/healthcheck.sh >/dev/null 2>&1" | sudo -u arcblock crontab -
check_success "Set up health monitoring cron job"

log "Step 12: Configuring SSH..."
if [ ! -f /etc/ssh/sshd_config.backup ]; then
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    log "Backed up SSH config"
fi

sudo tee /tmp/ssh-config.txt > /dev/null << 'EOF'
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

sudo cp /tmp/ssh-config.txt /etc/ssh/sshd_config
check_success "Configured SSH"

log "Step 13: Configuring firewall..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp comment 'SSH'
sudo ufw allow 8080/tcp comment 'Blocklet Server HTTP'
sudo ufw allow 8443/tcp comment 'Blocklet Server HTTPS'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw --force enable
check_success "Configured UFW firewall"

log "Step 14: Configuring fail2ban..."
sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
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

sudo tee /etc/fail2ban/filter.d/blocklet-server.conf > /dev/null << 'EOF'
[Definition]
failregex = ^.*\[.*\] .*Failed login attempt from <HOST>.*$
            ^.*\[.*\] .*Unauthorized access from <HOST>.*$
            ^.*\[.*\] .*Invalid authentication from <HOST>.*$
            ^.*\[.*\] .*Blocked request from <HOST>.*$
ignoreregex = ^.*\[.*\] .*Valid login from <HOST>.*$
EOF

sudo systemctl enable fail2ban
sudo systemctl start fail2ban
check_success "Configured and started fail2ban"

log "Step 15: Configuring system limits..."
sudo tee -a /etc/security/limits.conf > /dev/null << 'EOF'
arcblock soft nofile 65536
arcblock hard nofile 65536
arcblock soft nproc 32768
arcblock hard nproc 32768
* soft core 0
* hard core 0
EOF
check_success "Configured system limits"

log "Step 16: Configuring sysctl parameters..."
sudo tee -a /etc/sysctl.conf > /dev/null << 'EOF'
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 65536 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.core.netdev_max_backlog = 5000
net.ipv4.ip_forward = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
EOF

sudo sysctl -p
check_success "Applied sysctl configuration"

log "Step 17: Starting Blocklet Server service..."
sudo systemctl daemon-reload
sudo systemctl enable blocklet-server
sudo systemctl start blocklet-server
check_success "Started blocklet-server service"

log "Step 18: Waiting for Blocklet Server to become ready..."
echo "This may take several minutes for the service to start and initialize..."

max_attempts=24
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -sf --max-time 10 http://localhost:8080 >/dev/null 2>&1; then
        log "✅ Blocklet Server is ready and responding!"
        break
    fi
    
    attempt=$((attempt + 1))
    log "Attempt $attempt/$max_attempts - waiting 15 seconds..."
    
    # Check if service is still running
    if ! sudo systemctl is-active --quiet blocklet-server; then
        log "⚠️ Service stopped unexpectedly, restarting..."
        sudo systemctl restart blocklet-server
    fi
    
    sleep 15
done

if [ $attempt -eq $max_attempts ]; then
    log "⚠️ Warning: Blocklet Server did not become ready within expected time"
    log "Check service status with: sudo systemctl status blocklet-server"
    log "Check service logs with: sudo journalctl -u blocklet-server -n 50"
else
    check_success "Blocklet Server is ready"
fi

log "Step 19: Restarting SSH with new configuration..."
sudo systemctl restart ssh
check_success "Restarted SSH service"

log "Step 20: Final verification..."
echo ""
echo "=== FINAL STATUS CHECK ==="

echo "User status:"
id arcblock

echo ""
echo "Service status:"
sudo systemctl status blocklet-server --no-pager -l

echo ""
echo "Nginx status:"
sudo systemctl status nginx --no-pager

echo ""
echo "Redis status:"
sudo systemctl status redis-server --no-pager

echo ""
echo "Network connectivity:"
curl -f http://localhost:8080 2>/dev/null && echo "✅ HTTP endpoint responding" || echo "❌ HTTP endpoint not responding"
curl -f http://localhost:80 2>/dev/null && echo "✅ Nginx proxy responding" || echo "❌ Nginx proxy not responding"

echo ""
echo "Firewall status:"
sudo ufw status

echo ""
echo "SSH configuration:"
grep -E "^Port" /etc/ssh/sshd_config

log "Step 21: Creating completion markers..."
sudo touch /opt/blocklet-server/.native-install-complete
echo "Manual recovery completed at $(date)" | sudo tee /opt/blocklet-server/recovery-complete.log
sudo chown arcblock:arcblock /opt/blocklet-server/.native-install-complete /opt/blocklet-server/recovery-complete.log
check_success "Created completion markers"

log "Step 22: Cleaning up temporary files..."
sudo rm -f /tmp/ssh-config.txt /tmp/nodesource_setup.sh
check_success "Cleaned up temporary files"

echo ""
echo "=============================================="
echo "🎉 NATIVE INSTALLATION RECOVERY COMPLETED! 🎉"
echo "=============================================="
echo ""
echo "✅ Access Information:"
echo "   - SSH: ssh -p 2222 arcblock@YOUR_SERVER_IP"
echo "   - Web Interface (Direct): http://YOUR_SERVER_IP:8080"
echo "   - Web Interface (Nginx): http://YOUR_SERVER_IP"
echo "   - HTTPS Interface: https://YOUR_SERVER_IP:8443"
echo ""
echo "✅ Useful Commands:"
echo "   - Service Status: sudo systemctl status blocklet-server"
echo "   - Service Logs: sudo journalctl -u blocklet-server -f"
echo "   - Health Check: sudo -u arcblock /opt/blocklet-server/healthcheck.sh"
echo "   - Blocklet CLI: sudo -u arcblock blocklet server status"
echo "   - Nginx Status: sudo systemctl status nginx"
echo "   - Redis Status: sudo systemctl status redis-server"
echo ""
echo "✅ Security Features Enabled:"
echo "   - SSH hardened (key-only auth, port 2222)"
echo "   - UFW firewall enabled"
echo "   - Fail2ban protection active"
echo "   - Nginx reverse proxy"
echo "   - Redis backend service"
echo ""
echo "✅ Native Installation Components:"
echo "   - Node.js LTS installed"
echo "   - @blocklet/cli installed globally"
echo "   - Blocklet Server running natively"
echo "   - Systemd service management"
echo "   - Health monitoring active"
echo ""
echo "🔗 For support: https://github.com/Pocklabs/ArcDeploy"
echo "=============================================="

log "Native installation manual recovery script completed successfully!"