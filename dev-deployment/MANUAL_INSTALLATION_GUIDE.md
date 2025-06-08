# ArcDeploy Manual Installation Guide

**Document Version**: 1.0  
**Created**: June 8, 2025  
**Target Audience**: System Administrators & DevOps Engineers  
**Environment**: Ubuntu 22.04 LTS Server

## Overview

This guide provides step-by-step instructions for manually installing ArcDeploy on a fresh Ubuntu 22.04 server, starting from root access and creating the arcblock user with proper security configuration.

**Prerequisites:**
- Fresh Ubuntu 22.04 LTS server
- Root SSH access with SSH key authentication
- Minimum 4GB RAM, 40GB disk space
- Internet connectivity for package downloads

---

## Phase 1: Initial Server Preparation

### Step 1: Connect to Server as Root

```bash
# Connect to your server as root
ssh -i /path/to/your/private-key root@YOUR_SERVER_IP

# Verify system information
uname -a
cat /etc/os-release
```

### Step 2: Update System Packages

```bash
# Update package repository
apt update

# Upgrade all packages
apt upgrade -y

# Install essential packages
apt install -y curl wget git build-essential software-properties-common \
    apt-transport-https ca-certificates gnupg lsb-release jq htop nano vim \
    unzip fail2ban ufw python3 python3-pip nginx sqlite3 redis-server \
    net-tools systemd
```

### Step 3: Configure Basic Security

```bash
# Configure UFW firewall (initial setup)
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# Allow SSH on default port 22 (we'll change this later)
ufw allow 22/tcp comment 'SSH - temporary'

# Enable firewall
ufw --force enable

# Verify firewall status
ufw status verbose
```

---

## Phase 2: User Management and SSH Security

### Step 4: Create arcblock User

```bash
# Create arcblock user with home directory
useradd -m -s /bin/bash arcblock

# Add arcblock to sudo group
usermod -aG sudo arcblock

# Set up directory structure
mkdir -p /home/arcblock/.ssh
mkdir -p /opt/blocklet-server/{bin,data,config,logs}

# Set proper ownership
chown -R arcblock:arcblock /home/arcblock
chown -R arcblock:arcblock /opt/blocklet-server
```

### Step 5: Configure SSH Keys for arcblock User

```bash
# Copy your SSH public key to arcblock user
# Replace with your actual public key
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... your-email@example.com" > /home/arcblock/.ssh/authorized_keys

# Set proper permissions
chmod 700 /home/arcblock/.ssh
chmod 600 /home/arcblock/.ssh/authorized_keys
chown -R arcblock:arcblock /home/arcblock/.ssh

# Verify SSH key setup
ls -la /home/arcblock/.ssh/
cat /home/arcblock/.ssh/authorized_keys
```

### Step 6: Configure SSH Hardening

```bash
# Backup original SSH configuration
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Create new SSH configuration
cat > /etc/ssh/sshd_config << 'EOF'
# ArcDeploy SSH Configuration
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

# Update firewall for new SSH port
ufw allow 2222/tcp comment 'SSH - secure port'
ufw delete allow 22/tcp

# Test SSH configuration
sshd -t

# Restart SSH service
systemctl restart ssh
systemctl status ssh
```

### Step 7: Test SSH Access

**IMPORTANT**: Open a new terminal window to test before closing the current session!

```bash
# In a NEW terminal window, test SSH access as arcblock user
ssh -p 2222 -i /path/to/your/private-key arcblock@YOUR_SERVER_IP

# If successful, verify sudo access
sudo whoami  # Should output: root

# Test basic commands
id
pwd
sudo systemctl status ssh
```

**Only proceed if SSH access works correctly!**

---

## Phase 3: Node.js and Application Setup

### Step 8: Install Node.js LTS

```bash
# Download Node.js setup script
curl -fsSL https://deb.nodesource.com/setup_lts.x -o /tmp/nodesource_setup.sh

# Install Node.js
bash /tmp/nodesource_setup.sh
apt-get install -y nodejs

# Verify installation
node --version
npm --version

# Clean up
rm /tmp/nodesource_setup.sh
```

### Step 9: Install Blocklet CLI

```bash
# Install Blocklet CLI globally
npm install -g @blocklet/cli

# Verify installation
which blocklet
blocklet --version

# Test CLI access for arcblock user
sudo -u arcblock blocklet --version
```

