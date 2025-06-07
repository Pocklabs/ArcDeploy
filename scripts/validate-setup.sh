#!/bin/bash

# Arcblock Blocklet Server Cloud-Init Setup Validation Script
# Enhanced validation for production-ready configuration

set -e

echo "=== Blocklet Server Setup Validation ==="
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo "User: $(whoami)"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Function to check status
check_status() {
    if [ $1 -eq 0 ]; then
        echo -e "[${GREEN}PASS${NC}] $2"
        ((PASSED++))
    else
        echo -e "[${RED}FAIL${NC}] $2"
        ((FAILED++))
    fi
}

check_warning() {
    echo -e "[${YELLOW}WARN${NC}] $1"
    ((WARNINGS++))
}

check_info() {
    echo -e "[${BLUE}INFO${NC}] $1"
}

# Test 1: Cloud-Init Status
echo "1. Checking Cloud-Init Status"
cloud-init status --wait > /dev/null 2>&1
check_status $? "Cloud-init completed successfully"

if [ -f "/var/log/cloud-init-output.log" ]; then
    check_status 0 "Cloud-init output log exists"
    
    # Check for errors in cloud-init log
    if grep -q "Error:" /var/log/cloud-init-output.log; then
        check_warning "Errors found in cloud-init log - check /var/log/cloud-init-output.log"
    else
        check_status 0 "No errors found in cloud-init log"
    fi
else
    check_status 1 "Cloud-init output log missing"
fi

echo

# Test 2: User and Permissions Setup
echo "2. Checking User Setup"
id arcblock > /dev/null 2>&1
check_status $? "User 'arcblock' exists"

groups arcblock | grep -q sudo > /dev/null 2>&1
check_status $? "User 'arcblock' has sudo privileges"

[ -d "/home/arcblock" ]
check_status $? "Home directory exists for arcblock user"

stat -c "%U:%G" /home/arcblock | grep -q "arcblock:arcblock" > /dev/null 2>&1
check_status $? "Home directory has correct ownership"

echo

# Test 3: SSH Configuration
echo "3. Checking SSH Configuration"
grep -q "PermitRootLogin no" /etc/ssh/sshd_config > /dev/null 2>&1
check_status $? "Root login is disabled"

grep -q "PasswordAuthentication no" /etc/ssh/sshd_config > /dev/null 2>&1
check_status $? "Password authentication is disabled"

grep -q "Port 2222" /etc/ssh/sshd_config > /dev/null 2>&1
check_status $? "SSH port is set to 2222"

grep -q "AllowUsers arcblock" /etc/ssh/sshd_config > /dev/null 2>&1
check_status $? "SSH access restricted to arcblock user"

[ -f "/home/arcblock/.ssh/authorized_keys" ]
check_status $? "SSH authorized_keys file exists"

if [ -f "/home/arcblock/.ssh/authorized_keys" ]; then
    key_count=$(wc -l < /home/arcblock/.ssh/authorized_keys)
    if [ "$key_count" -gt 0 ]; then
        check_status 0 "SSH keys are configured ($key_count keys found)"
    else
        check_status 1 "No SSH keys found in authorized_keys"
    fi
fi

systemctl is-active --quiet ssh
check_status $? "SSH service is running"

echo

# Test 4: Firewall Configuration
echo "4. Checking Firewall Configuration"
command -v ufw > /dev/null 2>&1
check_status $? "UFW is installed"

ufw status | grep -q "Status: active" > /dev/null 2>&1
check_status $? "UFW firewall is active"

ufw status | grep -q "2222" > /dev/null 2>&1
check_status $? "Port 2222 (SSH) is allowed"

ufw status | grep -q "8089" > /dev/null 2>&1
check_status $? "Port 8089 (Blocklet Server) is allowed"

ufw status | grep -q "80" > /dev/null 2>&1
check_status $? "Port 80 (HTTP) is allowed"

ufw status | grep -q "443" > /dev/null 2>&1
check_status $? "Port 443 (HTTPS) is allowed"

