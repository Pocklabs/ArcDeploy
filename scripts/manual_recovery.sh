#!/bin/bash
set -e

echo "=== ArcDeploy Manual Recovery Script ==="
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
sudo mkdir -p /home/arcblock/blocklet-server
sudo chown -R arcblock:arcblock /home/arcblock
check_success "Created blocklet-server directory"

log "Step 3: Creating compose.yaml file..."
sudo tee /home/arcblock/blocklet-server/compose.yaml > /dev/null << 'EOF'
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
    environment:
      - ABT_NODE_LOG_LEVEL=info
      - ABT_NODE_ENV=production
      - ABT_NODE_HOST=0.0.0.0
      - ABT_NODE_PORT=8089
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8089/api/did"]
      interval: 30s
      timeout: 10s
      retries: 3
volumes:
  blocklet-data:
  blocklet-config:
EOF
sudo chown arcblock:arcblock /home/arcblock/blocklet-server/compose.yaml
check_success "Created compose.yaml"

log "Step 4: Creating systemd service file..."
sudo tee /etc/systemd/system/blocklet-server.service > /dev/null << 'EOF'
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
ExecStartPre=/usr/bin/podman compose down --remove-orphans
ExecStart=/usr/bin/podman compose up -d
ExecStop=/usr/bin/podman compose down --timeout 30
TimeoutStartSec=300
TimeoutStopSec=120

[Install]
WantedBy=multi-user.target
EOF
check_success "Created systemd service file"

log "Step 5: Configuring Podman for rootless operation..."
if ! grep -q "arcblock:100000:65536" /etc/subuid; then
    echo 'arcblock:100000:65536' | sudo tee -a /etc/subuid
    log "Added subuid configuration"
fi

if ! grep -q "arcblock:100000:65536" /etc/subgid; then
    echo 'arcblock:100000:65536' | sudo tee -a /etc/subgid
    log "Added subgid configuration"
fi

sudo loginctl enable-linger arcblock
check_success "Enabled user lingering for arcblock"

log "Step 6: Setting up Podman socket..."
sudo -u arcblock systemctl --user enable podman.socket
sudo -u arcblock systemctl --user start podman.socket
check_success "Started Podman socket"

log "Step 7: Installing Blocklet CLI..."
sudo -u arcblock npm install -g @blocklet/cli
check_success "Installed @blocklet/cli"

log "Step 8: Pulling container image..."
sudo -u arcblock podman pull arcblock/blocklet-server:latest
check_success "Pulled blocklet-server container image"

log "Step 9: Configuring SSH..."
if [ ! -f /etc/ssh/sshd_config.backup ]; then
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    log "Backed up SSH config"
fi

sudo tee /tmp/ssh-config.txt > /dev/null << 'EOF'
Port 2222
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
X11Forwarding no
AllowTcpForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers arcblock
EOF

sudo cp /tmp/ssh-config.txt /etc/ssh/sshd_config
check_success "Configured SSH"

log "Step 10: Configuring firewall..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp comment 'SSH'
sudo ufw allow 8089/tcp comment 'Blocklet Server'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw --force enable
check_success "Configured UFW firewall"

log "Step 11: Configuring fail2ban..."
sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 2222
banaction = iptables-multiport
EOF

sudo systemctl enable fail2ban
sudo systemctl start fail2ban
check_success "Configured and started fail2ban"

log "Step 12: Starting Blocklet Server service..."
sudo systemctl daemon-reload
sudo systemctl enable blocklet-server
sudo systemctl start blocklet-server
check_success "Started blocklet-server service"

log "Step 13: Waiting for Blocklet Server to become ready..."
echo "This may take several minutes for the container to start and initialize..."

max_attempts=24
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -sf --max-time 10 http://localhost:8089/api/did >/dev/null 2>&1; then
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
    log "Check container logs with: sudo -u arcblock podman logs blocklet-server"
else
    check_success "Blocklet Server is ready"
fi

log "Step 14: Restarting SSH with new configuration..."
sudo systemctl restart ssh
check_success "Restarted SSH service"

log "Step 15: Final verification..."
echo ""
echo "=== FINAL STATUS CHECK ==="

echo "User status:"
id arcblock

echo ""
echo "Service status:"
sudo systemctl status blocklet-server --no-pager -l

echo ""
echo "Container status:"
sudo -u arcblock podman ps

echo ""
echo "Network connectivity:"
curl -f http://localhost:8089/api/did 2>/dev/null && echo "✅ API endpoint responding" || echo "❌ API endpoint not responding"

echo ""
echo "Firewall status:"
sudo ufw status

echo ""
echo "SSH configuration:"
grep -E "^Port" /etc/ssh/sshd_config

log "Step 16: Creating completion marker..."
sudo touch /home/arcblock/.manual-recovery-complete
echo "Manual recovery completed at $(date)" | sudo tee /home/arcblock/recovery-complete.log
sudo chown arcblock:arcblock /home/arcblock/.manual-recovery-complete /home/arcblock/recovery-complete.log
check_success "Created completion markers"

log "Step 17: Cleaning up temporary files..."
sudo rm -f /tmp/ssh-config.txt
check_success "Cleaned up temporary files"

echo ""
echo "=============================================="
echo "🎉 MANUAL RECOVERY COMPLETED SUCCESSFULLY! 🎉"
echo "=============================================="
echo ""
echo "✅ Access Information:"
echo "   - SSH: ssh -p 2222 arcblock@YOUR_SERVER_IP"
echo "   - Web Interface: http://YOUR_SERVER_IP:8089"
echo ""
echo "✅ Useful Commands:"
echo "   - Service Status: sudo systemctl status blocklet-server"
echo "   - Container Status: sudo -u arcblock podman ps"
echo "   - Container Logs: sudo -u arcblock podman logs blocklet-server"
echo "   - Service Logs: sudo journalctl -u blocklet-server -f"
echo ""
echo "✅ Security Features Enabled:"
echo "   - SSH hardened (key-only auth, port 2222)"
echo "   - UFW firewall enabled"
echo "   - Fail2ban protection active"
echo "   - Rootless Podman containers"
echo ""
echo "🔗 For support: https://github.com/Pocklabs/ArcDeploy"
echo "=============================================="

log "Manual recovery script completed successfully!"