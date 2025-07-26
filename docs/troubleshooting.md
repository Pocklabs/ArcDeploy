# Troubleshooting Guide

**Common issues and solutions for ArcDeploy**

This guide covers the most common issues users encounter when deploying ArcBlock Blocklet Server using ArcDeploy, along with step-by-step solutions.

## 🚨 Quick Diagnostics

If you're experiencing issues, run these commands first to gather information:

```bash
# Check cloud-init status
sudo cloud-init status --long

# Check Blocklet Server service
sudo systemctl status blocklet-server

# Check system logs
sudo journalctl -u blocklet-server --since "1 hour ago"

# Test network connectivity
curl -I http://localhost:8080
```

## 🔑 SSH Connection Issues

### Problem: Can't connect via SSH

**Symptoms:**
- `Connection refused` error
- `Connection timed out` error
- `Permission denied (publickey)` error

**Solutions:**

#### 1. Verify SSH Port
```bash
# Test if port 2222 is reachable
telnet YOUR_SERVER_IP 2222

# If that fails, check if default SSH port is open
telnet YOUR_SERVER_IP 22
```

#### 2. Check Cloud Provider Firewall
- **Hetzner**: Verify Cloud Firewall allows port 2222
- **AWS**: Check Security Group rules
- **GCP**: Verify VPC firewall rules
- **DigitalOcean**: Check Cloud Firewall settings
- **Azure**: Verify Network Security Group

#### 3. Verify SSH Key Configuration
```bash
# Check your SSH key format
ssh-keygen -l -f ~/.ssh/your_key.pub

# Try verbose SSH connection
ssh -p 2222 -v arcblock@YOUR_SERVER_IP
```

#### 4. Check cloud-init SSH Configuration
```bash
# On the server (if you have console access)
sudo cat /home/arcblock/.ssh/authorized_keys
sudo tail -f /var/log/auth.log
```

### Problem: SSH key authentication fails

**Solutions:**

#### 1. Verify Key Format in cloud-init.yaml
```yaml
# Correct format:
ssh_authorized_keys:
  - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIYourActualKeyHere user@hostname

# NOT this:
ssh_authorized_keys:
  - "ssh-ed25519 AAAAC3..."  # Remove quotes
  - YOUR_SSH_KEY_HERE        # Must be actual key
```

#### 2. Check Key Permissions
```bash
# On your local machine
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# Check key ownership
ls -la ~/.ssh/
```

## 🌐 Web Interface Issues

### Problem: Can't access web interface (port 8080/8443)

**Symptoms:**
- Browser shows "This site can't be reached"
- Connection timeout errors
- ERR_CONNECTION_REFUSED

**Solutions:**

#### 1. Verify Services are Running
```bash
# Check Blocklet Server
sudo systemctl status blocklet-server

# Check nginx
sudo systemctl status nginx

# Check processes
ps aux | grep -E "(blocklet|nginx)"
```

#### 2. Check Port Bindings
```bash
# Verify ports are listening
sudo netstat -tlnp | grep -E "(8080|8443)"

# Expected output:
# tcp 0.0.0.0:8080 0.0.0.0:* LISTEN 1234/nginx
# tcp 0.0.0.0:8443 0.0.0.0:* LISTEN 1234/nginx
```

#### 3. Test Local Connectivity
```bash
# Test from server itself
curl -I http://localhost:8080
curl -I http://127.0.0.1:8080

# Test blocklet server directly
curl -I http://localhost:3030
```

#### 4. Check Firewall Rules
```bash
# Check UFW status
sudo ufw status verbose

# Check iptables
sudo iptables -L -n

# Temporarily disable firewall for testing
sudo ufw disable
# Test access, then re-enable: sudo ufw enable
```

#### 5. Check nginx Configuration
```bash
# Test nginx configuration
sudo nginx -t

# Check nginx error logs
sudo tail -f /var/log/nginx/error.log

# Restart nginx
sudo systemctl restart nginx
```

## ☁️ Cloud-Init Issues

### Problem: Cloud-init failed or degraded

**Symptoms:**
- `sudo cloud-init status` shows "error" or "degraded"
- Services not installed or configured properly

**Solutions:**

#### 1. Check Cloud-Init Logs
```bash
# Check main cloud-init log
sudo tail -f /var/log/cloud-init-output.log

# Check detailed logs
sudo tail -f /var/log/cloud-init.log

# Check for specific errors
sudo journalctl -u cloud-init-local -u cloud-init -u cloud-config -u cloud-final
```

#### 2. Validate YAML Syntax
```bash
# On your local machine, validate YAML
python3 -c "import yaml; yaml.safe_load(open('cloud-init.yaml'))"

# Or use online YAML validator
# Copy cloud-init.yaml content to: https://yaml-online-parser.appspot.com/
```

#### 3. Check Cloud-Init Schema
```bash
# Validate cloud-init schema (on server)
sudo cloud-init schema --config-file /var/lib/cloud/instance/cloud-config.txt
```

### Problem: Cloud-init user data too large

**Symptoms:**
- Cloud provider rejects the configuration
- "User data too large" error

**Solutions:**

#### 1. Minimize Configuration
- Remove unnecessary comments
- Use shorter variable names
- Consider using external scripts

## 🔧 Service Issues

### Problem: Blocklet Server won't start

**Solutions:**

#### 1. Check Service Status
```bash
# Detailed status
sudo systemctl status blocklet-server -l

# Check if service exists
sudo systemctl list-unit-files | grep blocklet

# Check service definition
sudo cat /etc/systemd/system/blocklet-server.service
```