# Check if old SSH port 22 is closed
if ufw status | grep -q "22/tcp" > /dev/null 2>&1 && ! ufw status | grep -q "2222" > /dev/null 2>&1; then
    check_warning "Port 22 is still open - should be closed in favor of 2222"
fi

echo

# Test 5: Fail2Ban Setup
echo "5. Checking Fail2Ban Configuration"
command -v fail2ban-client > /dev/null 2>&1
check_status $? "Fail2ban is installed"

systemctl is-active --quiet fail2ban > /dev/null 2>&1
check_status $? "Fail2ban service is running"

[ -f "/etc/fail2ban/jail.local" ]
check_status $? "Fail2ban local configuration exists"

[ -f "/etc/fail2ban/filter.d/blocklet-server.conf" ]
check_status $? "Blocklet Server fail2ban filter exists"

fail2ban-client status 2>/dev/null | grep -q "sshd" > /dev/null 2>&1
check_status $? "SSH protection is enabled in fail2ban"

echo

# Test 6: Podman Installation and Configuration
echo "6. Checking Podman Installation"
command -v podman > /dev/null 2>&1
check_status $? "Podman is installed"

sudo -u arcblock podman --version > /dev/null 2>&1
check_status $? "Podman accessible by arcblock user"

# Check subuid/subgid configuration
grep -q "arcblock:" /etc/subuid > /dev/null 2>&1
check_status $? "Subuid configuration for arcblock user"

grep -q "arcblock:" /etc/subgid > /dev/null 2>&1
check_status $? "Subgid configuration for arcblock user"

# Check user linger
loginctl show-user arcblock 2>/dev/null | grep -q "Linger=yes" > /dev/null 2>&1
check_status $? "User linger is enabled for arcblock"

# Check podman socket
sudo -u arcblock systemctl --user is-active --quiet podman.socket > /dev/null 2>&1
check_status $? "Podman socket is active for arcblock user"

echo

# Test 7: Directory Structure
echo "7. Checking Directory Structure"
[ -d "/home/arcblock/blocklet-server" ]
check_status $? "Blocklet Server directory exists"

[ -d "/home/arcblock/.config/containers" ]
check_status $? "Podman configuration directory exists"

[ -d "/home/arcblock/.local/share/containers" ]
check_status $? "Podman storage directory exists"

[ -d "/home/arcblock/backups" ]
check_status $? "Backup directory exists"

[ -f "/home/arcblock/blocklet-server/compose.yaml" ]
check_status $? "Docker compose configuration exists"

[ -f "/home/arcblock/.config/containers/registries.conf" ]
check_status $? "Container registry configuration exists"

[ -f "/home/arcblock/.config/containers/storage.conf" ]
check_status $? "Container storage configuration exists"

echo

# Test 8: Service Configuration
echo "8. Checking Service Configuration"
[ -f "/etc/systemd/system/blocklet-server.service" ]
check_status $? "Blocklet Server systemd service file exists"

systemctl is-enabled --quiet blocklet-server > /dev/null 2>&1
check_status $? "Blocklet Server service is enabled"

systemctl is-active --quiet blocklet-server > /dev/null 2>&1
check_status $? "Blocklet Server service is running"

[ -f "/etc/logrotate.d/blocklet-server" ]
check_status $? "Log rotation configuration exists"

echo

# Test 9: Container Status
echo "9. Checking Container Status"
sudo -u arcblock podman images | grep -q "arcblock/blocklet-server" > /dev/null 2>&1
check_status $? "Blocklet Server image is available"

sudo -u arcblock podman ps | grep -q "blocklet-server" > /dev/null 2>&1
check_status $? "Blocklet Server container is running"

# Check container health
if sudo -u arcblock podman ps --format "{{.Status}}" --filter "name=blocklet-server" | grep -q "healthy\|Up" > /dev/null 2>&1; then
    check_status 0 "Blocklet Server container is healthy"
else
    check_warning "Container health status unclear"
fi

