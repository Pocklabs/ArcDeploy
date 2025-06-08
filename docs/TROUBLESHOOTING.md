# ArcDeploy Troubleshooting Guide

This comprehensive guide covers debugging and troubleshooting common issues with ArcDeploy's native Blocklet Server deployments.

## Quick Diagnostics

### Automated Diagnostic Script

Run our automated diagnostic script to quickly assess your deployment:

```bash
# Download and run diagnostic script
curl -fsSL https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/scripts/debug_commands.sh -o /tmp/debug_commands.sh
chmod +x /tmp/debug_commands.sh
/tmp/debug_commands.sh
```

### Manual Quick Checks

```bash
# 1. Check cloud-init status
sudo cloud-init status --long

# 2. Check user creation
id arcblock

# 3. Check service status
sudo systemctl status blocklet-server

# 4. Check Blocklet CLI installation
which blocklet && blocklet --version

# 5. Check HTTP endpoint
curl -f http://localhost:8080

# 6. Check HTTPS endpoint
curl -k -f https://localhost:8443

# 7. Check nginx proxy
curl -f http://localhost:80

# 8. Check Redis backend
redis-cli ping
```

## Common Issues and Solutions

### 1. Cloud-Init Failures

#### Issue: Cloud-init shows "error" or "degraded" status
```bash
sudo cloud-init status --long
# Shows: status: error
```

**Diagnosis:**
```bash
# Check detailed logs
sudo cat /var/log/cloud-init.log | tail -50

# Check output logs
sudo cat /var/log/cloud-init-output.log | tail -50

# Check for YAML syntax errors
sudo cloud-init schema --config-file /etc/cloud/cloud.cfg.d/50-curtin-networking.cfg

# Check specific cloud-init modules
sudo cloud-init single --name runcmd
```

**Common Causes:**
- YAML syntax errors in cloud-init configuration
- Network connectivity issues during package installation
- Insufficient disk space or memory
- Package repository unavailability

**Solutions:**
```bash
# Fix common YAML issues
sudo cloud-init clean --logs --seed
sudo cloud-init init --local
sudo cloud-init init
sudo cloud-init modules --mode config
sudo cloud-init modules --mode final

# Manual package installation if needed
sudo apt-get update
sudo apt-get install -y nodejs nginx redis-server
```

### 2. User Creation Issues

#### Issue: arcblock user not created or lacks permissions
```bash
id arcblock
# Shows: id: 'arcblock': no such user
```

**Diagnosis:**
```bash
# Check if user exists
grep arcblock /etc/passwd

# Check sudo permissions
sudo -l -U arcblock

# Check group memberships
groups arcblock

# Check home directory
ls -la /home/arcblock
```

**Solutions:**
```bash
# Create user manually
sudo useradd -m -G users,admin,sudo -s /bin/bash arcblock
echo "arcblock ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/arcblock

# Set up SSH keys
sudo mkdir -p /home/arcblock/.ssh
echo "YOUR_PUBLIC_KEY_HERE" | sudo tee /home/arcblock/.ssh/authorized_keys
sudo chown -R arcblock:arcblock /home/arcblock/.ssh
sudo chmod 700 /home/arcblock/.ssh
sudo chmod 600 /home/arcblock/.ssh/authorized_keys
```

### 3. SSH Connection Issues

#### Issue: Cannot connect via SSH on port 2222
```bash
ssh -p 2222 arcblock@YOUR_SERVER_IP
# Shows: Connection refused or Permission denied
```

**Diagnosis:**
```bash
# Check SSH service status
sudo systemctl status ssh

# Check SSH configuration
sudo grep -E "^Port|^PasswordAuthentication|^PubkeyAuthentication" /etc/ssh/sshd_config

# Check if port 2222 is listening
sudo netstat -tlnp | grep :2222

# Check firewall rules
sudo ufw status

# Check SSH logs
sudo journalctl -u ssh --no-pager -n 20
```

**Solutions:**
```bash
# Configure SSH properly
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

sudo tee /etc/ssh/sshd_config > /dev/null << 'EOF'
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

# Restart SSH service
sudo systemctl restart ssh

# Configure firewall
sudo ufw allow 2222/tcp
```

### 4. Node.js and Blocklet CLI Issues

#### Issue: Node.js not installed or wrong version
```bash
node --version
# Shows: command not found or old version
```

**Diagnosis:**
```bash
# Check Node.js installation
which node
node --version
npm --version

# Check Node.js repository
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo bash -c 'head -20'
```

