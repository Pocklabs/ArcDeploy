# ArcDeploy Implementation Details

## Overview

ArcDeploy provides a streamlined, native installation approach for deploying Arcblock Blocklet Server on cloud infrastructure. This document details the technical implementation, architectural decisions, and production-ready features that make ArcDeploy reliable and secure.

## Architecture

### Native Installation Approach

ArcDeploy uses a native installation strategy that installs Blocklet Server directly on the host system without containers. This approach provides:

- **Maximum Performance**: No container overhead or virtualization layers
- **Direct System Integration**: Native systemd service management
- **Simplified Debugging**: Direct access to logs and processes
- **Better Resource Utilization**: Full access to system resources
- **Easier Maintenance**: Standard Linux package management

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                    ArcDeploy Stack                          │
├─────────────────────────────────────────────────────────────┤
│  Nginx (Reverse Proxy)     │  UFW (Firewall)               │
│  Port 80/443 → 8080/8443   │  Ports: 2222, 8080, 8443     │
├─────────────────────────────────────────────────────────────┤
│  Blocklet Server (Native)   │  Redis (Database)            │
│  Node.js + @blocklet/cli    │  Session & Cache Storage     │
│  Ports: 8080 (HTTP)        │  Port: 6379 (local)          │
│         8443 (HTTPS)        │                               │
├─────────────────────────────────────────────────────────────┤
│  SSH Hardening              │  Fail2ban (IPS)              │
│  Port 2222, Key-only Auth   │  SSH & HTTP Protection       │
├─────────────────────────────────────────────────────────────┤
│                Ubuntu 22.04 LTS Base System                 │
└─────────────────────────────────────────────────────────────┘
```

## Technical Implementation

### Cloud-Init Configuration

ArcDeploy uses a single `cloud-init.yaml` file that orchestrates the entire deployment:

#### User Management
```yaml
users:
  - name: arcblock
    groups: users, admin, sudo
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - [USER_SSH_PUBLIC_KEY]
```

#### Service Configuration
```yaml
write_files:
  - path: /etc/systemd/system/blocklet-server.service
    content: |
      [Unit]
      Description=Arcblock Blocklet Server
      After=network-online.target redis.service
      
      [Service]
      Type=simple
      User=arcblock
      Environment=BLOCKLET_PORT=8080
      ExecStart=/usr/local/bin/blocklet server start
```

### Package Management

#### Node.js Installation
- **Source**: NodeSource repository (official Node.js packages)
- **Version**: Latest LTS release
- **Installation**: Direct package manager integration
- **Benefits**: Automatic security updates, system integration

#### Blocklet CLI Installation
```bash
npm install -g @blocklet/cli
```
- **Package**: `@blocklet/cli` (current, maintained package)
- **Scope**: Global installation for system-wide access
- **Verification**: Post-installation PATH validation

### Security Implementation

#### SSH Hardening
```
Port 2222                        # Non-standard port
Protocol 2                       # Secure protocol only
PermitRootLogin no              # No root access
PasswordAuthentication no       # Key-only authentication
PubkeyAuthentication yes        # Enable key auth
MaxAuthTries 3                  # Limit login attempts
AllowUsers arcblock             # Restrict user access
```

#### Firewall Configuration (UFW)
```
Default: DENY incoming, ALLOW outgoing
Allowed Ports:
  - 2222/tcp  (SSH)
  - 8080/tcp  (Blocklet Server HTTP)
  - 8443/tcp  (Blocklet Server HTTPS)
  - 80/tcp    (Nginx HTTP)
  - 443/tcp   (Nginx HTTPS)
```

#### Intrusion Prevention (Fail2ban)
```ini
[sshd]
enabled = true
port = 2222
bantime = 3600
maxretry = 5

