# ArcDeploy Enhanced Features Documentation

## Overview

ArcDeploy Enhanced provides improved deployment capabilities, security hardening, and better error handling based on the latest Hetzner Cloud API best practices and modern cloud-init configurations.

## 🚀 What's New in Enhanced Version

### Enhanced Deployment Script (`scripts/deploy-test-server-enhanced.sh`)

#### Key Improvements

| Feature | Standard Version | Enhanced Version |
|---------|------------------|------------------|
| **API Error Handling** | Basic error checking | Retry logic with exponential backoff |
| **Rate Limiting** | No handling | Automatic retry on 429 errors |
| **Server Validation** | Manual type checking | API-based validation against current offerings |
| **Cloud-Init Validation** | File existence check | Size, format, and YAML syntax validation |
| **Progress Monitoring** | Basic status checks | Real-time progress with timeout handling |
| **SSH Testing** | Manual connection | Automated connectivity testing |
| **Dry Run Mode** | Not available | Preview changes without execution |
| **Verbose Logging** | Basic output | Detailed debug information |

#### New Command-Line Options

```bash
# Enhanced deployment with options
./scripts/deploy-test-server-enhanced.sh [OPTIONS] <server_name> [server_type] [location]

# New options available:
--verbose           # Enable detailed logging
--dry-run          # Preview without executing
--delete <name>    # Delete server with confirmation
--list             # Show all ArcDeploy servers
--status <name>    # Detailed server information
--help             # Comprehensive help system
```

#### Advanced Server Type Mapping

```bash
# Friendly names map to specific server types
small      → cx11  # 1 vCPU, 4GB RAM  (€4.15/month)
medium     → cx21  # 2 vCPU, 8GB RAM  (€8.25/month)
standard   → cx31  # 2 vCPU, 8GB RAM  (€13.10/month) [RECOMMENDED]
large      → cx41  # 4 vCPU, 16GB RAM (€26.20/month)
xlarge     → cx51  # 8 vCPU, 32GB RAM (€52.40/month)
```

### Enhanced Cloud-Init Configuration (`cloud-init-enhanced.yaml`)

#### Security Hardening

- **SSH Configuration**: Modern cipher suites, key-only authentication
- **Fail2ban Protection**: Advanced rules for SSH, Nginx, and application layers
- **Firewall Rules**: UFW with logging and rate limiting
- **System Limits**: Optimized file descriptors and process limits
- **Kernel Tuning**: Network performance and security parameters

#### Monitoring & Maintenance

- **Health Checks**: Comprehensive system and application monitoring
- **Log Rotation**: Automatic log management to prevent disk space issues
- **Automated Maintenance**: Weekly security updates and system cleanup
- **Resource Monitoring**: Disk, memory, and network usage tracking

#### Application Enhancements

- **Nginx Security Headers**: XSS protection, HSTS, content type validation
- **Rate Limiting**: API endpoint protection and DDoS mitigation
- **Service Hardening**: Systemd security features and sandboxing
- **Backup Preparation**: Directory structure for automated backups

## 📊 Performance Improvements

### API Call Enhancements

```bash
# Enhanced retry mechanism
api_call_with_retry() {
    # Handles rate limits (429)
    # Retries on server errors (5xx)
    # Exponential backoff with jitter
    # Detailed error reporting
}
```

### Validation System

```bash
# Comprehensive validation pipeline
validate_cloud_init()    # Size and syntax checking
validate_server_type()   # API-based type validation
validate_location()      # Real-time location availability
check_server_name()      # Uniqueness verification
```

### Health Monitoring

```bash
# Advanced health checking
/opt/blocklet-server/healthcheck.sh
- Service status monitoring
- Resource usage tracking
- Network connectivity testing
- Automatic service recovery
```

## 🔧 Usage Examples

### Basic Enhanced Deployment

```bash
# Simple deployment with enhanced features
./scripts/deploy-test-server-enhanced.sh my-server

# Preview deployment without execution
./scripts/deploy-test-server-enhanced.sh --dry-run my-server large ash

# Verbose deployment for troubleshooting
./scripts/deploy-test-server-enhanced.sh --verbose my-server standard
```

### Server Management

```bash
# List all ArcDeploy servers
./scripts/deploy-test-server-enhanced.sh --list

# Check specific server status
./scripts/deploy-test-server-enhanced.sh --status my-server

# Delete server with confirmation
./scripts/deploy-test-server-enhanced.sh --delete my-server
```

### Environment Configuration

```bash
# Required environment variables
export HETZNER_TOKEN="your-hetzner-cloud-api-token"

# Optional SSH key configuration
export ARCDEPLOY_SSH_KEY="your-ssh-key-name"
```

## 🛡️ Security Features

### SSH Hardening

```yaml
# Enhanced SSH configuration
Port 2222                    # Non-standard port
PermitRootLogin no          # Root access disabled
PasswordAuthentication no    # Key-only authentication
MaxAuthTries 3              # Brute force protection
Modern cipher suites        # ChaCha20, AES-GCM
```

### Network Security

```yaml
# Fail2ban configuration
SSH protection:     3 attempts → 2 hour ban
HTTP auth:         6 attempts → 1 hour ban
DDoS protection:   200 req/min → 10 min ban
Application:       5 attempts → 1 hour ban
```

### System Hardening

```yaml
# Kernel security parameters
IP forwarding disabled
Source routing blocked
ICMP redirects ignored
Martian packet logging
TCP SYN cookies enabled
```

## 📈 Monitoring & Alerting

### Health Check System

