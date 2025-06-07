# ArcDeploy Troubleshooting Guide

This comprehensive guide covers debugging and troubleshooting common issues with ArcDeploy Blocklet Server deployments.

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

# 4. Check containers
sudo -u arcblock podman ps

# 5. Check API endpoint
curl -f http://localhost:8089/api/did
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
sudo cat /var/log/cloud-init-output.log | tail -50

# Check what configuration was used
sudo cat /var/lib/cloud/instance/user-data.txt
```

**Common Causes:**
- **YAML formatting errors**: Incorrect indentation in cloud-init file
- **User creation before file writes**: Files written to user home before user exists
- **Missing dependencies**: Required packages not installed
- **Network connectivity**: Unable to download external resources

**Solutions:**
```bash
# For user creation issues
sudo useradd -m -s /bin/bash -G users,admin,sudo arcblock
sudo mkdir -p /home/arcblock/.ssh
echo "YOUR_SSH_KEY" | sudo tee /home/arcblock/.ssh/authorized_keys
sudo chown -R arcblock:arcblock /home/arcblock
sudo chmod 700 /home/arcblock/.ssh
sudo chmod 600 /home/arcblock/.ssh/authorized_keys

# Re-run cloud-init (destructive)
sudo cloud-init clean --logs
sudo cloud-init init
```

### 2. Blocklet Server Service Issues

#### Issue: Service not found or won't start
```bash
sudo systemctl status blocklet-server
# Shows: Unit blocklet-server.service could not be found
```

**Diagnosis:**
```bash
# Check if service file exists
ls -la /etc/systemd/system/blocklet-server.service

# Check service logs
sudo journalctl -u blocklet-server --no-pager

# Check working directory
ls -la /home/arcblock/blocklet-server/
```

**Solution - Manual Service Creation:**
```bash
# Create service file
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

# Reload and start
sudo systemctl daemon-reload
sudo systemctl enable blocklet-server
sudo systemctl start blocklet-server
```

### 3. Container Issues

#### Issue: No containers running
```bash
sudo -u arcblock podman ps
# Shows: CONTAINER ID  IMAGE  COMMAND  CREATED  STATUS  PORTS  NAMES
```

**Diagnosis:**
```bash
# Check Podman configuration
sudo -u arcblock podman info | head -20

# Check if image was pulled
sudo -u arcblock podman images

# Check compose file
cat /home/arcblock/blocklet-server/compose.yaml

# Check for errors
sudo -u arcblock podman logs blocklet-server 2>/dev/null || echo "No container logs"
```

**Common Causes:**
- **Rootless Podman not configured**: Missing subuid/subgid configuration
- **Missing compose file**: Docker compose configuration not created
- **Image pull failures**: Network issues or authentication problems
- **Permission issues**: User can't access Podman socket

**Solutions:**
```bash
# Configure rootless Podman
echo 'arcblock:100000:65536' | sudo tee -a /etc/subuid
echo 'arcblock:100000:65536' | sudo tee -a /etc/subgid
sudo loginctl enable-linger arcblock

# Setup Podman socket
sudo -u arcblock systemctl --user enable podman.socket
sudo -u arcblock systemctl --user start podman.socket

# Pull image manually
sudo -u arcblock podman pull arcblock/blocklet-server:latest

# Create compose file if missing
sudo mkdir -p /home/arcblock/blocklet-server
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
sudo chown -R arcblock:arcblock /home/arcblock/blocklet-server
```

### 4. Network Connectivity Issues

#### Issue: API endpoint not responding
```bash
curl -f http://localhost:8089/api/did
# Shows: curl: (7) Failed to connect to localhost port 8089
```

**Diagnosis:**
```bash
# Check if port is listening
sudo netstat -tlnp | grep 8089

# Check firewall
sudo ufw status

# Check container port mapping
sudo -u arcblock podman port blocklet-server

# Check service status
sudo systemctl status blocklet-server

# Check container health
sudo -u arcblock podman inspect blocklet-server | grep -A 10 -B 10 Health
```

**Solutions:**
```bash
# Configure firewall
sudo ufw allow 8089/tcp

# Restart service
sudo systemctl restart blocklet-server

# Check container startup
sudo -u arcblock podman compose -f /home/arcblock/blocklet-server/compose.yaml up -d

# Wait for service to be ready
for i in {1..12}; do
  if curl -sf http://localhost:8089/api/did; then
    echo "Service is ready!"
    break
  fi
  echo "Waiting... attempt $i/12"
  sleep 15
done
```

### 5. SSH Access Issues

#### Issue: Cannot SSH to server
```bash
ssh -p 2222 arcblock@YOUR_SERVER_IP
# Shows: Connection refused or timeout
```

**Diagnosis:**
```bash
# Check SSH service
sudo systemctl status ssh

# Check SSH configuration
sudo sshd -T | grep -E "^port|^passwordauthentication|^pubkeyauthentication"

# Check firewall
sudo ufw status | grep 2222

# Test local SSH
ssh -p 2222 arcblock@localhost
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
PubkeyAuthentication yes
MaxAuthTries 3
X11Forwarding no
AllowTcpForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers arcblock
EOF

# Restart SSH
sudo systemctl restart ssh

# Configure firewall
sudo ufw allow 2222/tcp
```

## Manual Recovery Procedures

### Complete Manual Recovery

If cloud-init completely failed, use our automated recovery script:

```bash
# Download and run recovery script
curl -fsSL https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/scripts/manual_recovery.sh -o /tmp/manual_recovery.sh
chmod +x /tmp/manual_recovery.sh
sudo /tmp/manual_recovery.sh
```

### Partial Recovery Steps

#### If only container setup failed:
```bash
# Configure Podman
echo 'arcblock:100000:65536' | sudo tee -a /etc/subuid
echo 'arcblock:100000:65536' | sudo tee -a /etc/subgid
sudo loginctl enable-linger arcblock

