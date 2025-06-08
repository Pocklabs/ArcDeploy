# ArcDeploy Debugging Guide

Complete troubleshooting guide for ArcDeploy's native Blocklet Server deployment issues.

## 🚨 Emergency Quick Start

If your deployment failed, run these commands first:

```bash
# Check cloud-init status
sudo cloud-init status --long

# Check logs for errors
sudo tail -50 /var/log/cloud-init.log | grep -i error

# Check Blocklet Server status
sudo systemctl status blocklet-server

# Check Blocklet CLI installation
which blocklet && blocklet --version

# Test web interface
curl -I http://localhost:8080
```

## 📋 Common Deployment Issues

### 1. SSH Connection Problems

**Symptoms:**
- "Permission denied (publickey)" error
- Connection refused on port 2222
- SSH timeout

**Most Common Cause:** SSH key placeholder not replaced in cloud-init.yaml

**Check SSH Key Configuration:**
```bash
# Verify SSH key was replaced in cloud-init.yaml
grep "ssh-ed25519" cloud-init.yaml
# Should show YOUR actual key, not "IReplaceWithYourActualEd25519PublicKey"
```

**Debugging Steps:**
```bash
# Check if SSH service is running (from console)
sudo systemctl status ssh

# Check SSH configuration
sudo sshd -T | grep -i port
sudo sshd -T | grep -i passwordauth

# Check firewall status
sudo ufw status verbose

# Check user exists
id arcblock

# Check SSH logs
sudo journalctl -u ssh -f
```

**Solutions:**
```bash
# 1. Fix SSH key in cloud-init.yaml and redeploy
sed -i 's/ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIReplaceWithYourActualEd25519PublicKey your-email@example.com/YOUR_ACTUAL_SSH_PUBLIC_KEY/' cloud-init.yaml

# 2. Manual key addition via cloud console
sudo -u arcblock mkdir -p /home/arcblock/.ssh
echo "YOUR_SSH_PUBLIC_KEY" | sudo tee -a /home/arcblock/.ssh/authorized_keys
sudo chown -R arcblock:arcblock /home/arcblock/.ssh
sudo chmod 700 /home/arcblock/.ssh
sudo chmod 600 /home/arcblock/.ssh/authorized_keys

# 3. Connect with correct format
ssh -p 2222 arcblock@YOUR_SERVER_IP
```

### 2. Cloud-Init Never Started

**Symptoms:**
- `cloud-init status` shows "not run"
- No logs in `/var/log/cloud-init.log`
- Services show as inactive

**Debugging Steps:**
```bash
# Check datasource detection
sudo cat /run/cloud-init/ds-identify.log

# Check cloud-init services
sudo systemctl status cloud-init-local.service
sudo systemctl status cloud-init-network.service
sudo systemctl status cloud-config.service
sudo systemctl status cloud-final.service

# Check service order
sudo systemctl list-jobs --after
```

**Solutions:**
- Verify cloud provider supports cloud-init
- Check that user-data was properly attached to instance
- Verify cloud-init is installed: `cloud-init --version`

### 3. Cloud-Init Hung/Never Finished

**Symptoms:**
- `cloud-init status` shows "running" for extended time
- Some services completed, others stuck
- Instance accessible but setup incomplete

**Debugging Steps:**
```bash
# Check for system errors
sudo dmesg -T | grep -i -e warning -e error -e fatal

# Check failed services
sudo systemctl --failed

# Find running cloud-init processes
sudo pstree $(pgrep -f cloud-init)

# Check what's blocking
sudo systemctl list-jobs --after
```

**Solutions:**
- Kill hanging processes if identified
- Check for commands that don't exit (interactive prompts)
- Verify network connectivity for downloads
- Check disk space: `df -h`

### 4. YAML Configuration Errors

**Symptoms:**
- Cloud-init starts but fails early
- Error messages about YAML parsing
- Malformed configuration warnings

**Debugging Steps:**
```bash
# Validate YAML syntax locally
python3 -c "import yaml; yaml.safe_load(open('cloud-init.yaml'))"

# Check cloud-init logs for parsing errors
sudo grep -i -A5 -B5 "yaml\|parse\|syntax" /var/log/cloud-init.log

# Validate cloud-config format
sudo cloud-init schema --config-file /var/lib/cloud/instance/user-data.txt
```