# Check container volumes
volume_count=$(sudo -u arcblock podman volume ls --format "{{.Name}}" | grep -c "blocklet" 2>/dev/null || echo "0")
if [ "$volume_count" -ge 3 ]; then
    check_status 0 "Container volumes are created ($volume_count volumes)"
else
    check_warning "Expected 3 volumes, found $volume_count"
fi

echo

# Test 10: Network Connectivity
echo "10. Checking Network Connectivity"
# Test if ports are listening
netstat -tlnp 2>/dev/null | grep -q ":2222" > /dev/null 2>&1
check_status $? "SSH port 2222 is listening"

netstat -tlnp 2>/dev/null | grep -q ":8089" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    check_status 0 "Blocklet Server port 8089 is listening"
else
    check_warning "Port 8089 is not listening (service may be starting)"
fi

# Test HTTP endpoint
curl -sf --max-time 10 http://localhost:8089/api/did >/dev/null 2>&1
if [ $? -eq 0 ]; then
    check_status 0 "Blocklet Server HTTP endpoint is responding"
else
    check_warning "Blocklet Server HTTP endpoint not responding (may still be initializing)"
fi

echo

# Test 11: System Resources
echo "11. Checking System Resources"
total_mem=$(free -m | awk 'NR==2{printf "%.0f", $2}')
if [ "$total_mem" -gt 4000 ]; then
    check_status 0 "Memory: ${total_mem}MB (sufficient)"
elif [ "$total_mem" -gt 2000 ]; then
    check_warning "Memory: ${total_mem}MB (minimum requirements met)"
else
    check_status 1 "Memory: ${total_mem}MB (insufficient - recommended 4GB+)"
fi

total_disk=$(df /home/arcblock 2>/dev/null | awk 'NR==2 {print $2}' || echo "0")
total_disk_gb=$((total_disk / 1024 / 1024))
if [ "$total_disk_gb" -gt 40 ]; then
    check_status 0 "Disk space: ${total_disk_gb}GB (sufficient)"
elif [ "$total_disk_gb" -gt 20 ]; then
    check_warning "Disk space: ${total_disk_gb}GB (minimum requirements met)"
else
    check_status 1 "Disk space: ${total_disk_gb}GB (insufficient - recommended 40GB+)"
fi

# Check disk usage
disk_usage=$(df /home/arcblock 2>/dev/null | awk 'NR==2 {print $(NF-1)}' | sed 's/%//' || echo "0")
if [ "$disk_usage" -lt 80 ]; then
    check_status 0 "Disk usage: ${disk_usage}% (healthy)"
else
    check_warning "Disk usage: ${disk_usage}% (high usage detected)"
fi

echo

# Test 12: Monitoring and Backup Scripts
echo "12. Checking Monitoring and Backup"
[ -f "/home/arcblock/blocklet-server/healthcheck.sh" ]
check_status $? "Health check script exists"

[ -f "/home/arcblock/blocklet-server/backup.sh" ]
check_status $? "Backup script exists"

[ -x "/home/arcblock/blocklet-server/healthcheck.sh" ]
check_status $? "Health check script is executable"

[ -x "/home/arcblock/blocklet-server/backup.sh" ]
check_status $? "Backup script is executable"

# Check cron jobs
sudo -u arcblock crontab -l 2>/dev/null | grep -q "healthcheck.sh" > /dev/null 2>&1
check_status $? "Health check cron job is configured"

sudo -u arcblock crontab -l 2>/dev/null | grep -q "backup.sh" > /dev/null 2>&1
check_status $? "Backup cron job is configured"

echo

# Test 13: Software Installation
echo "13. Checking Software Installation"
command -v node > /dev/null 2>&1
check_status $? "Node.js is installed"

if command -v node > /dev/null 2>&1; then
    node_version=$(node --version 2>/dev/null)
    check_info "Node.js version: $node_version"
fi

sudo -u arcblock npm list -g @blocklet/cli > /dev/null 2>&1
if [ $? -eq 0 ]; then
    check_status 0 "Blocklet CLI is installed"
    cli_version=$(sudo -u arcblock npx abtnode --version 2>/dev/null || echo "unknown")
    check_info "Blocklet CLI version: $cli_version"