# Start Podman services
sudo -u arcblock systemctl --user enable podman.socket
sudo -u arcblock systemctl --user start podman.socket

# Install CLI and pull image
sudo -u arcblock npm install -g @blocklet/cli
sudo -u arcblock podman pull arcblock/blocklet-server:latest

# Start service
sudo systemctl start blocklet-server
```

#### If only network setup failed:
```bash
# Configure firewall
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp
sudo ufw allow 8089/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Configure fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## Configuration Validation

### Pre-deployment Validation
```bash
# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('cloud-init.yaml'))"

# Check SSH key format
grep -E "^ssh-(rsa|dss|ecdsa|ed25519)" cloud-init.yaml

# Validate required fields
grep -E "(users|packages|write_files|runcmd)" cloud-init.yaml
```

### Post-deployment Validation
```bash
# Complete system check
curl -fsSL https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/scripts/debug_commands.sh | bash

# Service health check
sudo systemctl is-active blocklet-server
sudo -u arcblock podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
curl -sf http://localhost:8089/api/did && echo "API OK" || echo "API FAILED"
```

## Known Issues and Workarounds

### 1. ARM Server Compatibility
- **Issue**: Cloud-init may not execute properly on ARM-based Hetzner servers
- **Workaround**: Use x86_64 servers (CX31, CX41, etc.)

### 2. Container Image Availability
- **Issue**: `arcblock/blocklet-server:latest` may require authentication
- **Workaround**: Use native installation (`native-install.yaml`)

### 3. Network Timeout Issues
- **Issue**: Package downloads may fail in some regions
- **Workaround**: Retry deployment or use different package mirrors

### 4. Cloud Provider Compatibility
- **Issue**: Some cloud providers may have different cloud-init implementations
- **Workaround**: Test deployment in development environment first

## Advanced Debugging

### Container Debugging
```bash
# Access running container
sudo -u arcblock podman exec -it blocklet-server /bin/bash

# Check container logs
sudo -u arcblock podman logs blocklet-server --tail 100

# Check container resource usage
sudo -u arcblock podman stats

# Inspect container configuration
sudo -u arcblock podman inspect blocklet-server
```

### System Performance Debugging
```bash
# Check system resources
free -h
df -h
top -bn1 | head -20

# Check network connectivity
ss -tlnp | grep -E "(8089|2222)"
ping -c 3 8.8.8.8

# Check system logs
sudo journalctl --since "1 hour ago" | grep -E "(error|failed|critical)"
```

### Log Analysis
```bash
# Cloud-init logs
sudo journalctl -u cloud-init --no-pager
sudo journalctl -u cloud-config --no-pager
sudo journalctl -u cloud-final --no-pager

# Service logs
sudo journalctl -u blocklet-server --no-pager -f

# System logs
sudo journalctl --since "1 hour ago" --no-pager
```

## Getting Help

### Log Collection
Before seeking help, collect these logs:
```bash
# Create log bundle
mkdir -p /tmp/arcdeploy-logs
sudo cloud-init status --long > /tmp/arcdeploy-logs/cloud-init-status.txt
sudo cat /var/log/cloud-init.log > /tmp/arcdeploy-logs/cloud-init.log
sudo cat /var/log/cloud-init-output.log > /tmp/arcdeploy-logs/cloud-init-output.log
sudo systemctl status blocklet-server > /tmp/arcdeploy-logs/service-status.txt
sudo -u arcblock podman ps -a > /tmp/arcdeploy-logs/containers.txt
sudo journalctl -u blocklet-server --no-pager > /tmp/arcdeploy-logs/service-logs.txt

# Create archive
tar -czf arcdeploy-debug-$(date +%Y%m%d-%H%M%S).tar.gz -C /tmp arcdeploy-logs/
```

### Support Channels
- **GitHub Issues**: [Report bugs and issues](https://github.com/Pocklabs/ArcDeploy/issues)
- **GitHub Discussions**: [Community support](https://github.com/Pocklabs/ArcDeploy/discussions)
- **Documentation**: [Project Wiki](https://github.com/Pocklabs/ArcDeploy/wiki)

### Emergency Recovery
If you're completely locked out:
1. **Access via Hetzner Console**: Use the web-based console in Hetzner Cloud
2. **Reset SSH**: Redeploy server with corrected cloud-init configuration
3. **Manual Installation**: Skip cloud-init and install manually via console

---

## Quick Reference Commands

```bash
# Status checks
sudo cloud-init status --long
sudo systemctl status blocklet-server
sudo -u arcblock podman ps
curl -f http://localhost:8089/api/did

# Service management
sudo systemctl restart blocklet-server
sudo -u arcblock podman restart blocklet-server
sudo systemctl restart ssh

# Log viewing
sudo journalctl -u blocklet-server -f
sudo -u arcblock podman logs blocklet-server --tail 50
sudo tail -f /var/log/cloud-init-output.log

# Recovery
curl -fsSL https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/scripts/debug_commands.sh | bash
curl -fsSL https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/scripts/manual_recovery.sh -o /tmp/recovery.sh && chmod +x /tmp/recovery.sh && sudo /tmp/recovery.sh
```

This troubleshooting guide covers the most common issues encountered with ArcDeploy. For additional help, please refer to the project's GitHub repository or community discussions.