# 🚀 ArcDeploy Test Server Deployment

Automated deployment scripts for testing ArcDeploy cloud-init configurations on Hetzner Cloud.

## 📋 Overview

This deployment system provides three scripts to easily create, manage, and test ArcDeploy servers:

- **`check-setup.sh`** - Validates your local setup and configuration
- **`quick-deploy.sh`** - Simple one-command deployment with sensible defaults
- **`deploy-test-server.sh`** - Full-featured deployment with all options

## 🚀 Quick Start

### 1. Prerequisites

```bash
# Install dependencies (Ubuntu/Debian)
sudo apt update && sudo apt install curl jq

# Install dependencies (macOS)
brew install curl jq

# Get your Hetzner Cloud API token
# 1. Go to https://console.hetzner.cloud/
# 2. Select your project
# 3. Go to Security → API Tokens
# 4. Generate new token with Read & Write permissions
```

### 2. Configure SSH Key

```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t ed25519 -C "your-email@example.com"

# Get your public key
cat ~/.ssh/id_ed25519.pub

# Edit cloud-init.yaml and replace the SSH key placeholder
nano cloud-init.yaml
# Replace: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIReplaceWithYourActualEd25519PublicKey
# With your actual public key from the command above
```

### 3. Set API Token

```bash
export HETZNER_TOKEN="your-hetzner-cloud-api-token-here"
```

### 4. Validate Setup

```bash
./scripts/check-setup.sh
```

### 5. Deploy Server

```bash
# Quick deploy with optimal defaults
./scripts/quick-deploy.sh

# Or specify size/location
./scripts/quick-deploy.sh small    # Minimal server (cx11)
./scripts/quick-deploy.sh large    # High-performance (cx41)
./scripts/quick-deploy.sh us       # Deploy to US location
```

## 📖 Detailed Usage

### check-setup.sh

Validates your environment before deployment:

```bash
./scripts/check-setup.sh
```

**Checks performed:**
- ✅ Required dependencies (curl, jq, ssh)
- ✅ Hetzner Cloud API token validity
- ✅ Cloud-init configuration
- ✅ SSH key setup
- ✅ Network connectivity
- ✅ Script permissions

### quick-deploy.sh

Simple wrapper for common deployment scenarios:

```bash
# Deploy with defaults (cx31, Germany)
./scripts/quick-deploy.sh

# Deploy different server sizes
./scripts/quick-deploy.sh small     # cx11 - €4.15/month (minimal)
./scripts/quick-deploy.sh deploy    # cx31 - €13.10/month (recommended)
./scripts/quick-deploy.sh large     # cx41 - €26.20/month (high performance)

# Deploy to different regions
./scripts/quick-deploy.sh us        # Deploy to US (Ashburn, VA)

# Server management
./scripts/quick-deploy.sh list               # List all test servers
./scripts/quick-deploy.sh delete <server>    # Delete a test server
```

### deploy-test-server.sh

Full-featured deployment script with all options:

```bash
# Basic usage
./scripts/deploy-test-server.sh [server_name] [server_type] [location]

# Examples
./scripts/deploy-test-server.sh my-test-server cx31 fsn1
./scripts/deploy-test-server.sh prod-test cx41 nbg1
./scripts/deploy-test-server.sh us-test cx21 ash

# Server management
./scripts/deploy-test-server.sh --delete my-test-server
./scripts/deploy-test-server.sh --help
```

## 🖥️ Server Types & Pricing

| Type | vCPU | RAM | Disk | Monthly Cost* | Use Case |
|------|------|-----|------|---------------|----------|
| cx11 | 1    | 4GB | 40GB | €4.15         | Minimal testing |
| cx21 | 2    | 8GB | 80GB | €8.30         | Light testing |
| cx31 | 2    | 8GB | 80GB | €13.10        | **Recommended** |
| cx41 | 4    | 16GB| 160GB| €26.20        | Heavy testing |
| cx51 | 8    | 32GB| 320GB| €52.40        | Performance testing |

*Prices as of 2024, subject to change

## 🌍 Available Locations

| Code | Location | Description |
|------|----------|-------------|
| fsn1 | Germany | Falkenstein (Default) |
| nbg1 | Germany | Nuremberg |
| hel1 | Finland | Helsinki |
| ash  | USA     | Ashburn, Virginia |
| hil  | USA     | Hillsboro, Oregon |

## 🔧 Configuration

### Environment Variables

```bash
# Required
export HETZNER_TOKEN="your-api-token"

# Optional - customize defaults
export DEFAULT_SERVER_TYPE="cx31"
export DEFAULT_LOCATION="fsn1"
```

### Cloud-Init Customization

Edit `cloud-init.yaml` to customize the deployment:

- **SSH Keys**: Replace the placeholder with your public key
- **Packages**: Add additional packages to install
- **Configuration**: Modify service configurations
- **Scripts**: Add custom installation scripts

