# Quick Start Guide

**Deploy ArcBlock Blocklet Server in 10 minutes**

This guide walks you through the fastest way to deploy ArcBlock Blocklet Server using ArcDeploy's cloud-init configuration on Hetzner Cloud.

## 📋 Prerequisites

- Hetzner Cloud account
- SSH key pair (we'll help you create one if needed)
- 10 minutes of your time

## 🚀 Step-by-Step Deployment

### Step 1: Generate SSH Key (if needed)

If you don't have an SSH key pair, create one:

```bash
# Generate ED25519 key (recommended)
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/arcblock_ed25519

# Or generate RSA key (alternative)
ssh-keygen -t rsa -b 4096 -C "your-email@example.com" -f ~/.ssh/arcblock_rsa

# Display your public key
cat ~/.ssh/arcblock_ed25519.pub
```

Copy the entire output (starts with `ssh-ed25519` or `ssh-rsa`).

### Step 2: Download and Configure

```bash
# Download cloud-init configuration
curl -O https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/cloud-init.yaml

# Edit the configuration
nano cloud-init.yaml
```

Find this line in the file:

```yaml
ssh_authorized_keys:
  - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIReplaceWithYourActualEd25519PublicKey your-email@example.com
```

Replace the placeholder with your actual SSH public key:

```yaml
ssh_authorized_keys:
  - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIYourActualPublicKeyHere your-email@example.com
```

### Step 3: Deploy to Hetzner Cloud

#### 🟢 Hetzner Cloud

1. **Login** to [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. **Create Server**:
   - **Image**: Ubuntu 22.04
   - **Type**: CX31 or higher (4 vCPUs, 8GB RAM)
   - **Location**: Choose nearest to you
3. **Add Cloud Config**:
   - Scroll to "Cloud config" section
   - Paste the entire contents of your `cloud-init.yaml` file
4. **Create & Start**

> **Note**: While ArcDeploy works with any cloud provider that supports cloud-init, we recommend Hetzner Cloud for its simplicity, reliability, and cost-effectiveness. For other providers, simply paste the `cloud-init.yaml` content in your provider's user data or cloud config section during server creation.

### Step 4: Wait for Installation

⏱️ **Installation time**: 5-10 minutes

The cloud-init process will:

1. Update the system
2. Install Node.js and dependencies
3. Configure nginx reverse proxy
4. Set up firewall and security
5. Install and start Blocklet Server
6. Configure SSL certificates

### Step 5: Access Your Server

Once deployment is complete (usually 5-10 minutes), connect to your server:

#### SSH Access

```bash
# Connect via SSH (note the custom port 2222)
ssh -p 2222 arcblock@YOUR_SERVER_IP

# If using custom key file
ssh -p 2222 -i ~/.ssh/arcblock_ed25519 arcblock@YOUR_SERVER_IP
```

#### Web Interface

```bash
# Open in browser
http://YOUR_SERVER_IP:8080

# Admin panel
http://YOUR_SERVER_IP:8080/.well-known/server/admin/
```

## ✅ Verification Checklist

Once connected, verify everything is working:

```bash
# Check cloud-init completed successfully
sudo cloud-init status --long

# Verify Blocklet Server is running
sudo systemctl status blocklet-server

# Check that all ports are listening
sudo netstat -tlnp | grep -E "(2222|8080|8443)"

# Test web interface locally
curl -I http://localhost:8080
```

**Expected results:**

- Cloud-init status: `done`
- Blocklet Server: `active (running)`
- Ports 2222, 8080, 8443 should be listening
- HTTP request should return `200 OK` or similar

## 🎉 Initial Setup

### Access Admin Panel

1. **Open**: `http://YOUR_SERVER_IP:8080/.well-known/server/admin/`
2. **Complete Setup Wizard**:
   - Set admin password
   - Configure domain (optional)
   - Set up SSL certificates (optional)
3. **Install Your First Blocklet**

### Secure Your Installation (Optional)

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Review firewall status
sudo ufw status verbose

# Check fail2ban status
sudo systemctl status fail2ban

# Review system logs
sudo journalctl -u blocklet-server --since "1 hour ago"
```

## 🔧 Common Issues & Solutions

### Issue: Can't SSH to server

**Solution:**

```bash
# Test if port 2222 is reachable
telnet YOUR_SERVER_IP 2222

# Check Hetzner Cloud firewall settings
# Ensure port 2222 is allowed from your IP

# Verify SSH key is correct
ssh-keygen -l -f ~/.ssh/arcblock_ed25519.pub
```

### Issue: Web interface not accessible

**Solution:**

```bash
# Check if blocklet-server is running
ssh -p 2222 arcblock@YOUR_SERVER_IP
sudo systemctl status blocklet-server

# Check if nginx is running
sudo systemctl status nginx

# Verify ports are open
sudo netstat -tlnp | grep -E "(8080|8443)"
```

### Issue: Cloud-init failed

**Solution:**

```bash
# Check cloud-init logs
ssh -p 2222 arcblock@YOUR_SERVER_IP
sudo tail -f /var/log/cloud-init-output.log

# Check for specific errors
sudo journalctl -u cloud-init-local -u cloud-init -u cloud-config -u cloud-final
```

## 📊 Server Requirements

### Minimum Hardware Requirements

- **CPU:** 4 cores / 4 vCPUs
- **RAM:** 8GB
- **Storage:** 80GB SSD
- **Network:** 1Gbps connection

### Recommended Hardware Requirements

- **CPU:** 8 cores / 8 vCPUs
- **RAM:** 16GB
- **Storage:** 160GB SSD
- **Network:** 1Gbps+ connection

### System Requirements

- **Operating System:** Ubuntu 22.04 LTS
- **Architecture:** x86_64 (ARM not currently supported)
- **Cloud-Init:** Required for automated deployment
- **Internet Access:** Required for package installation

## 🚀 Next Steps

1. **Explore Blocklets**: Visit the [Blocklet Store](https://store.blocklet.dev/)
2. **Configure SSL**: Set up Let's Encrypt certificates
3. **Domain Setup**: Point your domain to the server
4. **Backup Strategy**: Set up automated backups
5. **Monitoring**: Configure uptime monitoring

## 🆘 Getting Help

- **Documentation**: [ArcDeploy Documentation](../README.md)
- **Issues**: [GitHub Issues](https://github.com/Pocklabs/ArcDeploy/issues)
- **Community**: [GitHub Discussions](https://github.com/Pocklabs/ArcDeploy/discussions)
- **ArcBlock Support**: [ArcBlock Documentation](https://docs.arcblock.io/)

---

**🎯 Total deployment time: 10 minutes or less!**

**Next**: Visit the [troubleshooting guide](TROUBLESHOOTING.md) for additional help and solutions.