**Solutions:**
- Use proper indentation (spaces, not tabs)
- Escape special characters in strings
- Use `|` for multi-line strings
- Validate YAML before deployment

### 5. Package Installation Failures

**Symptoms:**
- Errors about package not found
- Network timeouts during downloads
- Repository access denied

**Debugging Steps:**
```bash
# Check package manager logs
sudo tail -50 /var/log/apt/history.log
sudo tail -50 /var/log/apt/term.log

# Test network connectivity
ping -c 3 8.8.8.8
curl -I https://deb.nodesource.com

# Check repository configuration
sudo apt update
```

**Solutions:**
- Verify internet connectivity
- Check if repositories are accessible
- Try manual package installation
- Use alternative package sources

### 6. Blocklet Server Won't Start

**Symptoms:**
- `systemctl status blocklet-server` shows failed
- Service exits immediately
- Port 8080 not accessible

**Debugging Steps:**
```bash
# Check service status and logs
sudo systemctl status blocklet-server -l
sudo journalctl -u blocklet-server -f

# Check Blocklet CLI installation
which blocklet
blocklet --version

# Check service configuration
sudo cat /etc/systemd/system/blocklet-server.service

# Check Blocklet Server process
sudo ps aux | grep blocklet

# Check port binding
sudo netstat -tlnp | grep 8080
sudo ss -tlnp | grep 8080

# Test local endpoint
curl -I http://localhost:8080
```

**Solutions:**
```bash
# 1. Verify CLI is installed correctly
npm list -g @blocklet/cli

# 2. Check service file ExecStart path
sudo grep ExecStart /etc/systemd/system/blocklet-server.service
# Should show: ExecStart=/usr/local/bin/blocklet server start

# 3. Restart service with daemon reload
sudo systemctl daemon-reload
sudo systemctl restart blocklet-server

# 4. Check Blocklet Server initialization
sudo -u arcblock ls -la /opt/blocklet-server/
```

### 7. Node.js/NPM Issues

**Symptoms:**
- Blocklet CLI not found
- npm permission errors
- Node.js version conflicts

**Debugging Steps:**
```bash
# Check Node.js installation
node --version
npm --version

# Check npm global packages
npm list -g --depth=0

# Check npm configuration
npm config list

# Check PATH includes npm globals
echo $PATH | grep npm
```

**Solutions:**
```bash
# 1. Reinstall Node.js from NodeSource
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# 2. Fix npm permissions
sudo chown -R $(whoami) ~/.npm

# 3. Reinstall Blocklet CLI
npm uninstall -g @blocklet/cli
npm install -g @blocklet/cli

# 4. Verify installation
which blocklet && blocklet --version
```

## 📊 Log Analysis

### Primary Log Locations

| Log File | Purpose | Key Information |
|----------|---------|-----------------|
| `/var/log/cloud-init.log` | Main cloud-init log | Execution flow, errors, warnings |
| `/var/log/cloud-init-output.log` | Command output | stdout/stderr from runcmd and bootcmd |
| `/run/cloud-init/ds-identify.log` | Datasource detection | Platform identification |
| `/var/log/syslog` | System log | Service start/stop, system events |

### Log Analysis Commands

```bash
# Find errors in cloud-init logs
sudo grep -i error /var/log/cloud-init.log

# Find warnings
sudo grep -i warning /var/log/cloud-init.log

# Check last 100 lines
sudo tail -100 /var/log/cloud-init.log

# Monitor logs in real-time
sudo tail -f /var/log/cloud-init.log

# Search for specific modules
sudo grep -i "cc_runcmd\|cc_users\|cc_ssh" /var/log/cloud-init.log
```

### Error Patterns to Look For

```bash
# YAML parsing errors
sudo grep -i "yaml\|parse\|indent" /var/log/cloud-init.log

# Network/download errors
sudo grep -i "timeout\|connection\|download\|curl\|wget" /var/log/cloud-init.log

# Permission errors
sudo grep -i "permission\|denied\|sudo" /var/log/cloud-init.log

# Service failures
sudo grep -i "failed\|systemctl\|service" /var/log/cloud-init.log
```

