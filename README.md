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
[![Work In Progress](https://img.shields.io/badge/Status-Work%20In%20Progress-orange.svg)](https://github.com/Pocklabs/blocklet-server-cloud-init/issues)

## 🚀 Quick Start

Deploy a production-ready Arcblock Blocklet Server in minutes:

1. **Replace your SSH key** in the cloud-init file
2. **Deploy to Hetzner Cloud** using the configuration
3. **Access your server** at `http://YOUR_SERVER_IP:8089`

```bash
# 1. Clone this repository
git clone https://github.com/Pocklabs/blocklet-server-cloud-init.git
cd blocklet-server-cloud-init

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
sudo cloud-init status

# View cloud-init logs
sudo cat /var/log/cloud-init-output.log
```

## 📖 Documentation

- **[Firewall & Ports Guide](docs/FIREWALL_PORTS_GUIDE.md)** - Complete network configuration
- **[Implementation Details](docs/IMPLEMENTATION_DETAILS.md)** - Technical deep dive
- **[Changelog](docs/CHANGELOG.md)** - Version history and changes

## 🤝 Contributing

Contributions welcome! Please read our contributing guidelines and submit pull requests for any improvements.

### Development Setup
```bash
git clone https://github.com/Pocklabs/blocklet-server-cloud-init.git
cd blocklet-server-cloud-init

# Test configurations
yamllint cloud-init/*.yaml

# Validate scripts
shellcheck scripts/*.sh
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

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues:** [GitHub Issues](https://github.com/Pocklabs/blocklet-server-cloud-init/issues)
- **Documentation:** [Project Wiki](https://github.com/Pocklabs/blocklet-server-cloud-init/wiki)
- **Discussions:** [GitHub Discussions](https://github.com/Pocklabs/blocklet-server-cloud-init/discussions)

## 🌟 Acknowledgments

- [Arcblock](https://www.arcblock.io/) - Blocklet Server platform
- [Hetzner Cloud](https://www.hetzner.com/cloud) - Cloud infrastructure
- [Podman](https://podman.io/) - Container runtime
- [Cloud-init](https://cloud-init.io/) - Instance initialization

---

**ArcDeploy** - Deploy smarter, not harder. 🚀

























Add Topics** in GitHub (Settings → Topics):
   - `arcblock`
   - `blocklet`
   - `hetzner-cloud`
   - `cloud-init`
   - `podman`
   - `deployment`
   - `automation