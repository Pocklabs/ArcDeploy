# Hetzner Cloud Deployment Guide

**Complete step-by-step guide for deploying ArcBlock Blocklet Server on Hetzner Cloud using ArcDeploy**

---

## 📋 Prerequisites

### Account Requirements
- **Hetzner Cloud Account**: [Sign up here](https://accounts.hetzner.com/signUp)
- **SSH Key Pair**: Ed25519 or RSA key for secure access
- **Payment Method**: Valid payment method for server costs

### Local Requirements
- **SSH Client**: Terminal with SSH support
- **Text Editor**: For editing configuration files
- **Web Browser**: For Hetzner Cloud Console access

---

## 💰 Cost Estimation

### Recommended Server: **CX31**
- **Specifications**: 2 vCPUs, 8GB RAM, 80GB SSD
- **Monthly Cost**: ~€4.15/month (as of 2025)
- **Hourly Cost**: ~€0.006/hour
- **Network**: 20 TB traffic included

### Alternative Options
- **CX21** (Minimum): 2 vCPUs, 4GB RAM, 40GB SSD - ~€3.29/month
- **CX41** (Performance): 4 vCPUs, 16GB RAM, 160GB SSD - ~€8.21/month

---

## 🚀 Step-by-Step Deployment

### Step 1: Prepare SSH Key Pair

#### Generate New SSH Key (if needed)
```bash
# Generate Ed25519 key (recommended)
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/hetzner_arcblock

# Or generate RSA key (alternative)
ssh-keygen -t rsa -b 4096 -C "your-email@example.com" -f ~/.ssh/hetzner_arcblock
```

#### Get Your Public Key
```bash
# Display your public key
cat ~/.ssh/hetzner_arcblock.pub

# Example output:
# ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGYourKeyContentHere your-email@example.com
```

**💡 Important**: Copy this entire public key - you'll need it in Step 3.

---

### Step 2: Download and Configure ArcDeploy

#### Clone Repository
```bash
# Clone ArcDeploy repository
git clone https://github.com/Pocklabs/ArcDeploy.git
cd ArcDeploy
```

#### Configure cloud-init.yaml
1. **Open** `cloud-init.yaml` in your text editor
2. **Find** the SSH key placeholder line:
   ```yaml
   ssh_authorized_keys:
     - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIReplaceWithYourActualEd25519PublicKey your-email@example.com
   ```
3. **Replace** with your actual public key:
   ```yaml
   ssh_authorized_keys:
     - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGYourKeyContentHere your-email@example.com
   ```
4. **Save** the file

---

### Step 3: Create Server on Hetzner Cloud

#### Access Hetzner Cloud Console
1. **Login** to [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. **Select** your project or create a new one
3. **Click** "Add Server"

#### Configure Server Settings

##### Basic Configuration
- **Location**: Choose closest to your users (e.g., Nuremberg, Helsinki, Ashburn)
- **Image**: Ubuntu 22.04 LTS (x86_64)
- **Type**: Standard (CX31 recommended)

##### Network Configuration
- **IPv4**: ✅ Enabled (required)
- **IPv6**: ✅ Enabled (optional but recommended)

##### SSH Keys
- **Click** "Add SSH Key"
- **Paste** your public key from Step 1
- **Name** it (e.g., "ArcBlock Deploy Key")

##### Cloud Config
- **Click** "Cloud config" section
- **Paste** the entire content of your configured `cloud-init.yaml` file
- **Verify** the SSH key in the pasted content matches your key

##### Server Details
- **Name**: `arcblock-server` (or your preferred name)
- **Labels**: Add labels for organization (optional)
  - `purpose: blocklet-server`
  - `environment: production`

#### Finalize Creation
1. **Review** all settings
2. **Click** "Create & Buy Now"
3. **Note** the server IP address once created

---

### Step 4: Monitor Deployment Progress

#### Check Server Status
- **Status**: Should show "Running" within 1-2 minutes
- **Console**: Use web console to monitor boot process if needed

#### Monitor Cloud-Init Progress
```bash
# Wait 2-3 minutes, then connect via SSH
ssh -p 2222 arcblock@YOUR_SERVER_IP

# Check cloud-init status
sudo cloud-init status --long

# Expected output when complete:
# status: done
```

#### Watch Installation Logs (Optional)
```bash
# Monitor real-time installation progress
sudo tail -f /var/log/cloud-init-output.log
```

**⏱️ Estimated Time**: 8-12 minutes for complete installation

---

### Step 5: Verify Deployment

#### SSH Access Test
```bash
# Test SSH connection (port 2222)
ssh -p 2222 arcblock@YOUR_SERVER_IP

# Should connect without password prompt
```

#### Service Status Check
```bash
# Check Blocklet Server status
sudo systemctl status blocklet-server

# Check nginx proxy status
sudo systemctl status nginx

# Check firewall status
sudo ufw status
```

#### Web Interface Access
1. **Open browser** to: `http://YOUR_SERVER_IP:8080`
2. **Expected**: Blocklet Server welcome page
3. **Admin Panel**: `http://YOUR_SERVER_IP:8080/.well-known/server/admin/`

---

### Step 6: Initial Setup and Configuration

#### Complete Setup Wizard
1. **Access**: `http://YOUR_SERVER_IP:8080/.well-known/server/admin/`
2. **Follow** the on-screen setup wizard
3. **Create** admin account
4. **Configure** basic settings

#### Optional: Configure Domain and SSL
```bash
# If you have a domain name, configure it
sudo blocklet server config set server-name your-domain.com

# Install SSL certificate (Let's Encrypt)
sudo blocklet server ssl enable --domain your-domain.com
```

---

## 🔧 Post-Deployment Configuration

### Firewall Configuration

#### View Current Rules
```bash
sudo ufw status numbered
```

#### Open Additional Ports (if needed)
```bash
# Example: Allow specific application port
sudo ufw allow 3000/tcp comment 'Custom App'

# Always reload after changes
sudo ufw reload
```

### Security Hardening

#### Update System
```bash
# Update all packages
sudo apt update && sudo apt upgrade -y

# Enable automatic security updates
sudo dpkg-reconfigure -plow unattended-upgrades
```

#### Monitor Fail2ban
```bash
# Check fail2ban status
sudo fail2ban-client status

# View SSH jail status
sudo fail2ban-client status sshd
```

### Backup Configuration

#### Backup Blocklet Server Data
```bash
# Create backup directory
sudo mkdir -p /backups/blocklet-server

# Backup configuration and data
sudo tar -czf /backups/blocklet-server/backup-$(date +%Y%m%d).tar.gz \
  /opt/blocklet-server/data \
  /opt/blocklet-server/config
```

---

## 📊 Performance Monitoring

### System Resources
```bash
# Check system load
htop

# Check disk usage
df -h

# Check memory usage
free -h

# Check network connections
netstat -tulpn | grep -E ':(8080|8443|2222)'
```

### Blocklet Server Health
```bash
# Run health check
sudo -u arcblock /opt/blocklet-server/healthcheck.sh

# Check service logs
sudo journalctl -u blocklet-server -f
```

---

## 🚨 Troubleshooting

### Common Issues

#### Can't SSH to Server
```bash
# Test if port 2222 is open
telnet YOUR_SERVER_IP 2222

# Check if SSH key is correct
ssh -p 2222 -v arcblock@YOUR_SERVER_IP
```

#### Blocklet Server Not Responding
```bash
# Check service status
sudo systemctl status blocklet-server

# Restart service if needed
sudo systemctl restart blocklet-server

# Check logs for errors
sudo journalctl -u blocklet-server --no-pager -l
```

#### Cloud-Init Failed
```bash
# Check cloud-init logs
sudo cloud-init status --long
sudo tail -f /var/log/cloud-init-output.log

# Re-run cloud-init (if safe)
sudo cloud-init clean --logs
sudo cloud-init init
```

### Getting Help

#### Debug Information Collection
```bash
# Check ArcBlock Node status
sudo -u arcblock /opt/abtnode/bin/abtnode status
sudo -u arcblock /opt/abtnode/bin/abtnode logs

# Run validation script
./scripts/validate-setup.sh
```

#### Support Resources
- **GitHub Issues**: [ArcDeploy Issues](https://github.com/Pocklabs/ArcDeploy/issues)
- **Troubleshooting Guide**: [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Hetzner Support**: [Hetzner Cloud Docs](https://docs.hetzner.com/cloud/)

---

## 💡 Tips and Best Practices

### Cost Optimization
- **Server Sizing**: Start with CX21, upgrade if needed
- **Snapshots**: Create snapshots before major changes
- **Monitoring**: Use Hetzner's free monitoring features

### Security Best Practices
- **Regular Updates**: Keep system and Blocklet Server updated
- **Key Management**: Rotate SSH keys periodically
- **Access Control**: Use strong passwords for admin accounts
- **Monitoring**: Review fail2ban logs regularly

### Performance Optimization
- **Location**: Choose server location close to your users
- **Resources**: Monitor and upgrade server size as needed
- **Caching**: Configure appropriate caching settings

---

## 🔄 Maintenance Tasks

### Weekly Tasks
- [ ] Check system resource usage
- [ ] Review security logs (fail2ban, auth.log)
- [ ] Verify backup integrity
- [ ] Check for system updates

### Monthly Tasks
- [ ] Update system packages
- [ ] Review and rotate logs
- [ ] Test disaster recovery procedures
- [ ] Optimize Blocklet Server configuration

### Quarterly Tasks
- [ ] Review and update security settings
- [ ] Performance optimization review
- [ ] Disaster recovery testing
- [ ] Cost analysis and optimization

---

## 📞 Emergency Procedures

### Server Unresponsive
1. **Check** Hetzner Cloud Console for server status
2. **Reboot** server through console if needed
3. **Access** via Hetzner rescue system if SSH fails
4. **Restore** from backup if corruption detected

### Data Recovery
1. **Stop** Blocklet Server service
2. **Mount** backup storage
3. **Restore** data from latest backup
4. **Restart** services and verify functionality

---

**Deploy with confidence. Scale with ease.** 🚀

*This guide is specifically tailored for Hetzner Cloud deployment. For other cloud providers, refer to their respective deployment guides in the docs/ directory.*