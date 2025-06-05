# ArcDeploy Quick Start Guide

Get your Arcblock Blocklet Server running on Hetzner Cloud in under 10 minutes.

## 🚀 Prerequisites

- Hetzner Cloud account
- SSH key pair (ED25519 recommended)
- Basic terminal knowledge

## 📋 Step 1: Prepare SSH Key

```bash
# Generate new SSH key (if needed)
ssh-keygen -t ed25519 -C "your-email@example.com"

# Display your public key
cat ~/.ssh/id_ed25519.pub
```

Copy the entire output starting with `ssh-ed25519 AAAAC3...`

## 📋 Step 2: Choose Configuration

### Option A: Minimal (Recommended - 657 bytes)
- Uses external script for full functionality
- Well under Hetzner's 32 KiB limit
- Easy to update and maintain

### Option B: Standard (4.7 KB)
- Self-contained configuration
- No external dependencies
- All essential features included

### Option C: Full-Featured (18.6 KB)
- Maximum features and monitoring
- Complete configuration in one file
- May approach size limits

## 📋 Step 3: Configure Cloud-Init

```bash
# 1. Download your chosen configuration
curl -O https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/cloud-init/minimal.yaml

# 2. Replace SSH key placeholder
sed -i 's/ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIReplaceWithYourActualEd25519PublicKey your-email@example.com/YOUR_ACTUAL_SSH_KEY_HERE/' minimal.yaml
```

## 📋 Step 4: Deploy to Hetzner

### Via Console (Easiest)
1. Login to Hetzner Cloud Console
2. Create new server → CX31 or higher
3. Select Ubuntu 22.04 LTS
4. Paste your modified cloud-init in "Cloud config" field
5. Create server

### Via API (Advanced)
```bash
export HETZNER_API_TOKEN="your-api-token"

curl -X POST \
  -H "Authorization: Bearer $HETZNER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"image\": \"ubuntu-22.04\",
    \"location\": \"nbg1\",
    \"name\": \"blocklet-server\",
    \"server_type\": \"cx31\",
    \"user_data\": \"$(cat minimal.yaml | jq -sRr @json)\"
  }" \
  https://api.hetzner.cloud/v1/servers
```

## 📋 Step 5: Configure Firewall

```bash
# Download firewall script
curl -O https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/scripts/hetzner-firewall-setup.sh
chmod +x hetzner-firewall-setup.sh

# Apply firewall rules
export HETZNER_API_TOKEN="your-api-token"
./hetzner-firewall-setup.sh blocklet-server
```

## 📋 Step 6: Access Your Server

Wait 5-10 minutes for setup to complete, then:

```bash
# SSH access
ssh -p 2222 arcblock@YOUR_SERVER_IP

# Web interface
open http://YOUR_SERVER_IP:8089
```

## 📋 Step 7: Validate Installation

```bash
# Download validation script
curl -O https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/scripts/validate-setup.sh
chmod +x validate-setup.sh

# Run validation
./validate-setup.sh
```

## ✅ Success Indicators

You should see:
- ✅ SSH access on port 2222
- ✅ Blocklet Server web interface on port 8089
- ✅ All validation checks passing
- ✅ Container running: `sudo -u arcblock podman ps`

## 🔧 Quick Commands

### Check Status
```bash
# Service status
sudo systemctl status blocklet-server

# Container status
sudo -u arcblock podman ps

# View logs
sudo journalctl -u blocklet-server -f
```

### Manage Service
```bash
# Restart service
sudo systemctl restart blocklet-server

# View container logs
sudo -u arcblock podman logs blocklet-server

# Access container shell
sudo -u arcblock podman exec -it blocklet-server /bin/bash
```

### Health & Monitoring
```bash
# Manual health check
sudo -u arcblock /home/arcblock/blocklet-server/healthcheck.sh

# View health logs
cat /home/arcblock/blocklet-server/logs/health.log

# Check backups
ls -la /home/arcblock/backups/
```

## 🚨 Troubleshooting

### Can't SSH
```bash
# Check if port 2222 is open
telnet YOUR_SERVER_IP 2222

# Check cloud-init status
sudo cloud-init status
sudo cat /var/log/cloud-init-output.log
```

### Service Not Running
```bash
# Check service logs
sudo journalctl -u blocklet-server --no-pager

# Restart service
sudo systemctl restart blocklet-server

# Check container status
sudo -u arcblock podman ps -a
```

### Web Interface Not Accessible
```bash
# Check if port is listening
sudo netstat -tlnp | grep :8089

# Test local connectivity
curl -I http://localhost:8089

# Check firewall
sudo ufw status | grep 8089
```

## 📚 Next Steps

1. **Complete Setup**: Access web interface and follow initial setup wizard
2. **Install Blocklets**: Browse and install your first blocklet
3. **Configure Domain**: Point your domain to the server IP
4. **Setup SSL**: Configure HTTPS with Let's Encrypt
5. **Monitor**: Set up additional monitoring and alerting

## 🆘 Need Help?

- **Documentation**: [Full README](README.md)
- **Firewall Guide**: [docs/FIREWALL_PORTS_GUIDE.md](docs/FIREWALL_PORTS_GUIDE.md)
- **Issues**: [GitHub Issues](https://github.com/Pocklabs/ArcDeploy/issues)

---

**Deployment Time**: ~5-10 minutes | **Total Setup**: ~15 minutes