#### 2. Check User and Permissions
```bash
# Verify arcblock user exists
id arcblock

# Check home directory permissions
sudo ls -la /home/arcblock/

# Check service file ownership
sudo ls -la /etc/systemd/system/blocklet-server.service
```

#### 3. Manual Service Start
```bash
# Try starting manually
sudo -u arcblock /usr/bin/blocklet server start

# Check for error messages
sudo -u arcblock /usr/bin/blocklet server status
```

#### 4. Reinstall Blocklet Server
```bash
# Uninstall
sudo -u arcblock npm uninstall -g @blocklet/cli

# Reinstall
sudo -u arcblock npm install -g @blocklet/cli

# Reconfigure
sudo -u arcblock blocklet server init --mode production
```

### Problem: Services fail after reboot

**Solutions:**

#### 1. Check Service Enablement
```bash
# Check if services are enabled
sudo systemctl is-enabled blocklet-server
sudo systemctl is-enabled nginx

# Enable if needed
sudo systemctl enable blocklet-server
sudo systemctl enable nginx
```

## 🌊 Network and Connectivity Issues

### Problem: Slow performance or timeouts

**Solutions:**

#### 1. Check Network Connectivity
```bash
# Test DNS resolution
nslookup google.com

# Test internet speed
curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -

# Check routing
traceroute 8.8.8.8
```

#### 2. Check Resource Usage
```bash
# Check CPU usage
top
htop

# Check memory usage
free -h

# Check disk I/O
iostat -x 1

# Check network usage
iftop
nethogs
```

### Problem: External access blocked

**Solutions:**

#### 1. Check Cloud Provider Security
- Verify security groups/firewall rules
- Check for IP allowlisting restrictions
- Verify network ACLs

#### 2. Check Local Firewall
```bash
# Check UFW rules
sudo ufw status numbered

# Check for blocking rules
sudo iptables -L -n --line-numbers
```

## 🔐 SSL/TLS Certificate Issues

### Problem: HTTPS not working

**Solutions:**

#### 1. Check Certificate Status
```bash
# Check if certificates exist
sudo ls -la /etc/letsencrypt/live/*/

# Check certificate validity
sudo openssl x509 -in /etc/letsencrypt/live/yourdomain.com/cert.pem -text -noout
```

#### 2. Check nginx SSL Configuration
```bash
# Check nginx SSL config
sudo nginx -T | grep ssl

# Test nginx configuration
sudo nginx -t
```

## 🗄️ Database and Storage Issues

### Problem: Database connection errors

**Solutions:**

#### 1. Check Disk Space
```bash
# Check available space
df -h /home/arcblock/

# Check inode usage
df -i
```

#### 2. Check Database Files
```bash
# Check blocklet server data directory
sudo -u arcblock ls -la /home/arcblock/.local/share/blocklet-server/

# Check for database locks
sudo -u arcblock find /home/arcblock/.local/share/blocklet-server/ -name "*.lock"
```

## 📋 Health Check Script

Create this script to quickly diagnose issues:

```bash
#!/bin/bash
# Save as check-health.sh

echo "=== ArcDeploy Health Check ==="
echo

echo "1. Cloud-init Status:"
sudo cloud-init status --long
echo

echo "2. Service Status:"
sudo systemctl status blocklet-server --no-pager -l
echo

echo "3. Port Status:"
sudo netstat -tlnp | grep -E "(2222|8080|8443)"
echo

echo "4. Disk Usage:"
df -h | grep -E "(/$|/home)"
echo

echo "5. Memory Usage:"
free -h
echo

echo "6. Web Interface Test:"
curl -I http://localhost:8080 2>/dev/null | head -1
echo

echo "7. Recent Errors:"
sudo journalctl -u blocklet-server --since "1 hour ago" | grep -i error | tail -5
echo

echo "=== Health Check Complete ==="
```

## 🆘 Getting Help

If you can't resolve the issue using this guide:

### 1. Gather Information
```bash
# Run health check
bash check-health.sh > health-report.txt

# Collect logs
sudo journalctl -u blocklet-server --since "1 hour ago" > blocklet-logs.txt
sudo tail -100 /var/log/cloud-init-output.log > cloud-init-logs.txt
```

### 2. Create Issue Report
Include the following information when asking for help:

- **Cloud Provider**: (Hetzner, AWS, GCP, etc.)
- **Server Specs**: (CPU, RAM, Storage)
- **Operating System**: `lsb_release -a`
- **Error Messages**: Copy exact error messages
- **Steps Taken**: What you've already tried
- **Log Files**: Relevant log excerpts

### 3. Support Channels
- **GitHub Issues**: [ArcDeploy Issues](https://github.com/Pocklabs/ArcDeploy/issues)
- **GitHub Discussions**: [Community Help](https://github.com/Pocklabs/ArcDeploy/discussions)
- **Documentation**: [Project Documentation](../README.md)

## 🔄 Recovery Procedures

### Complete System Recovery
If all else fails, these steps can help recover your deployment:

#### 1. Data Backup
```bash
# Backup blocklet data
sudo -u arcblock tar -czf blocklet-backup-$(date +%Y%m%d).tar.gz /home/arcblock/.local/share/blocklet-server/

# Download backup to local machine
scp -P 2222 arcblock@YOUR_SERVER_IP:blocklet-backup-*.tar.gz .
```

#### 2. Fresh Deployment
```bash
# Create new server with same cloud-init.yaml
# Wait for installation to complete
# Restore data if needed
```

---

**Remember**: Most issues can be resolved by checking logs, verifying configuration, and ensuring proper network connectivity. When in doubt, start with the basics! 🔧