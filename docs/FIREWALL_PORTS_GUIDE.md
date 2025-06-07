# ArcDeploy Firewall and Ports Configuration Guide

## Overview

This guide covers the complete firewall and port configuration for ArcDeploy's native Blocklet Server installation. The configuration uses UFW (Uncomplicated Firewall) for host-level protection and includes comprehensive security hardening.

## Port Configuration

### External Ports (Internet Accessible)

| Port | Protocol | Service | Purpose | Required |
|------|----------|---------|---------|----------|
| 2222 | TCP | SSH | Secure Shell access | Critical |
| 8080 | TCP | Blocklet Server | HTTP web interface | Critical |
| 8443 | TCP | Blocklet Server | HTTPS web interface | Critical |
| 80 | TCP | Nginx | HTTP proxy/redirect | Important |
| 443 | TCP | Nginx | HTTPS proxy (if SSL configured) | Important |

### Internal Ports (Local Access Only)

| Port | Protocol | Service | Purpose | Access |
|------|----------|---------|---------|---------|
| 6379 | TCP | Redis | Database backend | localhost |
| 22 | TCP | SSH (disabled) | Default SSH (blocked) | None |

## UFW Firewall Configuration

### Default Policies

```bash
# Default firewall rules applied by ArcDeploy
ufw default deny incoming    # Block all incoming by default
ufw default allow outgoing   # Allow all outgoing traffic
```

### Applied Rules

```bash
# SSH Access
ufw allow 2222/tcp comment 'SSH'

# Blocklet Server Direct Access
ufw allow 8080/tcp comment 'Blocklet Server HTTP'
ufw allow 8443/tcp comment 'Blocklet Server HTTPS'

# Nginx Proxy Access
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
```

### Verification Commands

```bash
# Check firewall status
sudo ufw status verbose

# List numbered rules
sudo ufw status numbered

# Check active connections
sudo netstat -tlnp | grep -E "(2222|8080|8443|80|443)"
```

## Port Usage Details

### SSH (Port 2222)

**Purpose**: Secure administrative access
**Security Features**:
- Non-standard port to reduce automated attacks
- Key-only authentication (passwords disabled)
- Limited to `arcblock` user only
- Protected by Fail2ban intrusion prevention

**Access Command**:
```bash
ssh -p 2222 arcblock@YOUR_SERVER_IP
```

**Security Configuration**:
```
Port 2222
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers arcblock
MaxAuthTries 3
```

### Blocklet Server HTTP (Port 8080)

**Purpose**: Primary web interface for Blocklet Server
**Features**:
- Direct access to Blocklet Server
- WebSocket support for real-time features
- API endpoints and admin interface
- Protected by application-level authentication

**Access URLs**:
- Web Interface: `http://YOUR_SERVER_IP:8080`
- Admin Panel: `http://YOUR_SERVER_IP:8080/.well-known/server/admin/`
- Health Check: `http://YOUR_SERVER_IP:8080/api/health`

### Blocklet Server HTTPS (Port 8443)

**Purpose**: Secure web interface with SSL/TLS encryption
**Features**:
- Encrypted communication
- Certificate-based security
- Same functionality as HTTP version
- Preferred for production use

**Access URLs**:
- Secure Interface: `https://YOUR_SERVER_IP:8443`
- Secure Admin: `https://YOUR_SERVER_IP:8443/.well-known/server/admin/`

### Nginx HTTP Proxy (Port 80)

**Purpose**: Web server proxy and redirect
**Features**:
- Reverse proxy to Blocklet Server
- Static content serving
- HTTP to HTTPS redirects (when SSL configured)
- Load balancing capabilities

**Proxy Configuration**:
```nginx
location / {
    proxy_pass http://127.0.0.1:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

### Nginx HTTPS Proxy (Port 443)

**Purpose**: Secure web server proxy (when SSL configured)
**Features**:
- SSL/TLS termination
- Secure reverse proxy
- Certificate management
- Enhanced security headers

## Cloud Provider Firewall Configuration

### Hetzner Cloud Firewall

```bash
# Create firewall rules via Hetzner Cloud Console or API
# Inbound Rules:
- SSH: TCP/2222, Source: 0.0.0.0/0
- HTTP: TCP/80, Source: 0.0.0.0/0  
- HTTPS: TCP/443, Source: 0.0.0.0/0
- Blocklet HTTP: TCP/8080, Source: 0.0.0.0/0
- Blocklet HTTPS: TCP/8443, Source: 0.0.0.0/0

# Outbound Rules:
- All traffic: Allow (for updates and external services)
```

### AWS Security Groups

```json
{
  "SecurityGroupRules": [
    {
      "IpProtocol": "tcp",
      "FromPort": 2222,
      "ToPort": 2222,
      "CidrIp": "0.0.0.0/0",
      "Description": "SSH"
    },
    {
      "IpProtocol": "tcp", 
      "FromPort": 8080,
      "ToPort": 8080,
      "CidrIp": "0.0.0.0/0",
      "Description": "Blocklet Server HTTP"
    },
    {
      "IpProtocol": "tcp",
      "FromPort": 8443, 
      "ToPort": 8443,
      "CidrIp": "0.0.0.0/0",
      "Description": "Blocklet Server HTTPS"
    },
    {
      "IpProtocol": "tcp",
      "FromPort": 80,
      "ToPort": 80, 
      "CidrIp": "0.0.0.0/0",
      "Description": "HTTP"
    },
    {
      "IpProtocol": "tcp",
      "FromPort": 443,
      "ToPort": 443,
      "CidrIp": "0.0.0.0/0", 
      "Description": "HTTPS"
    }
  ]
}
```

### Google Cloud Platform Firewall

```bash
# Create firewall rules via gcloud CLI
gcloud compute firewall-rules create arcblock-ssh \
  --allow tcp:2222 \
  --source-ranges 0.0.0.0/0 \
  --description "SSH access"

