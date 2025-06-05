# Firewall and Ports Reference Guide

## Overview

This guide covers all firewall and port configurations needed for Arcblock Blocklet Server deployment on Hetzner Cloud. You need to configure **two firewall layers**: Hetzner Cloud's network firewall and the server's UFW firewall.

## Port Requirements Summary

| Port | Protocol | Purpose | Required | Notes |
|------|----------|---------|----------|-------|
| **2222** | TCP | SSH Access | **Critical** | Changed from default 22 for security |
| **8089** | TCP | Blocklet Server Main Interface | **Critical** | Primary application port |
| **80** | TCP | HTTP Traffic | **Important** | Redirects to 8089 |
| **443** | TCP | HTTPS Traffic | **Important** | For SSL/TLS when configured |

## Hetzner Cloud Firewall Configuration

### Quick Setup (Recommended)

#### 1. Using the Automated Script
```bash
# Set your API token
export HETZNER_API_TOKEN="your-hetzner-api-token"

# Open access (production ready)
./hetzner-firewall-setup.sh your-server-name

# Restrictive SSH access (your IP only)
./hetzner-firewall-setup.sh your-server-name restrictive

# List available servers
./hetzner-firewall-setup.sh list

# Check firewall status
./hetzner-firewall-setup.sh status
```

#### 2. Manual Setup via Hetzner Console

**Step 1: Create Firewall**
1. Go to **Hetzner Cloud Console** → **Firewalls** → **Create Firewall**
2. Name: `blocklet-server-firewall`
3. Description: `Firewall for Arcblock Blocklet Server`

**Step 2: Configure Inbound Rules**

| Rule Name | Direction | Protocol | Port | Source IPs | Description |
|-----------|-----------|----------|------|------------|-------------|
| SSH | Inbound | TCP | 2222 | 0.0.0.0/0, ::/0 | SSH Access |
| Blocklet Server | Inbound | TCP | 8089 | 0.0.0.0/0, ::/0 | Main Interface |
| HTTP | Inbound | TCP | 80 | 0.0.0.0/0, ::/0 | Web Traffic |
| HTTPS | Inbound | TCP | 443 | 0.0.0.0/0, ::/0 | Secure Web Traffic |

**Step 3: Apply to Server**
1. Go to your server → **Firewalls** tab
2. Click **Assign Firewall**
3. Select your created firewall

### Security Configurations

#### Production Environment (Open Access)
```json
{
  "rules": [
    {
      "direction": "in",
      "port": "2222",
      "protocol": "tcp", 
      "source_ips": ["0.0.0.0/0", "::/0"],
      "description": "SSH Access"
    },
    {
      "direction": "in",
      "port": "8089", 
      "protocol": "tcp",
      "source_ips": ["0.0.0.0/0", "::/0"],
      "description": "Blocklet Server"
    },
    {
      "direction": "in",
      "port": "80",
      "protocol": "tcp",
      "source_ips": ["0.0.0.0/0", "::/0"], 
      "description": "HTTP"
    },
    {
      "direction": "in",
      "port": "443",
      "protocol": "tcp",
      "source_ips": ["0.0.0.0/0", "::/0"],
      "description": "HTTPS"
    }
  ]
}
```

#### Development Environment (Restricted Access)
```json
{
  "rules": [
    {
      "direction": "in",
      "port": "2222",
      "protocol": "tcp",
      "source_ips": ["YOUR_IP/32"],
      "description": "SSH - Your IP Only"
    },
    {
      "direction": "in", 
      "port": "8089",
      "protocol": "tcp",
      "source_ips": ["YOUR_IP/32"],
      "description": "Blocklet Server - Your IP Only"
    }
  ]
}
```

#### Staging Environment (Team Access)
```json
{
  "rules": [
    {
      "direction": "in",
      "port": "2222", 
      "protocol": "tcp",
      "source_ips": ["OFFICE_IP/32", "ADMIN_IP/32", "DEV_IP/32"],
      "description": "SSH - Team Access"
    },
    {
      "direction": "in",
      "port": "8089",
      "protocol": "tcp", 
      "source_ips": ["0.0.0.0/0", "::/0"],
      "description": "Blocklet Server - Public Access"
    }
  ]
}
```

## Server-Level UFW Firewall

### Current Configuration (Automatic via Cloud-Init)

The cloud-init script automatically configures UFW with these rules:

```bash
# Reset and configure UFW
ufw --force reset
ufw default deny incoming  
ufw default allow outgoing
ufw allow 2222/tcp comment 'SSH'
ufw allow 8089/tcp comment 'Blocklet Server'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw --force enable
```

### Manual UFW Management

#### Check Current Status
```bash
sudo ufw status verbose
```

#### Modify Rules
```bash
# Add new rule
sudo ufw allow from 192.168.1.0/24 to any port 8089 comment 'Local network access'

# Remove rule
sudo ufw delete allow 80/tcp

# Insert rule at specific position
sudo ufw insert 1 allow from YOUR_IP to any port 2222

# Reload firewall
sudo ufw reload
```

#### Advanced UFW Rules
```bash
# Limit SSH connections (rate limiting)
sudo ufw limit 2222/tcp

# Allow specific IP range for Blocklet Server
sudo ufw allow from 10.0.0.0/8 to any port 8089

# Log denied connections
sudo ufw logging on

# Allow outgoing on specific ports only
sudo ufw default deny outgoing
sudo ufw allow out 53 comment 'DNS'
sudo ufw allow out 80 comment 'HTTP'
sudo ufw allow out 443 comment 'HTTPS'
sudo ufw allow out 22 comment 'SSH to other servers'
```

## Outbound Traffic Requirements

### Required Outbound Ports

