# Changelog

All notable changes to the ArcDeploy project are documented in this file.

## [4.0.0] - 2025-06-07

### 🚀 Major Project Restructuring

#### Complete Project Simplification
- **BREAKING**: Removed all deployment methods except native installation
- **BREAKING**: Deleted `full-featured.yaml`, `minimal.yaml`, `standard.yaml`, `standard-docker.yaml`
- **BREAKING**: Renamed `cloud-init/native-install.yaml` to `cloud-init.yaml` in root directory
- **BREAKING**: Removed entire `cloud-init/` subdirectory for simplified structure
- Focused project on single, proven working approach for better maintainability

#### Security Cleanup and Key Management
- **SECURITY**: Complete removal of exposed SSH keys from entire git history
- **SECURITY**: Removed all instances of `pocklabs@pocklabs.com` from repository history
- Used `git-filter-repo` to rewrite complete git history and remove sensitive data
- Standardized all SSH key placeholders to `your-email@example.com` format
- Added `Log.md` to `.gitignore` to prevent accidental commit of debug logs

#### Documentation Overhaul
- **BREAKING**: Complete rewrite of README.md to focus on native installation only
- **BREAKING**: Updated QUICK_START.md to streamlined 10-minute deployment guide
- Removed confusion from multiple deployment options
- Added prominent Work In Progress notice with current project status
- Enhanced documentation clarity with single deployment path

#### Server Requirements Expansion
- **BREAKING**: Increased minimum requirements to 4 vCPUs, 8GB RAM, 80GB storage
- **BREAKING**: Increased recommended requirements to 8 vCPUs, 16GB RAM, 160GB storage
- Made requirements cloud-agnostic, supporting any hosting provider
- Added comprehensive list of compatible cloud providers (AWS, GCP, Azure, DigitalOcean, etc.)
- Included self-hosted and bare metal deployment options
- Removed Hetzner-specific focus for universal compatibility

### 🔧 Project Structure Improvements

#### Simplified Architecture
- Single `cloud-init.yaml` configuration file in root directory
- Eliminated decision paralysis with multiple configuration options
- Focused testing and development efforts on proven working solution
- Streamlined maintenance with single deployment path

#### Enhanced Cloud Provider Support
- Universal compatibility with any Ubuntu 22.04 + cloud-init provider
- Support for major clouds: AWS, Google Cloud, Azure, DigitalOcean, Linode, Vultr
- Specialized provider support: Scaleway, UpCloud, Contabo, Time4VPS
- Self-hosted options: Proxmox, VMware, OpenStack, KVM/QEMU

#### File Organization
- Moved primary configuration to root level for easier access
- Preserved `scripts/` and `docs/` directories
- Maintained clean project structure with focused purpose
- Added comprehensive `.gitignore` for debug files

### 📊 Quality and Security Improvements

#### Git History Cleanup
- Complete removal of sensitive data from all commits
- Rewritten git history with no exposed credentials
- Sanitized commit diffs and merge history
- Force-pushed clean history to remote repository

#### Documentation Quality
- Clear deployment instructions with exact commands
- Streamlined quick start guide for 10-minute deployment
- Comprehensive troubleshooting section
- Universal provider compatibility documentation

#### Resource Planning
- More generous resource allocations for reliable performance
- Future-proof specifications for scaling
- Clear bandwidth and network requirements
- SSD storage requirements for optimal performance

### ⚠️ Breaking Changes

1. **Project Structure**: Only `cloud-init.yaml` remains, all other configurations removed
2. **File Location**: Configuration moved from `cloud-init/native-install.yaml` to `cloud-init.yaml`
3. **Server Requirements**: Doubled minimum requirements for better performance
4. **Provider Focus**: No longer Hetzner-specific, universal cloud provider support
5. **Git History**: Complete history rewrite removes all previous commits with sensitive data

### 🔄 Migration Notes

#### Repository Updates
1. **File Location**: Update references from `cloud-init/native-install.yaml` to `cloud-init.yaml`
2. **Documentation**: All deployment guides now reference single configuration file
3. **Server Specs**: Review server specifications against new minimum requirements
4. **Provider Choice**: Expand deployment options beyond Hetzner Cloud

#### Compatibility
- Fully compatible with existing Blocklet Server installations
- Enhanced reliability with focused development approach
- Better resource allocation for improved performance
- Universal cloud provider compatibility

## [3.0.0] - 2025-06-15

### 🚀 Major Cloud-Init Refactoring

