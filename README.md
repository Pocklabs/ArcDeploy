# ArcDeploy

**Universal Cloud-Init Deployment for ArcBlock Blocklet Server**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Cloud-Init](https://img.shields.io/badge/Cloud--Init-Compatible-blue.svg)](https://cloud-init.io/)
[![Production Ready](https://img.shields.io/badge/Status-Production%20Ready-green.svg)](https://github.com/Pocklabs/ArcDeploy)

Deploy a production-ready ArcBlock Blocklet Server to any cloud provider in under 10 minutes using cloud-init. Simple, secure, and reliable.

## 🚀 Quick Start

```bash
# 1. Clone repository
git clone https://github.com/Pocklabs/ArcDeploy.git
cd ArcDeploy

# 2. Add your SSH public key to cloud-init.yaml
nano cloud-init.yaml

# 3. Deploy to your cloud provider using the cloud-init.yaml file
```

## ✨ Features

- **🔒 Security-First**: SSH key authentication, custom ports, firewall protection
- **⚡ High Performance**: Native installation without container overhead
- **🌐 Universal**: Works with any cloud provider that supports cloud-init
- **🛠️ Production Ready**: Auto-monitoring, SSL support, service integration
- **📦 Zero Dependencies**: Single cloud-init file deployment
- **🚀 Enhanced Deployment**: Advanced scripts with retry logic and validation
- **🛡️ Security Hardening**: Fail2ban, modern SSH ciphers, system optimization

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

## 🤖 Automated Deployment (Recommended)

For the fastest and easiest deployment, use our automated scripts:

### Standard Deployment
Quick deployment with basic features:

```bash
# 1. Validate your setup
./check-setup.sh

# 2. Quick deploy with optimal defaults
export HETZNER_TOKEN="your-hetzner-cloud-api-token"
./quick-deploy.sh

# 3. Access your server (after 5-10 minutes)
ssh -p 2222 arcblock@YOUR_SERVER_IP
open http://YOUR_SERVER_IP:8080
```

**Features:**
- ✅ Automatic server creation and configuration
- ✅ Built-in validation and error checking
- ✅ Real-time deployment monitoring
- ✅ SSH connectivity testing
- ✅ One-command cleanup

### Enhanced Deployment (New!)
Advanced deployment with improved security and monitoring:

```bash
# 1. Use enhanced script with validation
export HETZNER_TOKEN="your-hetzner-cloud-api-token"
./scripts/deploy-test-server-enhanced.sh --verbose my-server

# 2. Preview deployment (dry-run mode)
./scripts/deploy-test-server-enhanced.sh --dry-run my-server large ash

# 3. Manage servers
./scripts/deploy-test-server-enhanced.sh --list
./scripts/deploy-test-server-enhanced.sh --status my-server
./scripts/deploy-test-server-enhanced.sh --delete my-server
```

**Enhanced Features:**
- ✅ API retry logic with rate limit handling
- ✅ Real-time server type validation
- ✅ Cloud-init size and syntax validation
- ✅ Advanced security hardening
- ✅ Automated health monitoring
- ✅ Dry-run mode for testing
- ✅ Verbose logging for troubleshooting

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed automation documentation and [docs/enhanced-features.md](docs/enhanced-features.md) for enhanced feature documentation.

## 📋 Manual Deployment

If you prefer manual deployment or need to use a different cloud provider:

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

Use your cloud provider's interface to create a new server with cloud-init:

#### Hetzner Cloud
1. Create new server (CX31 or higher)
2. Select Ubuntu 22.04 LTS
3. Paste `cloud-init.yaml` content in "Cloud config" section
4. Create server

#### AWS EC2
1. Launch new EC2 instance (t3.large or higher)
2. Select Ubuntu 22.04 LTS AMI
3. In "Advanced Details" → "User data", paste `cloud-init.yaml` content
4. Configure security groups for ports 2222, 8080, 8443

#### Google Cloud Platform
1. Create new Compute Engine instance (e2-standard-4 or higher)
2. Select Ubuntu 22.04 LTS
3. In "Management" → "Automation", paste `cloud-init.yaml` content
4. Configure firewall rules for required ports

#### DigitalOcean
1. Create new Droplet (4GB or higher)
2. Select Ubuntu 22.04 LTS
3. Check "User data" and paste `cloud-init.yaml` content
4. Configure firewall for required ports

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

## 🤖 Automation Tools

This project includes powerful automation scripts for easy testing and deployment:

### Quick Commands

```bash
# Validate setup before deployment
./check-setup.sh

# Deploy with sensible defaults
./quick-deploy.sh

# Deploy different configurations
./quick-deploy.sh small    # Minimal server (cx11)
./quick-deploy.sh large    # High-performance (cx41)
./quick-deploy.sh us       # Deploy to US location

# Manage test servers
./quick-deploy.sh list            # List all test servers
./quick-deploy.sh delete my-test  # Clean up when done
```

### Full Control

```bash
# Custom deployment with all options
./deploy-test-server.sh my-server cx31 fsn1

# Advanced server management
./deploy-test-server.sh --delete my-server
```

**For complete automation documentation, see [DEPLOYMENT.md](DEPLOYMENT.md)**

## 🛡️ Security Features

- **SSH Hardening**: Key-only authentication on port 2222
- **Firewall Protection**: UFW configured with minimal attack surface
- **Intrusion Prevention**: Fail2ban monitoring and blocking
- **Automatic Updates**: Security patches applied automatically
- **Process Isolation**: Services run as non-root user

## 📚 Documentation

- **[Automated Deployment](DEPLOYMENT.md)** - Quick deployment scripts and automation
- **[Quick Start Guide](docs/quick-start.md)** - Streamlined deployment
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

## 🔗 Development Tools

For advanced users, developers, and contributors, comprehensive development tools are available in the **[ArcDeploy-Dev](https://github.com/Pocklabs/ArcDeploy-Dev)** repository:

- **Testing Framework**: Comprehensive test suites with 100+ scenarios
- **Debug Tools**: Advanced debugging and diagnostic utilities
- **Failure Injection**: Resilience testing with 31 failure scenarios
- **Performance Benchmarking**: System performance analysis tools
- **Mock Infrastructure**: Development and testing environments

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

## 🤝 Contributing

We welcome contributions! Please see our [contribution guidelines](CONTRIBUTING.md).

For development-related contributions, please use the **[ArcDeploy-Dev](https://github.com/Pocklabs/ArcDeploy-Dev)** repository.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/Pocklabs/ArcDeploy/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Pocklabs/ArcDeploy/discussions)
- **Documentation**: [Project Documentation](docs/)

---

**Deploy with confidence. Scale with ease.** 🚀