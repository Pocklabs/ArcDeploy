# ArcDeploy

> **⚠️ WORK IN PROGRESS ⚠️**
> 
> **This project is currently under active development and testing. While the native installation approach is our primary focus and has shown good results, we're still refining the deployment process and documentation.**
> 
> **Current Status:**
> - ✅ Native installation approach (primary focus)
> - 🔄 Testing and validation in progress
> - 📝 Documentation being refined based on real-world deployments
> - 🐛 Known issues being addressed
> 
> **Use with caution for production deployments.** We recommend thorough testing in a development environment first.
> 
> ---

**One-Click Arcblock Blocklet Server Deployment for Hetzner Cloud**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Cloud-Init](https://img.shields.io/badge/Cloud--Init-Compatible-blue.svg)](https://cloud-init.io/)
[![Hetzner Cloud](https://img.shields.io/badge/Hetzner-Cloud-red.svg)](https://www.hetzner.com/cloud)
[![Work In Progress](https://img.shields.io/badge/Status-Work%20In%20Progress-orange.svg)](https://github.com/Pocklabs/ArcDeploy/issues)

## 🚀 Quick Start

Deploy a production-ready Arcblock Blocklet Server in under 10 minutes:

1. **Generate SSH key pair**
2. **Replace placeholder in `cloud-init.yaml`**
3. **Deploy to Hetzner Cloud**
4. **Access your server**

```bash
# 1. Clone repository
git clone https://github.com/Pocklabs/ArcDeploy.git
cd ArcDeploy

# 2. Generate SSH key (if needed)
ssh-keygen -t ed25519 -C "your-email@example.com"

# 3. Replace SSH key placeholder
sed -i 's/ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIReplaceWithYourActualEd25519PublicKey your-email@example.com/YOUR_ACTUAL_SSH_PUBLIC_KEY/' cloud-init.yaml

# 4. Deploy via Hetzner Cloud Console (paste cloud-init.yaml content)
```

## ✨ Features

### 🔒 **Security-First Design**
- SSH key-only authentication (passwords disabled)
- Custom SSH port (2222) to reduce attack surface
- UFW firewall with minimal required ports
- Fail2ban intrusion prevention system
- Non-root user execution
- Automatic security updates

### ⚡ **Native Installation**
- Direct Node.js and npm installation (no containers)
- Maximum performance with zero container overhead
- Nginx reverse proxy for web access
- Automatic SSL/TLS certificate support
- Clean system service integration

### 🛠️ **Production Ready**
- Automated health monitoring
- System service integration with systemd
- Comprehensive logging
- Resource optimization
- Auto-restart on failure

## 📁 Project Structure

```
ArcDeploy/
├── cloud-init.yaml           # Single cloud-init configuration
├── scripts/                  # Utility scripts
├── docs/                     # Documentation
├── QUICK_START.md           # Quick deployment guide
└── README.md                # This file
```

## 🎯 Deployment Guide

### Prerequisites
- Hetzner Cloud account
- SSH key pair (ED25519 recommended)
- Basic knowledge of cloud-init

### Step 1: Prepare SSH Key

```bash
# Generate new SSH key
ssh-keygen -t ed25519 -C "your-email@example.com"

# Display public key
cat ~/.ssh/id_ed25519.pub
```

### Step 2: Configure cloud-init.yaml

Replace the SSH key placeholder:

```yaml
ssh_authorized_keys:
  - YOUR_ACTUAL_SSH_PUBLIC_KEY_HERE
```

### Step 3: Deploy to Hetzner Cloud

#### Via Hetzner Console:
1. Create new server (CX31+ recommended, x86 architecture)
2. Select Ubuntu 22.04 LTS
3. Paste `cloud-init.yaml` content in "Cloud config" section
4. Add server to project and create

#### Via Hetzner API:
```bash
export HETZNER_API_TOKEN="your-token-here"

curl -X POST \
  -H "Authorization: Bearer $HETZNER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "image": "ubuntu-22.04",
    "location": "nbg1",
    "name": "blocklet-server",
    "server_type": "cx31",
    "user_data": "'"$(cat cloud-init.yaml)"'"
  }' \
  https://api.hetzner.cloud/v1/servers
```

### Step 4: Access Your Server

Wait 5-10 minutes for installation to complete, then:

```bash
# SSH access
ssh -p 2222 arcblock@YOUR_SERVER_IP

# Web interface
open http://YOUR_SERVER_IP:8080
```

## 🔥 Network Configuration

### Required Ports
| Port | Service | Description |
|------|---------|-------------|
| 2222 | SSH | Secure shell access |
| 8080 | HTTP | Blocklet Server web interface |
| 8443 | HTTPS | Blocklet Server secure web interface |

### Firewall Setup
The deployment automatically configures UFW firewall. For Hetzner Cloud Firewall:

```bash
# Allow SSH
- Source: 0.0.0.0/0, Port: 2222, Protocol: TCP

# Allow HTTP/HTTPS
- Source: 0.0.0.0/0, Port: 8080, Protocol: TCP
- Source: 0.0.0.0/0, Port: 8443, Protocol: TCP
```

## 📊 Post-Deployment

### Verify Installation

```bash
# Check cloud-init status
sudo cloud-init status --long

# Check Blocklet Server service
sudo systemctl status blocklet-server

# Test web interface
curl -I http://localhost:8080
```

### Access Blocklet Server

Your Blocklet Server will be available at:
- **HTTP:** `http://YOUR_SERVER_IP:8080`
- **HTTPS:** `https://YOUR_SERVER_IP:8443` (if SSL configured)
- **Admin Panel:** `http://YOUR_SERVER_IP:8080/.well-known/server/admin/`

## 🔧 Troubleshooting

### Common Issues

**Cloud-init failed:**
```bash
# Check cloud-init logs
sudo tail -f /var/log/cloud-init-output.log
sudo cloud-init status --long
```

**Can't SSH to server:**
```bash
# Verify firewall allows port 2222
sudo ufw status | grep 2222

# Test from another machine
telnet YOUR_SERVER_IP 2222
```

**Blocklet Server not responding:**
```bash
# Check service status
sudo systemctl status blocklet-server
sudo journalctl -u blocklet-server -f

# Restart service if needed
sudo systemctl restart blocklet-server
```

### Debug Commands

```bash
# Complete system status
sudo systemctl status
sudo cloud-init status --long
sudo journalctl -u blocklet-server --no-pager -l

# Check processes
ps aux | grep -E "(blocklet|node)"
netstat -tlnp | grep -E "(8080|8443|2222)"
```

## ⚙️ Server Requirements

### Minimum Requirements
- **CPU:** 2 vCPUs
- **RAM:** 4GB
- **Storage:** 40GB SSD
- **Server Type:** Hetzner CX31 or equivalent

### Recommended Requirements
- **CPU:** 4 vCPUs
- **RAM:** 8GB
- **Storage:** 80GB SSD
- **Server Type:** Hetzner CX41 or equivalent

### Operating System
- Ubuntu 22.04 LTS (tested and recommended)
- x86_64 architecture (ARM not currently supported)

## 🛡️ Security Features

- **SSH Hardening:** Key-only auth, custom port, failed login protection
- **Firewall:** UFW configured with minimal attack surface
- **Intrusion Prevention:** Fail2ban monitoring SSH and web services
- **System Updates:** Automatic security updates enabled
- **Process Isolation:** Non-root execution for all services
- **Log Monitoring:** Comprehensive logging for security analysis

## 📚 Additional Documentation

- **[Quick Start Guide](QUICK_START.md)** - Streamlined deployment instructions
- **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Security Guide](docs/SECURITY.md)** - Security best practices and configuration

## 🤝 Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Development

```bash
# Validate YAML syntax
yamllint cloud-init.yaml

# Test locally (requires appropriate setup)
sudo cloud-init schema --config-file cloud-init.yaml
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues:** [GitHub Issues](https://github.com/Pocklabs/ArcDeploy/issues)
- **Discussions:** [GitHub Discussions](https://github.com/Pocklabs/ArcDeploy/discussions)
- **Documentation:** [Project Wiki](https://github.com/Pocklabs/ArcDeploy/wiki)

---

**Deploy smarter, scale faster.** 🚀