**Solutions:**
```bash
# Install Node.js LTS
curl -fsSL https://deb.nodesource.com/setup_lts.x -o /tmp/nodesource_setup.sh
sudo bash /tmp/nodesource_setup.sh
sudo apt-get install -y nodejs

# Verify installation
node --version
npm --version
```

#### Issue: Blocklet CLI not installed or accessible
```bash
blocklet --version
# Shows: command not found
```

**Diagnosis:**
```bash
# Check global npm packages
npm list -g --depth=0

# Check Blocklet CLI specifically
npm list -g @blocklet/cli

# Check PATH
echo $PATH | grep npm
```

**Solutions:**
```bash
# Install Blocklet CLI globally
sudo npm install -g @blocklet/cli

# Verify installation
which blocklet
blocklet --version

# Fix PATH if needed
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc
```

### 5. Blocklet Server Service Issues

#### Issue: Blocklet Server service fails to start
```bash
sudo systemctl status blocklet-server
# Shows: failed (Result: exit-code)
```

**Diagnosis:**
```bash
# Check service logs
sudo journalctl -u blocklet-server --no-pager -n 50

# Check service configuration
sudo cat /etc/systemd/system/blocklet-server.service

# Check Blocklet Server configuration
sudo -u arcblock blocklet server config list

# Check directory permissions
ls -la /opt/blocklet-server
```

**Solutions:**
```bash
# Create/fix service directories
sudo mkdir -p /opt/blocklet-server/{bin,data,config,logs}
sudo chown -R arcblock:arcblock /opt/blocklet-server
sudo chmod 755 /opt/blocklet-server

# Initialize Blocklet Server
sudo -u arcblock blocklet server init /opt/blocklet-server

# Configure Blocklet Server
sudo -u arcblock blocklet server config set dataDir /opt/blocklet-server/data
sudo -u arcblock blocklet server config set port 8080

# Restart service
sudo systemctl daemon-reload
sudo systemctl restart blocklet-server
```

### 6. Network and Port Issues

#### Issue: Ports 8080/8443 not responding
```bash
curl -f http://localhost:8080
# Shows: Connection refused
```

**Port Migration Fix:**
The current version uses ports 8080/8443, not 8089. Update any references:

```bash
# Test current endpoint
curl http://YOUR_SERVER_IP:8080

# Test HTTPS endpoint
curl -k https://YOUR_SERVER_IP:8443

# NOT the old port
# curl http://YOUR_SERVER_IP:8089  # This won't work
```

**Diagnosis:**
```bash
# Check if ports are listening
sudo netstat -tlnp | grep -E ":8080|:8443"

# Check firewall rules
sudo ufw status

# Check service binding
sudo ss -tlnp | grep blocklet

# Check nginx configuration
sudo nginx -t
sudo systemctl status nginx
```

**Solutions:**
```bash
# Configure firewall
sudo ufw allow 8080/tcp comment 'Blocklet Server HTTP'
sudo ufw allow 8443/tcp comment 'Blocklet Server HTTPS'

# Test nginx configuration
sudo nginx -t

# Check if nginx is running
sudo systemctl status nginx

# Verify proxy configuration
sudo cat /etc/nginx/sites-available/blocklet-server

# Should proxy to 127.0.0.1:8080
```

### 7. Nginx Proxy Issues

#### Issue: Nginx not proxying correctly
```bash
curl -f http://localhost:80
# Shows: 502 Bad Gateway
```

**Diagnosis:**
```bash
# Check nginx status
sudo systemctl status nginx

# Check nginx configuration
sudo nginx -t

# Check nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Check if site is enabled
ls -la /etc/nginx/sites-enabled/
```

**Solutions:**
```bash
# Configure nginx properly
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

# Enable site
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/blocklet-server /etc/nginx/sites-enabled/

# Test and restart nginx
sudo nginx -t
sudo systemctl restart nginx
```

### 8. Redis Backend Issues

#### Issue: Redis not running or accessible
```bash
redis-cli ping
# Shows: Could not connect to Redis
```

**Diagnosis:**
```bash
# Check Redis status
sudo systemctl status redis-server

# Check Redis configuration
sudo cat /etc/redis/redis.conf | grep -E "^port|^bind"

# Check Redis logs
sudo journalctl -u redis-server --no-pager -n 20
```

**Solutions:**
```bash
# Install and configure Redis
sudo apt-get install -y redis-server

# Enable and start Redis
sudo systemctl enable redis-server
sudo systemctl start redis-server

# Test Redis connection
redis-cli ping
# Should return: PONG
```

### 9. SSL/TLS Certificate Issues

#### Issue: HTTPS endpoint not working
```bash
curl -k https://localhost:8443
# Shows: Connection refused
```