### Step 10: Configure Redis

```bash
# Enable and start Redis
systemctl enable redis-server
systemctl start redis-server

# Test Redis connectivity
redis-cli ping  # Should return: PONG

# Verify Redis status
systemctl status redis-server
```

---

## Phase 4: Web Server and Proxy Configuration

### Step 11: Configure Nginx

```bash
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

# Test Nginx configuration
nginx -t

# Enable and start Nginx
systemctl enable nginx
systemctl start nginx
systemctl status nginx
```

### Step 12: Configure Firewall for Web Services

```bash
# Allow HTTP and HTTPS traffic
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw allow 8080/tcp comment 'Blocklet Server HTTP'
ufw allow 8443/tcp comment 'Blocklet Server HTTPS'

# Verify firewall rules
ufw status numbered
```

---

## Phase 5: Security Hardening

### Step 13: Configure Fail2ban

```bash
# Create Fail2ban jail configuration
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

# Create Blocklet Server filter
cat > /etc/fail2ban/filter.d/blocklet-server.conf << 'EOF'
[Definition]
failregex = ^.*\[.*\] .*Failed login attempt from <HOST>.*$
            ^.*\[.*\] .*Unauthorized access from <HOST>.*$
            ^.*\[.*\] .*Invalid authentication from <HOST>.*$
            ^.*\[.*\] .*Blocked request from <HOST>.*$
ignoreregex = ^.*\[.*\] .*Valid login from <HOST>.*$
EOF

# Enable and start Fail2ban
systemctl enable fail2ban
systemctl start fail2ban
systemctl status fail2ban

# Check Fail2ban status
fail2ban-client status
```

### Step 14: System Hardening

```bash
# Configure system limits
cat >> /etc/security/limits.conf << 'EOF'
arcblock soft nofile 65536
arcblock hard nofile 65536
arcblock soft nproc 32768
arcblock hard nproc 32768
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

# Apply kernel parameters
sysctl -p
```

---

## Phase 6: Blocklet Server Setup

### Step 15: Initialize Blocklet Server

```bash
# Switch to arcblock user for initialization
sudo -u arcblock bash << 'EOF'
cd /opt/blocklet-server

# Initialize Blocklet Server
blocklet server init /opt/blocklet-server || echo "Manual initialization required"

# Create necessary directories
mkdir -p /opt/blocklet-server/{bin,data,config,logs}

# Configure Blocklet Server
blocklet server config set dataDir /opt/blocklet-server/data || true
blocklet server config set port 8080 || true
blocklet server config set host 0.0.0.0 || true
EOF
```

### Step 16: Create Systemd Service

```bash
# Create Blocklet Server systemd service
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

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable blocklet-server
```

### Step 17: Create Health Check Script

```bash
# Create health check script
cat > /opt/blocklet-server/healthcheck.sh << 'EOF'
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

# Set permissions
chmod 755 /opt/blocklet-server/healthcheck.sh
chown arcblock:arcblock /opt/blocklet-server/healthcheck.sh
```

---

## Phase 7: Service Startup and Verification

### Step 18: Start Services

```bash
# Start Blocklet Server service
systemctl start blocklet-server

# Check service status
systemctl status blocklet-server

# View service logs
journalctl -u blocklet-server -f --no-pager -n 50
```

### Step 19: Configure Health Monitoring

```bash
# Set up cron job for health monitoring
sudo -u arcblock bash << 'EOF'
# Add health check to crontab (every 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/blocklet-server/healthcheck.sh >/dev/null 2>&1") | crontab -
EOF

# Verify cron job
sudo -u arcblock crontab -l
```

### Step 20: Final Service Verification

```bash
# Wait for services to stabilize
sleep 30

# Test all endpoints
echo "Testing HTTP endpoints..."

# Test Blocklet Server direct access
curl -I http://localhost:8080 || echo "Blocklet Server not ready yet"

# Test Nginx proxy
curl -I http://localhost:80 || echo "Nginx proxy not ready yet"

# Test Redis
redis-cli ping

# Check all service statuses
systemctl status nginx
systemctl status redis-server
systemctl status blocklet-server
systemctl status fail2ban

# Run health check manually
sudo -u arcblock /opt/blocklet-server/healthcheck.sh
```

---

## Phase 8: Post-Installation Security

### Step 21: Remove Root SSH Access (Optional but Recommended)