[blocklet-server]
enabled = true
port = 8080
logpath = /opt/blocklet-server/logs/*.log
maxretry = 5
```

### Network Configuration

#### Nginx Reverse Proxy
```nginx
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### Port Strategy
- **8080**: Blocklet Server HTTP (internal)
- **8443**: Blocklet Server HTTPS (internal)
- **80**: Nginx HTTP proxy (external)
- **443**: Nginx HTTPS proxy (external)
- **2222**: SSH access (external)

### Monitoring and Health Checks

#### Health Check Script
```bash
#!/bin/bash
# Location: /opt/blocklet-server/healthcheck.sh

# Service status check
systemctl is-active --quiet blocklet-server

# HTTP endpoint validation
curl -sf --max-time 10 http://localhost:8080 >/dev/null

# Resource monitoring
DISK_USAGE=$(df /opt/blocklet-server | awk 'NR==2 {print $(NF-1)}')
MEM_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
```

#### Automated Monitoring
- **Cron Schedule**: Every 5 minutes
- **Health Checks**: Service status, HTTP endpoints, resource usage
- **Logging**: Comprehensive health check logs
- **Auto-Recovery**: Service restart on failure

### Error Handling and Recovery

#### Installation Validation
```bash
# Package installation verification
npm install -g @blocklet/cli || { echo "Failed to install CLI"; exit 1; }
which blocklet || { echo "CLI not found in PATH"; exit 1; }

# Service startup verification
systemctl start blocklet-server
systemctl is-active --quiet blocklet-server || restart_service
```

#### Graceful Degradation
- **Service Failures**: Automatic restart with exponential backoff
- **Network Issues**: Retry mechanisms for external dependencies
- **Resource Exhaustion**: Warning thresholds and cleanup procedures

## Deployment Process

### Phase 1: System Preparation (60-90 seconds)
1. Package repository updates
2. System package installation
3. User account creation
4. Directory structure setup

### Phase 2: Service Installation (90-120 seconds)
1. Node.js repository addition and installation
2. Blocklet CLI global installation
3. Redis database setup
4. Nginx web server configuration

### Phase 3: Security Hardening (30-60 seconds)
1. SSH configuration hardening
2. UFW firewall setup
3. Fail2ban intrusion prevention
4. System limits optimization

### Phase 4: Service Initialization (60-180 seconds)
1. Blocklet Server initialization
2. Configuration file setup
3. Systemd service registration
4. Service startup and verification

### Phase 5: Health Verification (30-60 seconds)
1. Service status validation
2. HTTP endpoint testing
3. Health monitoring setup
4. Final system cleanup

**Total Deployment Time**: 4-8 minutes (depending on server specs and network)

## Performance Characteristics

### Resource Requirements
- **Minimum**: 4 cores, 8GB RAM, 80GB SSD
- **Recommended**: 8 cores, 16GB RAM, 160GB SSD
- **Network**: 1Gbps+ connection recommended
- **Storage**: SSD required for optimal performance

### Performance Optimizations
- **Native Execution**: No container overhead
- **SSD Storage**: Fast I/O for database and logs
- **Nginx Caching**: Static content optimization
- **Redis Memory Store**: Fast session management
- **System Tuning**: Optimized network and file limits

## Security Features

### Multi-Layer Security
1. **Network Level**: UFW firewall with minimal attack surface
2. **Application Level**: Nginx reverse proxy with security headers
3. **System Level**: SSH hardening and non-root execution
4. **Monitoring Level**: Fail2ban intrusion detection

### Security Best Practices
- **Principle of Least Privilege**: Services run as non-root user
- **Defense in Depth**: Multiple security layers
- **Automatic Updates**: Security patches via package manager
- **Audit Logging**: Comprehensive security event logging

## Maintenance and Operations

### Log Management
```
/opt/blocklet-server/logs/     # Application logs
/var/log/nginx/                # Web server logs
/var/log/auth.log              # SSH authentication logs
/var/log/fail2ban.log          # Intrusion prevention logs
```

### Backup Strategy
- **Configuration**: `/opt/blocklet-server/config/`
- **Data**: `/opt/blocklet-server/data/`
- **Health Logs**: `/opt/blocklet-server/logs/`
- **System Config**: SSH keys, certificates, service files

### Update Procedures
1. **System Updates**: `apt update && apt upgrade`
2. **Blocklet Updates**: `npm update -g @blocklet/cli`
3. **Service Restart**: `systemctl restart blocklet-server`
4. **Health Verification**: Run health check script

## Troubleshooting

### Common Issues and Solutions

#### Service Won't Start
```bash
# Check service status
systemctl status blocklet-server

# Check logs
journalctl -u blocklet-server -f

# Verify CLI installation
which blocklet && blocklet --version
```

#### Network Connectivity Issues
```bash
# Test internal endpoints
curl -I http://localhost:8080

# Check port listening
netstat -tlnp | grep -E "(8080|2222)"

# Verify firewall rules
ufw status verbose
```

#### Performance Issues
```bash
# Check resource usage
top -u arcblock
df -h /opt/blocklet-server
free -h

# Review logs for errors
tail -f /opt/blocklet-server/logs/*.log
```

## Future Considerations

### Scalability Options
- **Horizontal Scaling**: Multiple server deployment
- **Load Balancing**: Nginx upstream configuration
- **Database Clustering**: Redis cluster setup
- **CDN Integration**: Static content distribution

### Security Enhancements
- **SSL/TLS Automation**: Let's Encrypt integration
- **Advanced Monitoring**: Centralized log aggregation
- **Compliance**: Security audit and hardening guides
- **Access Control**: Role-based access management

## Conclusion

ArcDeploy's native installation approach provides a robust, secure, and performant foundation for Blocklet Server deployment. The implementation prioritizes reliability, security, and maintainability while providing comprehensive monitoring and recovery capabilities.

The architecture supports both development and production environments, with clear upgrade paths and operational procedures. The single cloud-init configuration approach simplifies deployment while maintaining enterprise-grade security and monitoring features.