gcloud compute firewall-rules create arcblock-web \
  --allow tcp:80,tcp:443,tcp:8080,tcp:8443 \
  --source-ranges 0.0.0.0/0 \
  --description "Web access"
```

## Fail2ban Integration

### Protected Services

```ini
[sshd]
enabled = true
port = 2222
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600

[nginx-http-auth] 
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 6

[blocklet-server]
enabled = true
port = 8080
filter = blocklet-server
logpath = /opt/blocklet-server/logs/*.log
maxretry = 5
bantime = 3600
```

### Custom Filter Patterns

```ini
# /etc/fail2ban/filter.d/blocklet-server.conf
[Definition]
failregex = ^.*\[.*\] .*Failed login attempt from <HOST>.*$
            ^.*\[.*\] .*Unauthorized access from <HOST>.*$
            ^.*\[.*\] .*Invalid authentication from <HOST>.*$
            ^.*\[.*\] .*Blocked request from <HOST>.*$
ignoreregex = ^.*\[.*\] .*Valid login from <HOST>.*$
```

## Security Best Practices

### Port Security

1. **Non-Standard Ports**: SSH on 2222 reduces automated attacks
2. **Service Isolation**: Each service on dedicated ports
3. **Minimal Exposure**: Only necessary ports open
4. **Regular Monitoring**: Log analysis for suspicious activity

### Access Control

1. **SSH Key Authentication**: No password authentication
2. **User Restrictions**: Limited to `arcblock` user
3. **Application Security**: Blocklet Server has built-in authentication
4. **Network Segmentation**: Internal services not exposed

### Monitoring and Logging

```bash
# Monitor failed connection attempts
sudo tail -f /var/log/auth.log | grep "Failed password"

# Check Fail2ban status
sudo fail2ban-client status

# Monitor nginx access logs
sudo tail -f /var/log/nginx/access.log

# Check UFW logs
sudo tail -f /var/log/ufw.log
```

## Troubleshooting Port Issues

### Connection Refused

```bash
# Check if service is running
sudo systemctl status blocklet-server
sudo systemctl status nginx

# Verify ports are listening
sudo netstat -tlnp | grep -E "(8080|2222|80|443)"

# Test local connectivity
curl -I http://localhost:8080
```

### Firewall Blocking

```bash
# Check UFW status
sudo ufw status verbose

# Temporarily disable UFW for testing (NOT recommended for production)
sudo ufw disable

# Check iptables rules
sudo iptables -L -n

# Reset UFW rules if needed
sudo ufw --force reset
```

### DNS and Routing Issues

```bash
# Test external connectivity
curl -I http://YOUR_SERVER_IP:8080

# Check DNS resolution
nslookup YOUR_DOMAIN

# Verify routing
traceroute YOUR_SERVER_IP
```

## Advanced Configuration

### Custom Port Configuration

To change default ports, modify these files:

1. **Blocklet Server Port**: Edit systemd service environment variables
2. **Nginx Ports**: Modify `/etc/nginx/sites-available/blocklet-server`
3. **UFW Rules**: Update firewall rules accordingly
4. **Fail2ban**: Update port configurations in jail files

### SSL/TLS Configuration

```nginx
server {
    listen 443 ssl http2;
    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;
    
    location / {
        proxy_pass https://127.0.0.1:8443;
        proxy_ssl_verify off;
    }
}
```

### Load Balancing

```nginx
upstream blocklet_servers {
    server 127.0.0.1:8080;
    server 127.0.0.1:8081;  # Additional instances
}

server {
    location / {
        proxy_pass http://blocklet_servers;
    }
}
```

## Maintenance Commands

### Regular Checks

```bash
# Weekly firewall audit
sudo ufw status numbered > /var/log/ufw-audit-$(date +%Y%m%d).log

# Monthly port scan from external source
nmap -p 22,80,443,2222,8080,8443 YOUR_SERVER_IP

# Daily log review
sudo grep "DENY" /var/log/ufw.log | tail -20
```

### Emergency Procedures

```bash
# Emergency firewall disable (use with caution)
sudo ufw disable

# Reset all firewall rules
sudo ufw --force reset

# Emergency SSH access via cloud console if locked out
# Access via cloud provider's web console/VNC
```

## Conclusion

ArcDeploy's firewall configuration provides robust security while maintaining accessibility for legitimate users. The multi-layered approach combining UFW, Fail2ban, and application-level security ensures comprehensive protection against various attack vectors.

Regular monitoring and maintenance of firewall rules are essential for maintaining security posture. Always test changes in a development environment before applying to production systems.