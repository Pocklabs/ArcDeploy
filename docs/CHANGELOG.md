# Changelog

All notable changes to the Arcblock Blocklet Server cloud-init configuration are documented in this file.

## [2.0.0] - 2024-01-15

### 🚀 Major Improvements

#### Enhanced Container Management
- **BREAKING**: Replaced `podman-compose` with native `podman compose` for better reliability
- **BREAKING**: Updated compose file from `docker-compose.yml` to `compose.yaml` (modern standard)
- Added comprehensive container healthchecks with retry logic
- Implemented proper container volume management with explicit drivers
- Added container auto-update functionality with systemd timers
- Enhanced container logging and monitoring capabilities

#### Production-Ready Service Configuration
- **BREAKING**: Systemd service now uses `Type=exec` instead of `Type=forking` for better process management
- Added proper service dependencies with `network-online.target`
- Implemented graceful shutdown with configurable timeouts
- Added service restart policies with exponential backoff
- Enhanced service monitoring with health check integration

#### Security Hardening
- **BREAKING**: Removed default SSH port 22, now exclusively uses port 2222
- Enhanced SSH configuration with additional security parameters
- Added Protocol 2 enforcement and client timeout configurations
- Improved fail2ban configuration with better regex patterns and timeouts
- Enhanced firewall rules with explicit port comments and reset mechanism
- Added network security parameters via sysctl

#### Robust Error Handling
- Added comprehensive error handling throughout cloud-init script
- Implemented `error_exit()` function for consistent error reporting
- Added validation checks for critical operations
- Enhanced logging with proper error capture and reporting

#### Monitoring and Maintenance
- **NEW**: Comprehensive health check script with multiple validation points
- **NEW**: Automated backup script with retention policies
- **NEW**: Enhanced monitoring with disk space, memory, and service health checks
- Updated cron jobs for regular health checks and weekly backups
- Added log rotation with service reload integration

### 🔧 Technical Improvements

#### Node.js Installation
- **BREAKING**: Replaced NVM with NodeSource repository for production stability
- Ensures consistent Node.js version across deployments
- Better integration with system package management
- Improved reliability for automated installations

#### Podman Configuration
- Enhanced rootless container setup with proper subuid/subgid configuration
- Improved container registry configuration with security policies
- Added dedicated storage configuration for better performance
- Enhanced socket management with proper user lingering

#### Directory Structure
- Organized directory structure with proper permissions
- Added dedicated backup directory
- Enhanced configuration directory layout
- Improved log directory management

#### System Optimization
- Enhanced system limits configuration for better performance
- Improved network tuning parameters
- Added security-focused sysctl parameters
- Optimized container storage configuration

### 📊 Enhanced Validation

#### Comprehensive Testing
- **NEW**: 16 validation test categories covering all system aspects
- Enhanced validation script with detailed reporting and color coding
- Added pass/fail/warning counters for better overview
- Comprehensive system information reporting
- Enhanced troubleshooting command suggestions

#### Detailed Health Monitoring
- Real-time container health monitoring
- HTTP endpoint validation
- Resource usage monitoring (CPU, memory, disk)
- Service dependency validation
- Security configuration verification

### 🛠️ Configuration Updates

#### Compose Configuration
- Updated to compose spec v3.8 for better compatibility
- Added proper volume definitions with explicit drivers
- Enhanced environment variable configuration
- Added container labels for auto-update support
- Implemented health check configuration

#### Service Files
- Enhanced systemd service configuration with better resource management
- Added proper environment variable handling
- Improved service dependencies and ordering
- Enhanced restart and timeout configurations

#### Security Configuration
- Updated fail2ban configuration with improved filters
- Enhanced SSH hardening with additional security parameters
- Improved firewall configuration with explicit rules
- Added security-focused system parameter tuning

### 📝 Documentation

#### Enhanced README
- Updated with comprehensive Podman-specific instructions
- Added detailed troubleshooting sections
- Enhanced security considerations
- Added performance optimization guidelines
- Comprehensive command reference

#### New Scripts
- Health check script for automated monitoring
- Backup script for data protection
- Enhanced validation script for deployment verification

### ⚠️ Breaking Changes

1. **SSH Configuration**: Only port 2222 is now available for SSH (port 22 is completely disabled)
2. **Container Tool**: Replaced `podman-compose` with native `podman compose`
3. **Compose File**: Renamed from `docker-compose.yml` to `compose.yaml`
4. **Node.js Installation**: Changed from NVM to NodeSource repository
5. **Service Type**: Systemd service changed from `forking` to `exec` type

### 🔄 Migration Notes

#### From Version 1.x
1. **SSH Access**: Update your SSH configuration to use port 2222 exclusively
2. **Container Management**: Use `podman compose` instead of `podman-compose`
3. **Service Management**: Service restart behavior may differ due to type change
4. **Monitoring**: New health check and backup scripts are automatically configured

#### Compatibility
- Fully compatible with Hetzner Cloud infrastructure
- Supports Ubuntu 22.04 LTS
- Compatible with CX31+ server configurations
- Backward compatible with existing Blocklet Server data

## [1.0.0] - 2024-01-01

### Initial Release

#### Core Features
- Basic Podman-based Blocklet Server setup
- SSH key authentication
- UFW firewall configuration
- Basic fail2ban protection
- Simple monitoring script
- Docker-compose based container management

#### Security
- SSH hardening with key-only authentication
- Basic firewall rules
- Root login disabled
- Non-root user creation

#### Container Support
- Podman installation and configuration
- Basic rootless container support
- Simple container management

#### Monitoring
- Basic service monitoring
- Simple log rotation
- Cron-based health checks

---

### Legend
- 🚀 Major new features
- 🔧 Technical improvements
- 📊 Monitoring and validation
- 🛠️ Configuration changes
- 📝 Documentation updates
- ⚠️ Breaking changes
- 🔄 Migration information