else
    check_warning "Blocklet CLI not found (installation may have failed)"
fi

command -v git > /dev/null 2>&1
check_status $? "Git is installed"

echo

# Test 14: Log Files and Health
echo "14. Checking Logs and Health"
[ -f "/var/log/cloud-init.log" ]
check_status $? "Cloud-init log exists"

# Check if health check has run
if [ -f "/home/arcblock/blocklet-server/logs/health.log" ]; then
    check_status 0 "Health check log exists"
    
    # Check recent health check entries
    if tail -n 5 "/home/arcblock/blocklet-server/logs/health.log" | grep -q "$(date +%Y-%m-%d)" > /dev/null 2>&1; then
        check_status 0 "Recent health check entries found"
    else
        check_warning "No recent health check entries found"
    fi
else
    check_warning "Health check log not found (monitoring may not have started)"
fi

# Check container logs
if sudo -u arcblock podman logs blocklet-server --tail 10 2>/dev/null | grep -q "." > /dev/null 2>&1; then
    check_status 0 "Container logs are available"
else
    check_warning "Container logs are empty or unavailable"
fi

echo

# Test 15: Auto-update Configuration
echo "15. Checking Auto-update Configuration"
[ -f "/etc/systemd/system/podman-auto-update.timer" ]
check_status $? "Auto-update timer configuration exists"

[ -f "/etc/systemd/system/podman-auto-update.service" ]
check_status $? "Auto-update service configuration exists"

systemctl is-enabled --quiet podman-auto-update.timer > /dev/null 2>&1
check_status $? "Auto-update timer is enabled"

systemctl is-active --quiet podman-auto-update.timer > /dev/null 2>&1
check_status $? "Auto-update timer is active"

echo

# System Information
echo "16. System Information"
echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo "Podman Version: $(podman --version 2>/dev/null || echo 'Not available')"

if command -v node > /dev/null 2>&1; then
    echo "Node.js Version: $(node --version)"
fi

echo "IPv4 Address: $(hostname -I | awk '{print $1}' || echo 'Not available')"
echo "IPv6 Address: $(hostname -I | awk '{print $2}' || echo 'Not available')"

echo

# Final Summary
echo "=== Validation Summary ==="
echo -e "Total Tests: $((PASSED + FAILED + WARNINGS))"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"

echo

if [ $FAILED -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ Excellent! All checks passed successfully.${NC}"
    echo "Your Blocklet Server setup is fully operational."
elif [ $FAILED -eq 0 ]; then
    echo -e "${YELLOW}✓ Good! All critical checks passed with some warnings.${NC}"
    echo "Your Blocklet Server setup is operational but may need attention."
else
    echo -e "${RED}✗ Issues detected! Some critical checks failed.${NC}"
    echo "Please review the failed items above before proceeding."
fi

echo

# Quick Access Information
echo "=== Quick Access Information ==="
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "SSH Access: ssh -p 2222 arcblock@$SERVER_IP"
echo "Web Interface: http://$SERVER_IP:8089"
echo "Service Status: sudo systemctl status blocklet-server"
echo "Container Status: sudo -u arcblock podman ps"
echo "Container Logs: sudo -u arcblock podman logs blocklet-server"
echo "Health Check: sudo -u arcblock /home/arcblock/blocklet-server/healthcheck.sh"
echo "Manual Backup: sudo -u arcblock /home/arcblock/blocklet-server/backup.sh"

echo

# Troubleshooting Commands
echo "=== Troubleshooting Commands ==="
echo "View cloud-init logs: sudo tail -f /var/log/cloud-init-output.log"
echo "View service logs: sudo journalctl -u blocklet-server -f"
echo "Restart service: sudo systemctl restart blocklet-server"
echo "Check container health: sudo -u arcblock podman healthcheck run blocklet-server"
echo "View firewall rules: sudo ufw status verbose"
echo "Check fail2ban status: sudo fail2ban-client status"

echo
echo "For detailed troubleshooting, check the README.md file in this repository."