#### YAML Structure Overhaul
- **BREAKING**: Completely refactored all cloud-init YAML files for improved reliability
- **BREAKING**: Removed problematic `error_exit()` function that didn't persist between runcmd entries
- **BREAKING**: Moved complex bash scripts from inline runcmd to separate write_files entries
- Fixed cloud-init parsing issues with multi-line scripts and here-documents
- Simplified command structure to avoid YAML parsing failures
- Enhanced error handling with proper command chaining using `||` operators

#### Enhanced File Management
- **NEW**: SSH configuration moved to dedicated temporary files to avoid parsing issues
- **NEW**: System limits and sysctl configurations externalized to separate files
- **NEW**: All complex configurations now use write_files instead of inline here-documents
- Added proper cleanup of temporary files after installation
- Improved file ownership and permissions management

#### Repository and Documentation Updates
- **BREAKING**: Repository name standardized to `ArcDeploy`
- **BREAKING**: Updated all references from placeholder repository names to correct naming
- Fixed SSH key templates to use proper placeholder format
- Updated final_message sections to use `YOUR_SERVER_IP` instead of problematic variables
- Enhanced support URLs to point to correct repository location

### 🔧 Cloud-Init Reliability Improvements

#### Script Execution Reliability
- **full-featured.yaml**: Removed 580+ line complex inline scripts, moved to modular approach
- **standard.yaml**: Separated large setup script into dedicated file with proper error handling
- **minimal.yaml**: Made completely self-contained, no longer relies on external scripts
- **native-install.yaml**: Fixed truncated runcmd section and completed installation process
- **standard-docker.yaml**: Improved Docker configuration management and SSH setup

#### Error Handling Enhancement
- Replaced complex error functions with simple command chaining
- Added proper status checking and service verification
- Enhanced logging and completion markers for better debugging
- Improved service startup verification with timeout handling

#### Template Standardization
- **BREAKING**: All SSH keys now use template format: `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIReplaceWithYourActualEd25519PublicKey your-email@example.com`
- Standardized placeholder format across all configuration files
- Updated repository references to use `ArcDeploy` consistently
- Fixed support URLs to point to correct GitHub repository

### 📊 Validation and Testing

#### YAML Syntax Validation
- **NEW**: All YAML files now pass comprehensive syntax validation
- **NEW**: Added Python YAML parser validation for all configuration files
- Fixed indentation and structure issues that caused cloud-init failures
- Enhanced compatibility with cloud-init parsers across different platforms

#### Installation Process Verification
- Added completion markers for tracking installation progress
- Enhanced service startup verification with proper timeout handling
- Improved health check reliability and error reporting
- Added proper cleanup verification and system state validation

### 🛠️ Configuration Management Improvements

#### SSH Security Enhancement
- Moved SSH configuration to external files to prevent parsing issues
- Enhanced SSH hardening with comprehensive security parameters
- Improved SSH service restart reliability
- Standardized SSH configuration across all deployment types

#### System Configuration Optimization
- Externalized sysctl and limits configurations for better maintainability
- Enhanced system performance tuning parameters
- Improved container networking configuration
- Added proper security hardening parameters

#### Service Management Enhancement
- Improved systemd service configuration reliability
- Enhanced service dependency management
- Added proper environment variable handling
- Improved service startup and health check processes

### 📝 Documentation and Support

#### Repository Standardization
- **BREAKING**: All references updated to use `ArcDeploy` repository name
- Updated support URLs to point to correct GitHub location
- Enhanced README references and documentation links
- Standardized project naming convention throughout all files

#### Enhanced User Guidance
- Updated final_message sections with clearer instructions
- Improved troubleshooting guidance and command references
- Enhanced access information with proper placeholder usage
- Added comprehensive feature listing in completion messages

### ⚠️ Breaking Changes

1. **Repository Name**: Repository must be renamed to `ArcDeploy`
2. **YAML Structure**: Major refactoring means existing custom modifications may need updating
3. **SSH Key Format**: All SSH keys must use the new template format
4. **Script Dependencies**: Removed external script dependencies, everything is now self-contained
5. **Error Handling**: Custom error functions removed, replaced with standard command chaining

### 🔄 Migration Notes

#### Repository Migration
1. **GitHub**: Rename repository to `ArcDeploy` in repository settings
2. **Local Clone**: Update remote URL: `git remote set-url origin https://github.com/YourUsername/ArcDeploy.git`
3. **Documentation**: Update any external references to use new repository name

#### Configuration Updates
1. **SSH Keys**: Replace SSH keys using new template format
2. **Custom Scripts**: Review any custom modifications for compatibility with new structure
3. **Monitoring**: New completion markers and health checks may require script updates

#### Compatibility
- Fully compatible with existing Blocklet Server installations
- Backward compatible with data and configuration from previous versions
- Enhanced reliability for new deployments across all cloud platforms

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