| Port | Protocol | Purpose | Destination |
|------|----------|---------|-------------|
| **53** | UDP/TCP | DNS Resolution | DNS Servers |
| **80** | TCP | HTTP Updates | Package repositories, container registries |
| **443** | TCP | HTTPS Updates | Secure package repositories, container registries |
| **22** | TCP | Git/SSH | Code repositories (if needed) |
| **11371** | TCP | GPG Key Server | Package verification |

### Container Registry Access
```bash
# Docker Hub
- registry-1.docker.io:443
- auth.docker.io:443
- dseasb33srnrn.cloudfront.net:443

# Quay.io
- quay.io:443

# Red Hat Registry
- registry.access.redhat.com:443
```

### Arcblock Specific Requirements
```bash
# Arcblock services (adjust based on actual requirements)
- api.arcblock.io:443
- registry.arcblock.io:443
- updates.arcblock.io:443
```

## Security Best Practices

### 1. Principle of Least Privilege
```bash
# Only open required ports
# Use specific IP ranges when possible
# Regularly audit firewall rules
```

### 2. Layered Security
```bash
# Network Level: Hetzner Cloud Firewall
# Server Level: UFW Firewall  
# Application Level: Container security
# Access Level: SSH keys only
```

### 3. Monitoring and Alerting
```bash
# Enable UFW logging
sudo ufw logging medium

# Monitor failed connections
sudo tail -f /var/log/ufw.log

# Check fail2ban status
sudo fail2ban-client status

# Monitor active connections
sudo netstat -tuln
sudo ss -tuln
```

### 4. Regular Security Updates
```bash
# Firewall rules audit
sudo ufw --dry-run reset

# Check for unused rules
sudo ufw status numbered

# Review fail2ban logs
sudo fail2ban-client status sshd
sudo fail2ban-client status blocklet-server
```

## Troubleshooting

### Common Issues

#### 1. Cannot SSH to Server
```bash
# Check Hetzner Cloud firewall allows port 2222
# Verify UFW allows port 2222
sudo ufw status | grep 2222

# Test connectivity
telnet YOUR_SERVER_IP 2222
nc -zv YOUR_SERVER_IP 2222
```

#### 2. Cannot Access Blocklet Server
```bash
# Check if service is running
sudo systemctl status blocklet-server

# Check if port is listening
sudo netstat -tlnp | grep :8089
sudo ss -tlnp | grep :8089

# Check firewall rules
sudo ufw status | grep 8089

# Test local connectivity
curl -I http://localhost:8089
```

#### 3. Firewall Rules Not Working
```bash
# Reload UFW
sudo ufw reload

# Check UFW is enabled
sudo ufw status

# Check for conflicting iptables rules
sudo iptables -L -n

# Reset UFW completely
sudo ufw --force reset
# Then reconfigure using cloud-init commands
```

### Diagnostic Commands

#### Network Connectivity
```bash
# Test external connectivity
ping -c 4 8.8.8.8
curl -I https://google.com

# Check DNS resolution
nslookup arcblock.io
dig arcblock.io

# Trace network path
traceroute YOUR_SERVER_IP
mtr YOUR_SERVER_IP
```

#### Port Testing
```bash
# From external machine
nmap -p 2222,8089,80,443 YOUR_SERVER_IP

# From server (internal)
sudo netstat -tuln
sudo ss -tuln
lsof -i :8089
```

#### Firewall Status
```bash
# UFW detailed status
sudo ufw status verbose
sudo ufw show raw

# Fail2ban status
sudo fail2ban-client status
sudo fail2ban-client status sshd

# Check active connections
sudo netstat -an | grep ESTABLISHED
```

## Quick Reference Commands

### Hetzner Cloud API
```bash
# List firewalls
curl -H "Authorization: Bearer $HETZNER_API_TOKEN" \
  https://api.hetzner.cloud/v1/firewalls

# Get firewall details
curl -H "Authorization: Bearer $HETZNER_API_TOKEN" \
  https://api.hetzner.cloud/v1/firewalls/FIREWALL_ID

# Apply firewall to server
curl -X POST \
  -H "Authorization: Bearer $HETZNER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"resources":[{"server":{"id":SERVER_ID},"type":"server"}]}' \
  https://api.hetzner.cloud/v1/firewalls/FIREWALL_ID/actions/apply_to_resources
```

### UFW Quick Commands
```bash
# Enable/disable
sudo ufw enable
sudo ufw disable

# Status
sudo ufw status
sudo ufw status verbose
sudo ufw status numbered

# Add/remove rules
sudo ufw allow PORT
sudo ufw deny PORT  
sudo ufw delete RULE_NUMBER

# Reset
sudo ufw --force reset
```

### Testing Access
```bash
# SSH test
ssh -p 2222 -o ConnectTimeout=10 arcblock@YOUR_SERVER_IP

# HTTP test
curl -m 10 http://YOUR_SERVER_IP:8089/api/did

# Port scan
nmap -p 2222,8089,80,443 YOUR_SERVER_IP
```

## IPv6 Considerations

### IPv6 Firewall Rules
All firewall rules should include both IPv4 and IPv6:
```
IPv4: 0.0.0.0/0
IPv6: ::/0
```

### UFW IPv6 Support
```bash
# Ensure IPv6 is enabled in UFW
sudo nano /etc/default/ufw
# Set: IPV6=yes

# Reload UFW
sudo ufw reload
```

### Testing IPv6 Connectivity
```bash
# Test IPv6 connectivity
ping6 YOUR_SERVER_IPV6
curl -6 http://[YOUR_SERVER_IPV6]:8089

# SSH via IPv6
ssh -p 2222 arcblock@[YOUR_SERVER_IPV6]
```

This guide covers all aspects of firewall and port configuration for your Arcblock Blocklet Server deployment. Always test connectivity after making firewall changes and maintain security best practices.