**Diagnosis:**
```bash
# Check if HTTPS port is listening
sudo netstat -tlnp | grep :8443

# Check Blocklet Server SSL configuration
sudo -u arcblock blocklet server config list | grep -i ssl

# Check certificate files
sudo find /opt/blocklet-server -name "*.crt" -o -name "*.key" -o -name "*.pem"
```

**Solutions:**
```bash
# Generate self-signed certificate if needed
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /opt/blocklet-server/config/server.key \
    -out /opt/blocklet-server/config/server.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# Set proper permissions
sudo chown -R arcblock:arcblock /opt/blocklet-server/config/
sudo chmod 600 /opt/blocklet-server/config/server.key
sudo chmod 644 /opt/blocklet-server/config/server.crt

# Restart Blocklet Server
sudo systemctl restart blocklet-server
```

### 10. Performance and Resource Issues

#### Issue: High memory or CPU usage
```bash
free -h
# Shows: very low available memory
```

**Diagnosis:**
```bash
# Check system resources
free -h
df -h
top -bn1 | head -20

# Check service resource usage
sudo systemctl status blocklet-server
ps aux | grep -E "blocklet|node|nginx|redis"

# Check system load
uptime
```

**Solutions:**
```bash
# Optimize Blocklet Server configuration
sudo -u arcblock blocklet server config set memory.limit 2048
sudo -u arcblock blocklet server config set workers 2

# Restart services to apply changes
sudo systemctl restart blocklet-server
sudo systemctl restart nginx
sudo systemctl restart redis-server

# Clean up logs and temporary files
sudo journalctl --vacuum-time=7d
sudo apt-get clean
sudo apt-get autoremove
```

## Recovery Procedures

### Complete System Recovery

If your deployment is completely broken, use our manual recovery script:

```bash
# Download and run recovery script
curl -fsSL https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/scripts/manual_recovery.sh -o /tmp/manual_recovery.sh
chmod +x /tmp/manual_recovery.sh
sudo /tmp/manual_recovery.sh
```

### Partial Recovery Procedures

#### If only service failed:
```bash
# Reset service configuration
sudo systemctl stop blocklet-server
sudo rm -f /etc/systemd/system/blocklet-server.service

# Recreate service
curl -fsSL https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/cloud-init.yaml | grep -A 20 "blocklet-server.service" | sudo tee /etc/systemd/system/blocklet-server.service

# Restart service
sudo systemctl daemon-reload
sudo systemctl enable blocklet-server
sudo systemctl start blocklet-server
```

#### If only nginx failed:
```bash
# Reinstall and configure nginx
sudo apt-get install --reinstall nginx

# Reconfigure nginx
curl -fsSL https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/scripts/setup.sh | grep -A 15 "sites-available/blocklet-server" | sudo bash

# Restart nginx
sudo systemctl restart nginx
```

#### If only SSH failed:
```bash
# Reset SSH configuration
sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config

# Reconfigure SSH
curl -fsSL https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/scripts/manual_recovery.sh | grep -A 20 "ssh-config.txt" | sudo bash

# Restart SSH
sudo systemctl restart ssh
```

### Firewall Reset

```bash
# Complete firewall reset
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp comment 'SSH'
sudo ufw allow 8080/tcp comment 'Blocklet Server HTTP'
sudo ufw allow 8443/tcp comment 'Blocklet Server HTTPS'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw --force enable
```

## Diagnostic and Log Collection

### Comprehensive System Check

```bash
# Download and run comprehensive diagnostic
curl -fsSL https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/scripts/validate-setup.sh -o /tmp/validate-setup.sh
chmod +x /tmp/validate-setup.sh
/tmp/validate-setup.sh
```

### Manual Diagnostic Collection

```bash
# System status
echo "=== System Information ==="
uname -a
lsb_release -a
uptime
free -h
df -h

echo "=== Service Status ==="
sudo systemctl status blocklet-server --no-pager
sudo systemctl status nginx --no-pager
sudo systemctl status redis-server --no-pager
sudo systemctl status ssh --no-pager

echo "=== Network Status ==="
sudo netstat -tlnp | grep -E ":22|:80|:443|:2222|:8080|:8443"
sudo ufw status verbose

echo "=== Application Status ==="
curl -sf http://localhost:8080 && echo "HTTP OK" || echo "HTTP FAILED"
curl -k -sf https://localhost:8443 && echo "HTTPS OK" || echo "HTTPS FAILED"
redis-cli ping && echo "Redis OK" || echo "Redis FAILED"

echo "=== Log Samples ==="
sudo journalctl -u blocklet-server --no-pager -n 10
sudo tail -n 10 /var/log/nginx/error.log
sudo tail -n 10 /var/log/cloud-init.log
```

