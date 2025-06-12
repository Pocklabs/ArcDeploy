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

**Universal Cloud-Init Deployment for ArcBlock Blocklet Server**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Cloud-Init](https://img.shields.io/badge/Cloud--Init-Compatible-blue.svg)](https://cloud-init.io/)
[![Work In Progress](https://img.shields.io/badge/Status-Work%20In%20Progress-orange.svg)](https://github.com/Pocklabs/ArcDeploy/issues)

Deploy a production-ready ArcBlock Blocklet Server to Hetzner Cloud in under 10 minutes using cloud-init—simple, secure, and reliable.

## 🚀 Quick Start

1. Generate SSH key: `ssh-keygen -t ed25519 -C "your-email@example.com"`
2. Edit `cloud-init.yaml` and replace SSH key placeholder
3. Deploy to Hetzner Cloud with cloud-init configuration
4. Access your server: `ssh -p 2222 arcblock@YOUR_SERVER_IP`

**[→ Complete Deployment Guide](docs/hetzner-deployment-guide.md)**

## ✨ Features

- **🔒 Security-First**: Privilege isolation, systemd sandboxing, network segmentation
- **🛡️ Defense-in-Depth**: SSH hardening, firewall protection, intrusion prevention
- **⚡ High Performance**: Native installation without container overhead
- **🛠️ Production Ready**: Auto-monitoring, SSL support, automated updates
- **📦 Zero Dependencies**: Single cloud-init file deployment

## 📋 Requirements

- **Server**: 4+ vCPUs, 8GB+ RAM, 80GB+ SSD
- **OS**: Ubuntu 22.04 LTS (x86_64)
- **Cloud Provider**: Hetzner Cloud (recommended)

## 📚 Documentation

- **[Deployment Guide](docs/hetzner-deployment-guide.md)** - Complete setup instructions
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Issue resolution
- **[Security Assessment](docs/SECURITY_ASSESSMENT.md)** - Security analysis
- **[Quick Reference](docs/quick-start.md)** - Essential commands

## 🛡️ Security

**A+ Security Rating** - Production-ready with defense-in-depth architecture:

- **Privilege Isolation**: Service runs as dedicated `blockletd` user (no sudo access)
- **Systemd Hardening**: Process sandboxing with filesystem/kernel protection
- **Network Segmentation**: Application ports restricted to localhost only
- **Defense-in-Depth**: Multi-layer security controls and monitoring

**[→ Security Documentation](SECURITY.md)**

## 🛠️ Development

Development tools: **[ArcDeploy-Dev](https://github.com/Pocklabs/ArcDeploy-Dev)**

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 💬 Support

**[Issues](https://github.com/Pocklabs/ArcDeploy/issues)** | **[Discussions](https://github.com/Pocklabs/ArcDeploy/discussions)** | **[Docs](docs/)**

---

**Deploy with confidence. Scale with ease.** 🚀