## 🔧 Manual Recovery Commands

### Reset and Retry Cloud-Init

```bash
# Clean cloud-init state (WARNING: Will re-run cloud-init)
sudo cloud-init clean --logs
sudo cloud-init clean --seed

# Re-run specific stages
sudo cloud-init init --local
sudo cloud-init init
sudo cloud-init modules --mode=config
sudo cloud-init modules --mode=final
```

### Manual Service Management

```bash
# Restart Blocklet Server
sudo systemctl restart blocklet-server

# Reset Blocklet Server configuration
sudo -u arcblock blocklet server config reset

# Restart SSH with new configuration
sudo systemctl restart ssh

# Reset firewall
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 8443/tcp
sudo ufw --force enable
```

### Manual Service Management

**If the native service isn't starting properly:**

```bash
# Stop Blocklet Server service
sudo systemctl stop blocklet-server

# Reset service configuration
sudo systemctl daemon-reload

# Restart service
sudo systemctl start blocklet-server

# Check service status
sudo systemctl status blocklet-server
```

## ✅ Verification Commands

### Post-Deployment Checks

```bash
# Verify cloud-init completed successfully
sudo cloud-init status --long

# Check all services are active
sudo systemctl is-active cloud-init-local cloud-init-network cloud-config cloud-final

# Verify Blocklet Server is running
sudo systemctl is-active blocklet-server
sudo -u arcblock blocklet server status

# Test HTTP endpoint
curl -f http://localhost:8080

# Check SSH access (from another machine)
ssh -p 2222 arcblock@YOUR_SERVER_IP

# Verify firewall
sudo ufw status verbose

# Check system resources
df -h
free -h
sudo systemctl --failed
```

### Health Check Script

```bash
#!/bin/bash
# Quick health check for ArcDeploy installation

echo "=== ArcDeploy Health Check ==="

# Cloud-init status
echo "Cloud-init status:"
sudo cloud-init status --long

# Services status
echo -e "\nServices status:"
for service in cloud-init-local cloud-init-network cloud-config cloud-final blocklet-server; do
    status=$(sudo systemctl is-active $service)
    echo "  $service: $status"
done

# Service status
echo -e "\nService status:"
sudo systemctl status blocklet-server --no-pager -l

# Network check
echo -e "\nNetwork check:"
if curl -sf --max-time 5 http://localhost:8080 >/dev/null; then
    echo "  Blocklet Server: ✅ Responding"
else
    echo "  Blocklet Server: ❌ Not responding"
fi

# Disk space
echo -e "\nDisk usage:"
df -h / | tail -1

echo -e "\n=== Health Check Complete ==="
```

## 📞 Getting Help

### Information to Gather Before Reporting Issues

1. **System Information:**
   ```bash
   lsb_release -a
   cloud-init --version
   sudo systemctl --version
   ```

2. **Cloud-init Status:**
   ```bash
   sudo cloud-init status --long
   ```

3. **Relevant Logs:**
   ```bash
   sudo cloud-init collect-logs
   ```

4. **Configuration Used:**
   - Which YAML file (minimal, standard, full-featured, etc.)
   - Any modifications made
   - Cloud provider and instance type

### Support Channels

- **GitHub Issues**: [ArcDeploy Issues](https://github.com/Pocklabs/ArcDeploy/issues)
- **Documentation**: [Project Wiki](https://github.com/Pocklabs/ArcDeploy/wiki)
- **Discussions**: [GitHub Discussions](https://github.com/Pocklabs/ArcDeploy/discussions)

### Issue Template

When reporting issues, please include:

```
**Environment:**
- Cloud Provider: 
- Instance Type: 
- OS Version: 
- ArcDeploy Configuration: 

**Problem Description:**
[Describe what went wrong]

**Steps to Reproduce:**
1. 
2. 
3. 

**Expected Behavior:**
[What should have happened]

**Logs:**
[Attach relevant log snippets]

**Additional Context:**
[Any other relevant information]
```

---

**Remember**: Most cloud-init issues are caused by YAML syntax errors, network connectivity problems, or resource constraints. Always start with the basics!