### Log Bundle Creation

```bash
# Create comprehensive log bundle
mkdir -p /tmp/arcdeploy-logs
sudo cloud-init status --long > /tmp/arcdeploy-logs/cloud-init-status.txt
sudo cat /var/log/cloud-init.log > /tmp/arcdeploy-logs/cloud-init.log
sudo cat /var/log/cloud-init-output.log > /tmp/arcdeploy-logs/cloud-init-output.log
sudo systemctl status blocklet-server > /tmp/arcdeploy-logs/service-status.txt
sudo journalctl -u blocklet-server --no-pager > /tmp/arcdeploy-logs/service-logs.txt
sudo cat /var/log/nginx/access.log > /tmp/arcdeploy-logs/nginx-access.log
sudo cat /var/log/nginx/error.log > /tmp/arcdeploy-logs/nginx-error.log
sudo -u arcblock blocklet server config list > /tmp/arcdeploy-logs/blocklet-config.txt

# Create archive
tar -czf arcdeploy-debug-$(date +%Y%m%d-%H%M%S).tar.gz -C /tmp arcdeploy-logs/
echo "Log bundle created: arcdeploy-debug-$(date +%Y%m%d-%H%M%S).tar.gz"
```

## Advanced Troubleshooting

### Health Check Automation

```bash
# Run health check manually
sudo -u arcblock /opt/blocklet-server/healthcheck.sh

# Check health check cron job
sudo -u arcblock crontab -l | grep healthcheck

# View health check logs
sudo -u arcblock tail -f /opt/blocklet-server/logs/health.log
```

### Performance Monitoring

```bash
# Monitor system resources in real-time
htop

# Monitor specific service performance
sudo systemctl status blocklet-server
sudo journalctl -u blocklet-server -f

# Monitor network connections
sudo ss -tlnp | grep -E "(8080|8443|2222)"

# Monitor disk I/O
sudo iotop -ao

# Check service response times
time curl -f http://localhost:8080
```

### Security Validation

```bash
# Check SSH security
sudo sshd -T | grep -E "Port|PasswordAuthentication|PubkeyAuthentication"

# Check firewall rules
sudo ufw status verbose

# Check fail2ban status
sudo fail2ban-client status

# Check service permissions
ls -la /opt/blocklet-server
ps aux | grep blocklet | grep -v grep

# Check SSL/TLS configuration
sudo -u arcblock blocklet server config list | grep -i ssl
```

## Common Command Reference

### Service Management
```bash
# Status checks
sudo systemctl status blocklet-server
sudo systemctl status nginx
sudo systemctl status redis-server

# Service management
sudo systemctl restart blocklet-server
sudo systemctl restart nginx
sudo systemctl restart ssh

# Log viewing
sudo journalctl -u blocklet-server -f
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/cloud-init-output.log

# Configuration management
sudo -u arcblock blocklet server config list
sudo -u arcblock blocklet server status
sudo nginx -t
```

### Quick Fixes
```bash
# Restart all services
sudo systemctl restart blocklet-server nginx redis-server ssh

# Reset firewall
sudo ufw --force reset && sudo ufw default deny incoming && sudo ufw default allow outgoing && sudo ufw allow 2222/tcp && sudo ufw allow 8080/tcp && sudo ufw allow 8443/tcp && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp && sudo ufw --force enable

# Check all endpoints
curl -f http://localhost:8080 && curl -k -f https://localhost:8443 && curl -f http://localhost:80 && redis-cli ping

# Full system status
sudo systemctl is-active blocklet-server nginx redis-server ssh && echo "All services active"
```

## Getting Help

### Documentation Resources
- [Implementation Details](IMPLEMENTATION_DETAILS.md)
- [Debugging Guide](DEBUGGING_GUIDE.md)
- [Firewall Ports Guide](FIREWALL_PORTS_GUIDE.md)

### Automated Tools
- **Debug Script**: `scripts/debug_commands.sh` - 30+ diagnostic checks
- **Validation Script**: `scripts/validate-setup.sh` - Complete deployment validation
- **Recovery Script**: `scripts/manual_recovery.sh` - Full system recovery

### Support Channels
- **GitHub Issues**: [ArcDeploy Issues](https://github.com/Pocklabs/ArcDeploy/issues)
- **Documentation**: [ArcDeploy Documentation](https://github.com/Pocklabs/ArcDeploy/tree/main/docs)

---

**Note**: This troubleshooting guide is specifically for ArcDeploy's native installation architecture. All procedures assume a native Blocklet Server deployment without containers.