```bash
# Automated health monitoring
Service status:     Every 5 minutes
Resource usage:     Disk, memory, network
Application health: HTTP endpoint testing
Network connectivity: External ping tests
```

### Log Management

```bash
# Centralized logging
Application logs:   /opt/blocklet-server/logs/
Health check logs:  /opt/blocklet-server/logs/health.log
System logs:        journalctl -u blocklet-server
Security logs:      /var/log/fail2ban.log
```

### Maintenance Automation

```bash
# Weekly maintenance (Sundays 2 AM)
Package updates:    Security patches applied
Log rotation:       Prevents disk space issues
Health checks:      System verification
Security scans:     Rootkit detection
```

## 🔄 Migration Guide

### From Standard to Enhanced

1. **Backup Current Configuration**
   ```bash
   # Export current server list
   ./scripts/deploy-test-server.sh --list > servers-backup.txt
   ```

2. **Test Enhanced Script**
   ```bash
   # Use dry-run mode first
   ./scripts/deploy-test-server-enhanced.sh --dry-run test-server
   ```

3. **Deploy New Servers**
   ```bash
   # Create new servers with enhanced configuration
   ./scripts/deploy-test-server-enhanced.sh production-server large
   ```

4. **Update Existing Servers** (Optional)
   ```bash
   # Manually apply cloud-init-enhanced.yaml to existing servers
   # or redeploy with enhanced configuration
   ```

### Configuration Files

```bash
# File structure comparison
Standard Version:
├── cloud-init.yaml                 # Basic configuration
├── scripts/deploy-test-server.sh   # Standard deployment

Enhanced Version:
├── cloud-init.yaml                 # Original (unchanged)
├── cloud-init-enhanced.yaml        # Enhanced configuration
├── scripts/deploy-test-server.sh   # Original (unchanged)
├── scripts/deploy-test-server-enhanced.sh  # Enhanced deployment
└── docs/enhanced-features.md       # This documentation
```

## 🐛 Troubleshooting

### Common Issues

#### API Rate Limiting
```bash
# Enhanced script automatically handles rate limits
# Look for these messages in verbose mode:
Rate limit exceeded, retrying in X seconds...
```

#### Server Creation Failures
```bash
# Enhanced validation catches issues early:
Server type 'invalid' not available
Cloud-init file too large: X bytes (max: 65536)
Location 'xyz' not available
```

#### SSH Connection Issues
```bash
# Enhanced script tests SSH automatically:
SSH connection successful!
# OR
SSH connection test failed, but server may still be initializing
Try connecting manually: ssh -p 2222 arcblock@X.X.X.X
```

### Debug Mode

```bash
# Enable maximum verbosity
./scripts/deploy-test-server-enhanced.sh --verbose --dry-run my-server
```

### Health Check Debugging

```bash
# Manual health check execution
ssh -p 2222 arcblock@YOUR_SERVER_IP
sudo /opt/blocklet-server/healthcheck.sh

# View health check logs
tail -f /opt/blocklet-server/logs/health.log
```

## 📚 API Reference

### Enhanced API Features

#### Retry Logic
- **Rate Limit Handling**: Automatic retry with exponential backoff
- **Server Error Recovery**: Retry on 5xx HTTP status codes
- **Network Error Handling**: Retry on connection timeouts
- **Maximum Attempts**: Configurable retry limit (default: 3)

#### Validation Pipeline
- **Server Type Validation**: Real-time API checking
- **Location Validation**: Current availability verification
- **Cloud-Init Validation**: Size and format checking
- **Name Uniqueness**: Conflict prevention

#### Monitoring Integration
- **Progress Tracking**: Real-time deployment status
- **Health Verification**: Automated service testing
- **Resource Monitoring**: System resource checking
- **Error Recovery**: Automatic restart capabilities

## 🏆 Best Practices

### Deployment Workflow

1. **Pre-Deployment**
   ```bash
   # Validate environment
   ./scripts/deploy-test-server-enhanced.sh --help
   
   # Test with dry-run
   ./scripts/deploy-test-server-enhanced.sh --dry-run test-server
   ```

2. **Deployment**
   ```bash
   # Deploy with monitoring
   ./scripts/deploy-test-server-enhanced.sh --verbose production-server large ash
   ```

3. **Post-Deployment**
   ```bash
   # Verify deployment
   ./scripts/deploy-test-server-enhanced.sh --status production-server
   
   # Test application
   curl http://YOUR_SERVER_IP:8080
   ```

### Security Recommendations

1. **Change Default Password**: First login requires password change
2. **Configure SSH Keys**: Add your public keys to cloud-init
3. **Review Firewall Rules**: Customize UFW rules for your needs
4. **Enable Monitoring**: Set up external monitoring for production
5. **Regular Updates**: Use automated maintenance or manual updates

### Performance Optimization

1. **Server Sizing**: Use `standard` (cx31) for most workloads
2. **Location Selection**: Choose closest datacenter to users
3. **Resource Monitoring**: Watch disk and memory usage
4. **Log Management**: Regular log rotation and cleanup
5. **Health Checks**: Monitor application and system health

## 📞 Support

### Getting Help

- **Documentation**: `/docs/` directory for comprehensive guides
- **Script Help**: `--help` option for command-line reference
- **Health Checks**: Built-in system diagnostics
- **Log Analysis**: Centralized logging for troubleshooting

### Reporting Issues

When reporting issues, include:
- Command used (with `--verbose` output)
- Server configuration details
- Health check logs
- System logs (`journalctl -u blocklet-server`)

---

**ArcDeploy Enhanced** - Taking your cloud deployments to the next level! 🚀