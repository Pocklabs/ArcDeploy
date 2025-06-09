# ArcDeploy



**Universal Cloud-Init Deployment for ArcBlock Blocklet Server**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Cloud-Init](https://img.shields.io/badge/Cloud--Init-Compatible-blue.svg)](https://cloud-init.io/)
[![Production Ready](https://img.shields.io/badge/Status-Production%20Ready-green.svg)](https://github.com/Pocklabs/ArcDeploy)

Deploy a production-ready ArcBlock Blocklet Server to any cloud provider in under 10 minutes using cloud-init—simple, secure, and reliable.

## 🚀 Quick Start

Deploy a production-ready Arcblock Blocklet Server in under 10 minutes:

1. **Generate SSH key pair**
2. **Replace placeholder in `cloud-init.yaml`**
3. **Deploy to your cloud provider**
4. **Access your server**

```bash
# 1. Clone repository
git clone https://github.com/Pocklabs/ArcDeploy.git
cd ArcDeploy

# 2. Generate SSH key (if needed)
ssh-keygen -t ed25519 -C "your-email@example.com"

# 3. Replace SSH key placeholder
sed -i 's/ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIReplaceWithYourActualEd25519PublicKey your-email@example.com/YOUR_ACTUAL_SSH_PUBLIC_KEY/' cloud-init.yaml

# 4. Deploy via your cloud provider (paste cloud-init.yaml content)
```

## ✨ Features

- **🔒 Security-First**: SSH key authentication, custom ports, and firewall protection
- **⚡ High Performance**: Native installation without container overhead
- **🌐 Universal**: Works with any cloud provider that supports cloud-init
- **🛠️ Production Ready**: Auto-monitoring, SSL support, and service integration
- **📦 Zero Dependencies**: Single cloud-init file deployment

## 📋 Requirements

### Server Specifications

- **Minimum**: 4 vCPUs, 8GB RAM, 80GB SSD
- **Recommended**: 8 vCPUs, 16GB RAM, 160GB SSD
- **OS**: Ubuntu 22.04 LTS (x86_64)

### Network Ports

- **2222**: SSH access
- **8080**: HTTP web interface
- **8443**: HTTPS web interface

## 🎯 Deployment Steps

### Step 1: Prepare SSH Key

Generate an SSH key pair if you don't have one:

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
cat ~/.ssh/id_ed25519.pub
```

### Step 2: Configure cloud-init.yaml

Edit the `cloud-init.yaml` file and replace the SSH key placeholder with your actual public key:

```yaml
ssh_authorized_keys:
  - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIYourActualPublicKeyHere your-email@example.com
```

### Step 3: Deploy to Cloud Provider

Deploy to Hetzner Cloud using their interface:

#### Hetzner Cloud

1. Create new server (CX31 or higher)
2. Select Ubuntu 22.04 LTS
3. Paste `cloud-init.yaml` content in "Cloud config" section
4. Create server

> **Note**: While ArcDeploy works with any cloud provider that supports cloud-init, we recommend Hetzner Cloud for its simplicity, reliability, and cost-effectiveness.

### Step 4: Access Your Server

Wait 5-10 minutes for installation to complete, then access your server:

```bash
# SSH access
ssh -p 2222 arcblock@YOUR_SERVER_IP

# Web interface
open http://YOUR_SERVER_IP:8080

# Admin panel
open http://YOUR_SERVER_IP:8080/.well-known/server/admin/
```

## 🔧 Post-Deployment

### Verify Installation

```bash
# Check deployment status
ssh -p 2222 arcblock@YOUR_SERVER_IP
sudo cloud-init status --long
sudo systemctl status blocklet-server
```

### Initial Setup

1. **Access Admin Panel**: Visit `http://YOUR_SERVER_IP:8080/.well-known/server/admin/`
2. **Complete Setup Wizard**: Follow the on-screen instructions
3. **Configure SSL** (optional): Set up Let's Encrypt certificates
4. **Install Blocklets**: Browse and install your desired blocklets

## 🛡️ Security Features

- **SSH Hardening**: Key-only authentication on port 2222
- **Firewall Protection**: UFW configured with minimal attack surface
- **Intrusion Prevention**: Fail2ban monitoring and blocking
- **Automatic Updates**: Security patches applied automatically
- **Process Isolation**: Services run as non-root user

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

## 🆘 Troubleshooting

### Common Issues

**Can't connect via SSH:**

```bash
# Check if port 2222 is open
telnet YOUR_SERVER_IP 2222

# Verify SSH key is correct
ssh -p 2222 -v arcblock@YOUR_SERVER_IP
```

**Blocklet Server not responding:**

```bash
# Check service status
ssh -p 2222 arcblock@YOUR_SERVER_IP
sudo systemctl status blocklet-server
sudo journalctl -u blocklet-server -f
```

**Cloud-init failed:**

```bash
# Check cloud-init logs
sudo tail -f /var/log/cloud-init-output.log
sudo cloud-init status --long
```

## 📚 Documentation

- **[Quick Start Guide](docs/quick-start.md)** - Streamlined deployment
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

## 🔗 Development Tools

For advanced users, developers, and contributors, comprehensive development tools are available in the **[ArcDeploy-Dev](https://github.com/Pocklabs/ArcDeploy-Dev)** repository:

- **Testing Framework**: Comprehensive test suites with 100+ scenarios
- **Debug Tools**: Advanced debugging and diagnostic utilities
- **Failure Injection**: Resilience testing with 31 failure scenarios
- **Performance Benchmarking**: System performance analysis tools
- **Mock Infrastructure**: Development and testing environments

## 🌍 Other Cloud Providers

While this documentation focuses on Hetzner Cloud, ArcDeploy works with any cloud provider that supports cloud-init. For other providers, simply paste the `cloud-init.yaml` content in your provider's user data or cloud config section during server creation.

## 🤝 Contributing

We welcome contributions! Please see our [contribution guidelines](CONTRIBUTING.md).

For development-related contributions, please use the **[ArcDeploy-Dev](https://github.com/Pocklabs/ArcDeploy-Dev)** repository.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/Pocklabs/ArcDeploy/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Pocklabs/ArcDeploy/discussions)
- **Documentation**: [Project Documentation](docs/)

---

**Deploy with confidence. Scale with ease.** 🚀