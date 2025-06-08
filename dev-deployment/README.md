# ArcDeploy Development Deployment

This directory contains development-specific deployment tools and guides for ArcDeploy that are not included in the main production repository.

## Overview

The development deployment folder provides manual installation procedures and scripts for environments where:
- You have root SSH access to a fresh Ubuntu server
- You need to manually create the arcblock user
- You want to understand each step of the deployment process
- Cloud-init is not available or preferred

## Contents

### 📖 Documentation
- **`MANUAL_INSTALLATION_GUIDE.md`** - Comprehensive step-by-step manual installation guide
- **`README.md`** - This file

### 🔧 Scripts
- **`manual-install.sh`** - Automated script for manual installation process

## When to Use This

Use the development deployment approach when:

1. **Root Server Access**: You have a fresh Ubuntu 22.04 server with root SSH access
2. **Manual Setup Required**: Cloud-init is not available or you prefer manual control
3. **Learning/Development**: You want to understand each step of the installation
4. **Custom Environments**: You need to modify the installation process
5. **Troubleshooting**: You're debugging installation issues

## Quick Start

### Option 1: Automated Script Installation

```bash
# As root on your Ubuntu 22.04 server
wget https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/dev-deployment/manual-install.sh
chmod +x manual-install.sh
./manual-install.sh
```

### Option 2: Manual Step-by-Step Installation

1. Download the manual installation guide:
   ```bash
   wget https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/dev-deployment/MANUAL_INSTALLATION_GUIDE.md
   ```

2. Follow the comprehensive guide step by step

## Prerequisites

- **Server**: Fresh Ubuntu 22.04 LTS installation
- **Access**: Root SSH access with SSH key authentication
- **Resources**: Minimum 4GB RAM, 40GB disk space, 4 CPU cores
- **Network**: Internet connectivity for package downloads
- **SSH Key**: Ed25519 or RSA public key for arcblock user

## Installation Process Overview

The manual installation process includes:

### Phase 1: System Preparation
- System package updates
- Essential package installation
- Basic firewall configuration

### Phase 2: User & Security Setup
- Create arcblock user with sudo privileges
- Configure SSH key authentication
- Implement SSH hardening (port 2222, key-only auth)
- Disable root login

### Phase 3: Application Stack
- Install Node.js LTS
- Install Blocklet CLI globally
- Configure Redis backend
- Set up Nginx reverse proxy

### Phase 4: Security Hardening
- Configure Fail2ban intrusion detection
- Set up UFW firewall rules
- Apply system hardening parameters
- Configure resource limits

### Phase 5: Service Configuration
- Initialize Blocklet Server
- Create systemd service
- Set up health monitoring
- Configure automated health checks

### Phase 6: Validation & Testing
- Comprehensive system testing
- Security validation
- Service verification
- Performance checks

## Security Features

The manual installation implements comprehensive security:

- ✅ **SSH Hardening**: Port 2222, key-only authentication, root disabled
- ✅ **Firewall Protection**: UFW with minimal required ports
- ✅ **Intrusion Detection**: Fail2ban monitoring SSH and web services
- ✅ **Service Isolation**: Non-root execution with proper permissions
- ✅ **System Hardening**: Kernel parameters and resource limits
- ✅ **Monitoring**: Automated health checks every 5 minutes

## Post-Installation

After successful installation:

### Access Information
```bash
# SSH Access
ssh -p 2222 arcblock@YOUR_SERVER_IP

# Web Interfaces
http://YOUR_SERVER_IP:8080  # Blocklet Server
http://YOUR_SERVER_IP:80    # Nginx Proxy
```

### Service Management
```bash
# Check service status
sudo systemctl status blocklet-server

# View logs
sudo journalctl -u blocklet-server -f

# Run health check
/opt/blocklet-server/healthcheck.sh
```

### Validation
```bash
# Run comprehensive validation
curl -fsSL https://raw.githubusercontent.com/Pocklabs/ArcDeploy/main/scripts/validate-setup.sh | bash
```

## Differences from Production Deployment

| Aspect | Production (cloud-init) | Development (manual) |
|--------|------------------------|----------------------|
| **Setup Method** | Automated cloud-init | Manual step-by-step |
| **User Creation** | Automatic | Manual root → arcblock |
| **Initial Access** | SSH key in cloud-init | Root SSH then arcblock |
| **Customization** | Limited to cloud-init | Full control at each step |
| **Learning Value** | Black box | Educational |
| **Time Required** | 5-10 minutes | 30-60 minutes |
| **Troubleshooting** | More difficult | Step-by-step debugging |

## Troubleshooting

### Common Issues

1. **SSH Connection Problems**
   - Verify firewall allows port 2222
   - Check SSH service status
   - Validate SSH key format

2. **Service Startup Issues**
   - Check Node.js installation
   - Verify Blocklet CLI accessibility
   - Review systemd service logs

3. **Permission Problems**
   - Ensure proper ownership of /opt/blocklet-server
   - Verify arcblock user has sudo access
   - Check file permissions

### Getting Help

- **Installation Guide**: Detailed troubleshooting in `MANUAL_INSTALLATION_GUIDE.md`
- **Main Documentation**: Refer to main ArcDeploy repository
- **Issues**: Create GitHub issue with detailed error information
- **Validation**: Use provided validation scripts

## Development Notes

### File Structure
```
dev-deployment/
├── README.md                    # This file
├── MANUAL_INSTALLATION_GUIDE.md # Complete manual guide
└── manual-install.sh           # Automated installation script
```

### Version Information
- **Guide Version**: 1.0
- **Script Version**: 1.0
- **Target OS**: Ubuntu 22.04 LTS
- **Last Updated**: June 8, 2025

### Contributing

When contributing to development deployment:

1. Test all procedures on fresh Ubuntu 22.04 installations
2. Maintain compatibility with security standards
3. Update both manual guide and automated script
4. Verify all security configurations
5. Test SSH access thoroughly before finalizing

## Support

For support with development deployment:

- **Documentation**: Read the complete manual installation guide
- **Validation**: Use the provided validation scripts
- **Issues**: GitHub issues with [dev-deployment] tag
- **Security**: Follow the comprehensive security checklist

## License

This development deployment tooling is part of the ArcDeploy project and follows the same MIT license terms.

---

**Important**: These development deployment tools are intended for development, testing, and educational purposes. For production deployments, use the main cloud-init approach for better automation and consistency.