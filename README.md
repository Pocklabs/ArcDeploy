# ArcDeploy

> **⚠️ WORK IN PROGRESS ⚠️**
> 
> **This project is currently under active development and testing. While the configurations are functional, we're still troubleshooting deployment issues and improving compatibility.**
> 
> **Current Status:**
> - 🔄 Docker-based configuration (`standard-docker.yaml`) - **Being debugged**
> - 🔄 Podman configuration (`standard.yaml`) - Known compatibility issues
> - 🔄 Native installation (`native-install.yaml`) - **Testing in progress**
> - 🔄 ARM server compatibility - Known issues, use x86 servers
> - 📝 Documentation being refined based on real-world testing
> 
> **Known Issues:**
> - Cloud-init may not execute on ARM-based Hetzner servers
> - Container compatibility issues with Arcblock images (both Docker & Podman)
> - External script downloads may fail in some regions
> - Arcblock image availability and authentication issues
> 
> **Recommended Approach:** Try `native-install.yaml` for direct installation without containers
> 
> **Use at your own risk for production deployments.** We recommend testing thoroughly in a development environment first.
> 
> ---

**Automated Arcblock Blocklet Server deployment for Hetzner Cloud with enterprise-grade security and monitoring.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Cloud-Init](https://img.shields.io/badge/Cloud--Init-Compatible-blue.svg)](https://cloud-init.io/)
[![Hetzner Cloud](https://img.shields.io/badge/Hetzner-Cloud-red.svg)](https://www.hetzner.com/cloud)
[![Work In Progress](https://img.shields.io/badge/Status-Work%20In%20Progress-orange.svg)](https://github.com/Pocklabs/ArcDeploy/issues)

## 🚀 Quick Start

Deploy a production-ready Arcblock Blocklet Server in minutes:

1. **Replace your SSH key** in the cloud-init file
2. **Deploy to Hetzner Cloud** using the configuration
3. **Access your server** at `http://YOUR_SERVER_IP:8089`

```bash
# 1. Clone this repository
git clone https://github.com/Pocklabs/ArcDeploy.git
cd ArcDeploy

# Replace SSH key in cloud-init/minimal.yaml
sed -i 's/ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIReplaceWithYourActualEd25519PublicKey your-email@example.com/YOUR_ACTUAL_SSH_KEY/' cloud-init/minimal.yaml

# 3. Deploy via Hetzner Cloud Console or API
```

## 📋 Features

### 🔒 **Security First**
- SSH key-only authentication (no passwords)
- Custom SSH port (2222) with hardened configuration
- UFW firewall with minimal attack surface
- Fail2ban intrusion prevention
- Rootless container execution
- Regular security updates

### 🏗️ **Production Ready**
- Automated Blocklet Server installation
- Health monitoring with auto-recovery
- Automated backups with retention policy
- Log rotation and system optimization
- Container auto-updates
- Comprehensive validation tools

### ⚡ **Easy Deployment**
- Multiple cloud-init configurations (minimal to full-featured)
- Automated firewall setup scripts
- One-command validation and troubleshooting
- External script approach for size optimization
- Complete documentation and guides

## 📁 Project Structure

```
ArcDeploy/
├── cloud-init/                 # Cloud-init configurations
│   ├── minimal.yaml           # Recommended: External script approach (657 bytes)
│   ├── standard.yaml          # Self-contained setup (4.7 KB)
│   └── full-featured.yaml     # Complete configuration (18.6 KB)
├── scripts/                   # Automation scripts
│   ├── setup.sh              # Main installation script
│   ├── validate-setup.sh     # Comprehensive validation
│   └── hetzner-firewall-setup.sh # Firewall automation
├── docs/                      # Documentation
│   ├── FIREWALL_PORTS_GUIDE.md
│   ├── IMPLEMENTATION_DETAILS.md
│   └── CHANGELOG.md
└── README.md                  # This file
```

## 🎯 Deployment Options

### Option 1: Native Installation (Currently Testing 🔄)
**File:** `cloud-init/native-install.yaml` (11.0 KB)
- 🔄 **No containers** - direct Node.js installation
- 🔄 **Maximum performance** - no container overhead
- 🔄 **Nginx proxy** included for web access
- 🔄 **Under active testing** - most promising approach

### Option 2: Docker-Based (Known Issues ⚠️)
**File:** `cloud-init/standard-docker.yaml` (11.3 KB)
- ⚠️ **Container issues** - Arcblock image compatibility problems
- ⚠️ **Image availability** - may require authentication or different image
- 🔄 **Being debugged** - Docker setup and image issues
- 🔄 **Standard approach** - but having deployment problems

### Option 3: Podman-Based (Known Issues ⚠️)
**File:** `cloud-init/standard.yaml` (4.7 KB)
- ⚠️ **Compatibility issues** with Arcblock images
- ⚠️ **Rootless setup complexity** - systemd user services
- 🔄 **Being debugged** - use Docker version instead

### Option 4: Minimal External Script
**File:** `cloud-init/minimal.yaml` (747 bytes)
- ✅ **Tiny size** - uses external setup script
- ⚠️ **Podman-based** - inherits Podman issues
- 🔄 **For testing only** - not recommended for production

## 🛠️ Quick Setup Guide

### 1. Prepare Your SSH Key

```bash
# Generate ED25519 key (recommended)
ssh-keygen -t ed25519 -C "your-email@example.com"

# Display your public key
cat ~/.ssh/id_ed25519.pub
```

### 2. Configure Cloud-Init

Replace the SSH key placeholder in your chosen configuration:

```yaml
ssh_authorized_keys:
  - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIYourActualKeyHere your-email@example.com
```

### 3. Deploy to Hetzner Cloud

#### Via Hetzner Console:
1. Create new server (CX31+ recommended)
2. Choose Ubuntu 22.04 LTS
3. Paste cloud-init configuration in "Cloud config" field
4. Create server

#### Via Hetzner API:
```bash
export HETZNER_API_TOKEN="your-api-token"

curl -X POST \
  -H "Authorization: Bearer $HETZNER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "image": "ubuntu-22.04",
    "location": "nbg1", 
    "name": "blocklet-server",
    "server_type": "cx31",
    "user_data": "'"$(cat cloud-init/minimal.yaml)"'"
  }' \
  https://api.hetzner.cloud/v1/servers
```

### 4. Configure Firewall

```bash
# Automated firewall setup
export HETZNER_API_TOKEN="your-api-token"
./scripts/hetzner-firewall-setup.sh blocklet-server
```

### 5. Access Your Server

```bash
# SSH access (after setup completes - ~5-10 minutes)
ssh -p 2222 arcblock@YOUR_SERVER_IP

# Web interface
open http://YOUR_SERVER_IP:8089
```

## 🔥 Required Ports

| Port | Purpose | Required |
|------|---------|----------|
| 2222 | SSH Access | Critical |
| 8089 | Blocklet Server | Critical |
| 80 | HTTP (redirects to 8089) | Important |
| 443 | HTTPS (if SSL configured) | Important |

## 📊 Validation & Monitoring

### Validate Installation
```bash
# Run comprehensive validation
./scripts/validate-setup.sh
```

### Monitor Health
```bash
# Check service status
sudo systemctl status blocklet-server

# View logs
sudo journalctl -u blocklet-server -f

# Manual health check
sudo -u arcblock /home/arcblock/blocklet-server/healthcheck.sh
```

### Backup Management
```bash
# Manual backup
sudo -u arcblock /home/arcblock/blocklet-server/backup.sh

# Check automated backups
ls -la /home/arcblock/backups/
```

## 🔧 Troubleshooting

### Automated Diagnostic Tools

**Quick System Diagnosis:**
```bash
# Download and run comprehensive diagnostic script
curl -fsSL https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/scripts/debug_commands.sh -o /tmp/debug_commands.sh
chmod +x /tmp/debug_commands.sh
/tmp/debug_commands.sh
```

**Manual Recovery (if cloud-init failed):**
```bash
# Download and run automated recovery script
curl -fsSL https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/scripts/manual_recovery.sh -o /tmp/manual_recovery.sh
chmod +x /tmp/manual_recovery.sh
sudo /tmp/manual_recovery.sh
```

### Common Issues

**Can't SSH to server:**
```bash
# Check firewall allows port 2222
sudo ufw status | grep 2222

# Test connectivity
telnet YOUR_SERVER_IP 2222
```

**Blocklet Server not accessible:**
```bash
# Check service status
sudo systemctl status blocklet-server

# Check container status
sudo -u arcblock podman ps

# Check local connectivity
curl -I http://localhost:8089
```

**Cloud-init failed:**
```bash
# Check cloud-init status
sudo cloud-init status --long

# View cloud-init logs
sudo cat /var/log/cloud-init-output.log
sudo cat /var/log/cloud-init.log | tail -50
```

## 📖 Documentation

- **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)** - Comprehensive debugging and recovery procedures
- **[Firewall & Ports Guide](docs/FIREWALL_PORTS_GUIDE.md)** - Complete network configuration
- **[Implementation Details](docs/IMPLEMENTATION_DETAILS.md)** - Technical deep dive
- **[Changelog](docs/CHANGELOG.md)** - Version history and changes

## 🤝 Contributing

Contributions welcome! Please read our contributing guidelines and submit pull requests for any improvements.

### Development Setup
```bash
git clone https://github.com/Pocklabs/ArcDeploy.git
cd ArcDeploy

# Test configurations
yamllint cloud-init/*.yaml

# Validate scripts
shellcheck scripts/*.sh

# Test diagnostic tools
./scripts/debug_commands.sh
```

## 📋 Requirements

### Server Requirements
- **Minimum:** CX31 (4GB RAM, 2 vCPUs, 40GB storage)
- **Recommended:** CX41 (8GB RAM, 4 vCPUs, 80GB storage)
- **OS:** Ubuntu 22.04 LTS

### Local Requirements
- SSH key pair (ED25519 recommended)
- Hetzner Cloud account and API token
- curl/wget for script execution

## 🐛 Debugging Cloud-Init Issues

If you encounter problems during deployment, use these debugging commands based on the [official cloud-init debugging guide](https://cloudinit.readthedocs.io/en/latest/howto/debugging.html):

### Quick Status Check
```bash
# Check overall cloud-init status
sudo cloud-init status --long

# Check if cloud-init services completed
sudo systemctl status cloud-init-local.service cloud-init-network.service cloud-config.service cloud-final.service
```

### Common Issues and Solutions

#### Can't SSH to Instance
```bash
# Check serial console for errors (if available)
# Try password authentication if SSH keys failed
# Check cloud-init logs for user creation errors
sudo tail -f /var/log/cloud-init.log
```

#### Cloud-Init Didn't Run
```bash
# Check datasource detection
sudo cat /run/cloud-init/ds-identify.log

# Verify services started
sudo systemctl list-jobs --after
```

#### Cloud-Init Incomplete/Hanging
```bash
# Check for system errors
sudo dmesg -T | grep -i -e warning -e error -e fatal

# Check for failed services
sudo systemctl --failed

# Find blocking processes
sudo pstree $(pgrep cloud-init)
```

#### Configuration Issues
```bash
# Validate your YAML before deployment
python3 -c "import yaml; yaml.safe_load(open('cloud-init/minimal.yaml'))"

# Check cloud-init logs for specific errors
sudo tail -100 /var/log/cloud-init.log
sudo tail -100 /var/log/cloud-init-output.log

# Re-run cloud-init for testing (destroys existing config)
sudo cloud-init clean --logs
sudo cloud-init init
```

### Log Locations
- **Main log**: `/var/log/cloud-init.log`
- **Command output**: `/var/log/cloud-init-output.log`
- **Service status**: `/var/log/cloud-init-output.log`
- **Datasource detection**: `/run/cloud-init/ds-identify.log`

### Blocklet Server Specific
```bash
# Check Blocklet Server service
sudo systemctl status blocklet-server

# Check container status
sudo -u arcblock podman ps

# Run health check
sudo -u arcblock /home/arcblock/blocklet-server/healthcheck.sh

# Check service logs
sudo journalctl -u blocklet-server -f
```

### 📚 Comprehensive Debugging
For detailed troubleshooting including recovery procedures, manual fixes, and advanced debugging techniques, see our complete [Debugging Guide](docs/DEBUGGING_GUIDE.md).

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues:** [GitHub Issues](https://github.com/Pocklabs/ArcDeploy/issues)
- **Documentation:** [Project Wiki](https://github.com/Pocklabs/ArcDeploy/wiki)
- **Discussions:** [GitHub Discussions](https://github.com/Pocklabs/ArcDeploy/discussions)

## 🌟 Acknowledgments

- [Arcblock](https://www.arcblock.io/) - Blocklet Server platform
- [Hetzner Cloud](https://www.hetzner.com/cloud) - Cloud infrastructure
- [Podman](https://podman.io/) - Container runtime
- [Cloud-init](https://cloud-init.io/) - Instance initialization

---

**ArcDeploy** - Deploy smarter, not harder. 🚀