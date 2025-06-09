# Troubleshooting Guide

**Common issues and solutions for ArcDeploy**

This guide covers the most common issues users encounter when deploying ArcBlock Blocklet Server using ArcDeploy on Hetzner Cloud, along with step-by-step solutions.

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

#### 2. Check Hetzner Cloud Firewall
- **Hetzner Cloud Console**: Verify Cloud Firewall allows port 2222
- **Network Settings**: Check firewall rules in your project
- **IP Restrictions**: Ensure your IP address is allowed

#### 3. Verify SSH Key Configuration

```bash
# Check your SSH key format
ssh-keygen -l -f ~/.ssh/your_key.pub

# Try verbose SSH connection
ssh -p 2222 -v arcblock@YOUR_SERVER_IP
```

#### 4. Check cloud-init SSH Configuration
```bash
# On the server (if you have Hetzner console access)
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

#### 4. Check Server Firewall Rules
```bash
# Check UFW status
sudo ufw status verbose

# Check iptables
sudo iptables -L -n

# Temporarily disable firewall for testing (if needed)
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
#