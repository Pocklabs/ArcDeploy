# ArcDeploy Development Deployment

[![Dev Branch](https://img.shields.io/badge/Branch-dev--deployment-orange.svg)](https://github.com/Pocklabs/ArcDeploy/tree/dev-deployment)
[![Manual Install](https://img.shields.io/badge/Install-Manual-blue.svg)](manual-install.sh)

This directory contains development-specific deployment tools and guides for ArcDeploy, providing manual installation capabilities and step-by-step deployment procedures for development and testing environments.

## Overview

The development deployment folder provides manual installation procedures and scripts for environments where automated cloud-init deployment is not suitable. This approach is ideal for:

- **Development & Testing**: Understanding each deployment step
- **Custom Environments**: Non-standard server configurations
- **Educational Purposes**: Learning ArcDeploy internals
- **Troubleshooting**: Debugging deployment issues
- **Root Access Scenarios**: Fresh Ubuntu servers with root SSH
- **Cloud-init Unavailable**: Providers without cloud-init support

## Contents

### 📖 Documentation
- **`MANUAL_INSTALLATION_GUIDE.md`** - Comprehensive step-by-step manual installation guide
- **`README.md`** - This file (development deployment overview)

### 🔧 Scripts
- **`manual-install.sh`** - Automated script for manual installation process

### 🔗 Integration with Enhanced ArcDeploy
This dev-deployment directory is part of the enhanced ArcDeploy system in the `dev-deployment` branch, which includes:
- **Shared Libraries**: `../scripts/lib/common.sh` for consistent functions
- **Configuration Management**: `../config/arcdeploy.conf` for centralized settings
- **Testing Framework**: `../tests/test-suite.sh` for validation
- **Multi-Cloud Templates**: `../templates/` for various providers

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
wget https://raw.githubusercontent.com/Pocklabs/ArcDeploy/dev-deployment/dev-deployment/manual-install.sh
chmod +x manual-install.sh
./manual-install.sh
```

**Note**: Use the `dev-deployment` branch URL for access to the latest enhanced features.

### Option 2: Manual Step-by-Step Installation

1. Download the manual installation guide:
   ```bash
   wget https://raw.githubusercontent.com/Pocklabs/ArcDeploy/dev-deployment/dev-deployment/MANUAL_INSTALLATION_GUIDE.md
   ```

2. Follow the comprehensive guide step by step

### Option 3: Enhanced Installation (Recommended)

For the full enhanced experience with shared libraries and testing:

```bash
# Clone the dev-deployment branch
git clone -b dev-deployment https://github.com/Pocklabs/ArcDeploy.git
cd ArcDeploy

# Use enhanced manual installation with shared libraries
cd dev-deployment/
./manual-install.sh

# Optional: Run comprehensive tests after installation
cd ../
./tests/test-suite.sh
```

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

#### Standard Validation
```bash
# Run comprehensive validation
curl -fsSL https://raw.githubusercontent.com/Pocklabs/ArcDeploy/dev-deployment/scripts/validate-setup.sh | bash
```

#### Enhanced Validation (if using dev-deployment branch)
```bash
# Run enhanced test suite
./tests/test-suite.sh

# Run specific validation categories
./tests/test-suite.sh deployment security

# Generate detailed validation report
./tests/test-suite.sh --verbose --report
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

### Integration with Enhanced ArcDeploy
When using the `dev-deployment` branch, this directory integrates with:

```
ArcDeploy/
├── config/arcdeploy.conf        # Centralized configuration
├── scripts/lib/common.sh        # Shared function library
├── templates/                   # Multi-cloud templates
├── tests/test-suite.sh          # Comprehensive testing
└── dev-deployment/              # This directory
    ├── README.md
    ├── MANUAL_INSTALLATION_GUIDE.md
    └── manual-install.sh
```

### Enhanced Features Available
- **Shared Libraries**: Consistent logging and error handling
- **Configuration Management**: Centralized settings in `config/arcdeploy.conf`
- **Testing Framework**: Automated validation with `tests/test-suite.sh`
- **Multi-Cloud Support**: Generate configs for different providers
- **Dependency Management**: Systematic dependency checking

### Version Information
- **Guide Version**: 1.0
- **Script Version**: 1.0
- **Target OS**: Ubuntu 22.04 LTS
- **Last Updated**: June 8, 2025

### Contributing

When contributing to development deployment:

1. **Testing**: Test all procedures on fresh Ubuntu 22.04 installations
2. **Security**: Maintain compatibility with security standards
3. **Documentation**: Update both manual guide and automated script
4. **Validation**: Use the enhanced test suite for verification
5. **Integration**: Ensure compatibility with shared libraries
6. **Configuration**: Use centralized configuration system
7. **SSH Access**: Test SSH access thoroughly before finalizing

#### Development Workflow for Contributors
```bash
# 1. Set up development environment
git clone -b dev-deployment https://github.com/Pocklabs/ArcDeploy.git
cd ArcDeploy

# 2. Source shared libraries for development
source scripts/lib/common.sh

# 3. Make changes to dev-deployment/
vim dev-deployment/manual-install.sh

# 4. Test changes
./tests/test-suite.sh

# 5. Validate on fresh server
cd dev-deployment/
./manual-install.sh

# 6. Run comprehensive validation
cd ../
./tests/test-suite.sh deployment
```

## Support

For support with development deployment:

- **Documentation**: Read the complete manual installation guide
- **Enhanced Testing**: Use `./tests/test-suite.sh` for comprehensive validation
- **Issues**: GitHub issues with `[dev-deployment]` tag
- **Security**: Follow the comprehensive security checklist
- **Shared Libraries**: Leverage `scripts/lib/common.sh` for consistent operations
- **Configuration**: Customize via `config/arcdeploy.conf`

### Quick Troubleshooting

```bash
# Check system compatibility
source scripts/lib/dependencies.sh
check_system_compatibility

# Run dependency checks
check_all_dependencies

# Validate installation
./tests/test-suite.sh deployment

# Debug specific issues
./scripts/debug_commands.sh
```

## License

This development deployment tooling is part of the ArcDeploy project and follows the same MIT license terms.

---

## Branch Information

This `dev-deployment` directory is part of the **enhanced ArcDeploy system** available in the `dev-deployment` branch. For the latest features including:

- 🔧 Centralized configuration management
- 📚 Shared function libraries  
- 🎨 Multi-cloud template system
- 🧪 Comprehensive testing framework
- 🌐 Enhanced multi-provider support

**Use the `dev-deployment` branch for the most advanced capabilities.**

**Important**: These development deployment tools are intended for development, testing, and educational purposes. For production deployments, consider using the enhanced cloud-init templates available in the `templates/` directory of this branch for better automation and consistency across cloud providers.