**WARNING**: Only do this after confirming arcblock SSH access works!

```bash
# Disable root login completely
sed -i 's/PermitRootLogin no/PermitRootLogin no/' /etc/ssh/sshd_config

# Restart SSH service
systemctl restart ssh

# Test that root access is blocked (this should fail)
# ssh -p 2222 root@YOUR_SERVER_IP
```

### Step 22: Create Installation Completion Marker

```bash
# Create completion marker
touch /opt/blocklet-server/.manual-install-complete
echo "Manual installation completed on $(date)" > /opt/blocklet-server/.manual-install-complete
chown arcblock:arcblock /opt/blocklet-server/.manual-install-complete

# Final system cleanup
apt autoremove -y
apt autoclean
```

---

## Phase 9: Validation and Testing

### Step 23: Comprehensive System Test

```bash
# Download and run validation script
curl -fsSL https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/scripts/validate-setup.sh -o /tmp/validate-setup.sh
chmod +x /tmp/validate-setup.sh
/tmp/validate-setup.sh
```

### Step 24: Security Validation

```bash
# Check firewall status
ufw status verbose

# Check fail2ban status
fail2ban-client status

# Check SSH configuration
sshd -T | grep -E "(port|permitrootlogin|passwordauthentication|allowusers)"

# Check service security
ps aux | grep -E "(blocklet|nginx|redis)" | grep -v grep

# Verify file permissions
ls -la /opt/blocklet-server/
ls -la /home/arcblock/.ssh/
```

---

## Troubleshooting Common Issues

### SSH Connection Problems

```bash
# Check SSH service status
systemctl status ssh

# Check SSH logs
journalctl -u ssh -n 50

# Test SSH configuration
sshd -t

# Check firewall
ufw status | grep 2222
```

### Blocklet Server Issues

```bash
# Check service logs
journalctl -u blocklet-server -n 100

# Check process status
ps aux | grep blocklet

# Check port binding
netstat -tlnp | grep 8080

# Manual service restart
systemctl restart blocklet-server
```

### Network Connectivity Issues

```bash
# Check listening ports
netstat -tlnp

# Test local connectivity
curl -v http://localhost:8080
curl -v http://localhost:80

# Check nginx logs
tail -f /var/log/nginx/error.log
tail -f /var/log/nginx/access.log
```

---

## Final Access Information

### SSH Access
```bash
ssh -p 2222 arcblock@YOUR_SERVER_IP
```

### Web Interfaces
- **Blocklet Server**: `http://YOUR_SERVER_IP:8080`
- **Nginx Proxy**: `http://YOUR_SERVER_IP:80`
- **HTTPS (if configured)**: `https://YOUR_SERVER_IP:8443`

### Service Management Commands
```bash
# Check service status
sudo systemctl status blocklet-server

# View logs
sudo journalctl -u blocklet-server -f

# Restart service
sudo systemctl restart blocklet-server

# Run health check
/opt/blocklet-server/healthcheck.sh
```

---

## Security Considerations

### Completed Security Measures
- ✅ SSH hardened (port 2222, key-only authentication)
- ✅ Root login disabled
- ✅ UFW firewall configured with minimal ports
- ✅ Fail2ban intrusion detection active
- ✅ Non-root service execution
- ✅ System resource limits configured
- ✅ Kernel security parameters optimized

### Additional Security Recommendations
1. **Regular Updates**: Set up automatic security updates
2. **SSL/TLS**: Configure SSL certificates for HTTPS
3. **Monitoring**: Implement log aggregation and alerting
4. **Backups**: Configure automated backup procedures
5. **Vulnerability Scanning**: Regular security assessments

---

## Next Steps

1. **Configure SSL/TLS**: Set up Let's Encrypt certificates
2. **Monitoring Setup**: Implement comprehensive monitoring
3. **Backup Strategy**: Configure automated backups
4. **Documentation**: Document any customizations
5. **Team Access**: Add additional SSH keys as needed

---

**Installation Complete!**

Your ArcDeploy Blocklet Server is now running with comprehensive security hardening. The system is ready for production use with proper monitoring, security controls, and automated health checking.

For ongoing maintenance and updates, refer to the main ArcDeploy documentation at: https://github.com/Pocklabs/ArcDeploy

**Support**: For issues or questions, please refer to the troubleshooting documentation or create an issue in the GitHub repository.