## 📊 Post-Deployment

### Access Your Server

```bash
# SSH access (custom port for security)
ssh -p 2222 arcblock@YOUR_SERVER_IP

# Web interface
open http://YOUR_SERVER_IP:8080

# Admin panel
open http://YOUR_SERVER_IP:8080/.well-known/server/admin/
```

### Monitor Installation

```bash
# Check cloud-init status
ssh -p 2222 arcblock@YOUR_SERVER_IP 'sudo cloud-init status --long'

# Check service status
ssh -p 2222 arcblock@YOUR_SERVER_IP 'sudo systemctl status blocklet-server'

# View installation logs
ssh -p 2222 arcblock@YOUR_SERVER_IP 'sudo journalctl -u blocklet-server -f'

# Run health check
ssh -p 2222 arcblock@YOUR_SERVER_IP '/opt/blocklet-server/healthcheck.sh'
```

### Expected Timeline

- **0-2 minutes**: Server creation and boot
- **2-5 minutes**: Package installation and updates
- **5-8 minutes**: Blocklet Server installation
- **8-10 minutes**: Service configuration and startup
- **10+ minutes**: Full system ready

## 🔒 Security Features

- **SSH Hardening**: Key-only authentication on port 2222
- **Firewall**: UFW configured with minimal ports
- **Fail2ban**: Intrusion detection and blocking
- **Auto-updates**: Security patches applied automatically
- **Non-root**: Services run as unprivileged user

## 🔍 Troubleshooting

### Common Issues

**"SSH key placeholder still present"**
```bash
# Check your cloud-init.yaml file
grep "ReplaceWithYourActualEd25519PublicKey" cloud-init.yaml
# Replace with your actual public key from:
cat ~/.ssh/id_ed25519.pub
```

**"API access denied"**
```bash
# Check your token
echo $HETZNER_TOKEN
# Verify token at: https://console.hetzner.cloud/
```

**"Cannot connect via SSH"**
```bash
# Wait for installation to complete (5-10 minutes)
# Check if port 2222 is open
telnet YOUR_SERVER_IP 2222

# Try with verbose SSH
ssh -v -p 2222 arcblock@YOUR_SERVER_IP
```

**"Blocklet Server not responding"**
```bash
# Check service status
ssh -p 2222 arcblock@YOUR_SERVER_IP 'sudo systemctl status blocklet-server'

# Check logs
ssh -p 2222 arcblock@YOUR_SERVER_IP 'sudo journalctl -u blocklet-server --no-pager'

# Restart if needed
ssh -p 2222 arcblock@YOUR_SERVER_IP 'sudo systemctl restart blocklet-server'
```

### Log Locations

```bash
# Cloud-init logs
/var/log/cloud-init.log
/var/log/cloud-init-output.log

# Blocklet Server logs
/opt/blocklet-server/logs/

# System logs
journalctl -u blocklet-server
journalctl -u nginx
journalctl -u redis-server
```

## 🧹 Cleanup

### Delete Test Servers

```bash
# Using quick-deploy
./scripts/quick-deploy.sh delete my-server-name

# Using deploy script
./scripts/deploy-test-server.sh --delete my-server-name

# List all test servers
./scripts/quick-deploy.sh list
```

### Manual Cleanup

```bash
# Delete via API
curl -X DELETE \
  -H "Authorization: Bearer $HETZNER_TOKEN" \
  "https://api.hetzner.cloud/v1/servers/SERVER_ID"

# Or via Hetzner Console
# https://console.hetzner.cloud/
```

## 📚 Additional Resources

- [ArcDeploy Main Documentation](../README.md)
- [Hetzner Cloud API Documentation](https://docs.hetzner.cloud/)
- [Cloud-Init Documentation](https://cloud-init.io/)
- [ArcBlock Blocklet Documentation](https://www.arcblock.io/docs)

## 🆘 Support

If you encounter issues:

1. Run `./scripts/check-setup.sh` to validate your configuration
2. Check the troubleshooting section above
3. Review the logs on your server
4. Open an issue on GitHub with:
   - Output from `scripts/check-setup.sh`
   - Error messages
   - Server logs (if accessible)

## 🔄 Development

### Testing Changes

```bash
# Test with minimal server first
./scripts/quick-deploy.sh small

# Then test full deployment
./scripts/quick-deploy.sh

# Always clean up when done
./scripts/quick-deploy.sh delete test-server-name
```

### Script Modifications

- **scripts/deploy-test-server.sh**: Main deployment logic
- **scripts/quick-deploy.sh**: User-friendly wrapper
- **scripts/check-setup.sh**: Validation and troubleshooting
- **cloud-init.yaml**: Server configuration template

---

**Happy Deploying! 🚀**

For questions or contributions, visit: https://github.com/Pocklabs/ArcDeploy