#!/bin/bash

# ArcDeploy Native Installation Validation Script
# Enhanced validation for native Blocklet Server deployment

set -e

echo "=== ArcDeploy Native Installation Validation ==="
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
cloud_init_status=$?
check_status $cloud_init_status "Cloud-init completed successfully"

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
user_exists=$?
check_status $user_exists "User 'arcblock' exists"

groups arcblock | grep -q sudo > /dev/null 2>&1
sudo_check=$?
check_status $sudo_check "User 'arcblock' has sudo privileges"

if [ -d "/home/arcblock" ]; then
    check_status 0 "Home directory exists for arcblock user"
else
    check_status 1 "Home directory exists for arcblock user"
fi

stat -c "%U:%G" /home/arcblock | grep -q "arcblock:arcblock" > /dev/null 2>&1
ownership_check=$?
check_status $ownership_check "Home directory has correct ownership"

echo

# Test 3: SSH Configuration
echo "3. Checking SSH Configuration"
grep -q "PermitRootLogin no" /etc/ssh/sshd_config > /dev/null 2>&1
root_login_check=$?
check_status $root_login_check "Root login is disabled"

grep -q "PasswordAuthentication no" /etc/ssh/sshd_config > /dev/null 2>&1
password_auth_check=$?
check_status $password_auth_check "Password authentication is disabled"

grep -q "Port 2222" /etc/ssh/sshd_config > /dev/null 2>&1
ssh_port_check=$?
check_status $ssh_port_check "SSH port is set to 2222"

grep -q "AllowUsers arcblock" /etc/ssh/sshd_config > /dev/null 2>&1
allow_users_check=$?
check_status $allow_users_check "SSH access restricted to arcblock user"

if [ -f "/home/arcblock/.ssh/authorized_keys" ]; then
    check_status 0 "SSH authorized_keys file exists"
else
    check_status 1 "SSH authorized_keys file exists"
fi

if [ -f "/home/arcblock/.ssh/authorized_keys" ]; then
    key_count=$(wc -l < /home/arcblock/.ssh/authorized_keys)
    if [ "$key_count" -gt 0 ]; then
        check_status 0 "SSH keys are configured ($key_count keys found)"
    else
        check_status 1 "No SSH keys found in authorized_keys"
    fi
fi

systemctl is-active --quiet ssh
ssh_service_check=$?
check_status $ssh_service_check "SSH service is running"

echo

# Test 4: Firewall Configuration
echo "4. Checking Firewall Configuration"
command -v ufw > /dev/null 2>&1
ufw_installed=$?
check_status $ufw_installed "UFW is installed"

ufw status | grep -q "Status: active" > /dev/null 2>&1
ufw_active=$?
check_status $ufw_active "UFW firewall is active"

ufw status | grep -q "2222" > /dev/null 2>&1
ufw_ssh_port=$?
check_status $ufw_ssh_port "Port 2222 (SSH) is allowed"

ufw status | grep -q "8080" > /dev/null 2>&1
ufw_http_port=$?
check_status $ufw_http_port "Port 8080 (Blocklet Server HTTP) is allowed"

ufw status | grep -q "8443" > /dev/null 2>&1
ufw_https_port=$?
check_status $ufw_https_port "Port 8443 (Blocklet Server HTTPS) is allowed"

ufw status | grep -q "80" > /dev/null 2>&1
ufw_port_80=$?
check_status $ufw_port_80 "Port 80 (HTTP) is allowed"

ufw status | grep -q "443" > /dev/null 2>&1
ufw_port_443=$?
check_status $ufw_port_443 "Port 443 (HTTPS) is allowed"

# Check if old SSH port 22 is closed
if ufw status | grep -q "22/tcp" > /dev/null 2>&1 && ! ufw status | grep -q "2222" > /dev/null 2>&1; then
    check_warning "Port 22 is still open - should be closed in favor of 2222"
fi

echo

# Test 5: Fail2Ban Setup
echo "5. Checking Fail2Ban Configuration"
command -v fail2ban-client > /dev/null 2>&1
fail2ban_installed=$?
check_status $fail2ban_installed "Fail2ban is installed"

systemctl is-active --quiet fail2ban > /dev/null 2>&1
fail2ban_active=$?
check_status $fail2ban_active "Fail2ban service is running"

if [ -f "/etc/fail2ban/jail.local" ]; then
    check_status 0 "Fail2ban local configuration exists"
else
    check_status 1 "Fail2ban local configuration exists"
fi

if [ -f "/etc/fail2ban/filter.d/blocklet-server.conf" ]; then
    check_status 0 "Blocklet Server fail2ban filter exists"
else
    check_status 1 "Blocklet Server fail2ban filter exists"
fi

fail2ban-client status 2>/dev/null | grep -q "sshd" > /dev/null 2>&1
ssh_protection_check=$?
check_status $ssh_protection_check "SSH protection is enabled in fail2ban"

echo

# Test 6: Node.js Installation and Configuration
echo "6. Checking Node.js Installation"
command -v node > /dev/null 2>&1
node_installed=$?
check_status $node_installed "Node.js is installed"

command -v npm > /dev/null 2>&1
npm_installed=$?
check_status $npm_installed "npm is installed"

if command -v node > /dev/null 2>&1; then
    node_version=$(node --version 2>/dev/null)
    check_info "Node.js version: $node_version"
    
    # Check if Node.js version is reasonable (v16+)
    major_version=$(echo "$node_version" | sed 's/v\([0-9]\+\)\..*/\1/')
    if [ "$major_version" -ge 16 ]; then
        check_status 0 "Node.js version is suitable (v16+)"
    else
        check_warning "Node.js version may be too old (recommended v16+)"
    fi
fi

if command -v npm > /dev/null 2>&1; then
    npm_version=$(npm --version 2>/dev/null)
    check_info "npm version: $npm_version"
fi

echo

# Test 7: Blocklet CLI Installation
echo "7. Checking Blocklet CLI Installation"
command -v blocklet > /dev/null 2>&1
blocklet_in_path=$?
check_status $blocklet_in_path "Blocklet CLI is in PATH"

sudo -u arcblock blocklet --version > /dev/null 2>&1
blocklet_accessible=$?
check_status $blocklet_accessible "Blocklet CLI accessible by arcblock user"

sudo -u arcblock npm list -g @blocklet/cli > /dev/null 2>&1
blocklet_cli_installed=$?
check_status $blocklet_cli_installed "@blocklet/cli package is installed globally"

if sudo -u arcblock blocklet --version > /dev/null 2>&1; then
    cli_version=$(sudo -u arcblock blocklet --version 2>/dev/null)
    check_info "Blocklet CLI version: $cli_version"
fi

echo

# Test 8: Directory Structure
echo "8. Checking Directory Structure"
if [ -d "/opt/blocklet-server" ]; then
    check_status 0 "Main Blocklet Server directory exists"
else
    check_status 1 "Main Blocklet Server directory exists"
fi

if [ -d "/opt/blocklet-server/data" ]; then
    check_status 0 "Data directory exists"
else
    check_status 1 "Data directory exists"
fi

if [ -d "/opt/blocklet-server/config" ]; then
    check_status 0 "Config directory exists"
else
    check_status 1 "Config directory exists"
fi

if [ -d "/opt/blocklet-server/logs" ]; then
    check_status 0 "Logs directory exists"
else
    check_status 1 "Logs directory exists"
fi

stat -c "%U:%G" /opt/blocklet-server | grep -q "arcblock:arcblock" > /dev/null 2>&1
dir_ownership_check=$?
check_status $dir_ownership_check "Blocklet Server directory has correct ownership"

if [ -f "/opt/blocklet-server/healthcheck.sh" ]; then
    check_status 0 "Health check script exists"
else
    check_status 1 "Health check script exists"
fi

if [ -x "/opt/blocklet-server/healthcheck.sh" ]; then
    check_status 0 "Health check script is executable"
else
    check_status 1 "Health check script is executable"
fi

echo

# Test 9: Service Configuration
echo "9. Checking Service Configuration"
if [ -f "/etc/systemd/system/blocklet-server.service" ]; then
    check_status 0 "Blocklet Server systemd service file exists"
else
    check_status 1 "Blocklet Server systemd service file exists"
fi

systemctl is-enabled blocklet-server > /dev/null 2>&1
service_enabled_check=$?
check_status $service_enabled_check "Blocklet Server service is enabled"

systemctl is-active blocklet-server > /dev/null 2>&1
service_active_check=$?
check_status $service_active_check "Blocklet Server service is active"

# Check service configuration
if grep -q "User=arcblock" /etc/systemd/system/blocklet-server.service 2>/dev/null; then
    check_status 0 "Service runs as arcblock user"
else
    check_warning "Service user configuration unclear"
fi

echo

# Test 10: Nginx Configuration
echo "10. Checking Nginx Configuration"
command -v nginx > /dev/null 2>&1
nginx_installed=$?
check_status $nginx_installed "Nginx is installed"

systemctl is-active --quiet nginx > /dev/null 2>&1
nginx_active=$?
check_status $nginx_active "Nginx service is running"

if [ -f "/etc/nginx/sites-available/blocklet-server" ]; then
    check_status 0 "Nginx site configuration exists"
else
    check_status 1 "Nginx site configuration exists"
fi

if [ -L "/etc/nginx/sites-enabled/blocklet-server" ]; then
    check_status 0 "Nginx site is enabled"
else
    check_status 1 "Nginx site is enabled"
fi

nginx -t > /dev/null 2>&1
nginx_config_valid=$?
check_status $nginx_config_valid "Nginx configuration is valid"

# Check nginx version for required modules
nginx_version=$(nginx -v 2>&1 | grep -o '[0-9]\+\.[0-9]\+')
if [ -n "$nginx_version" ]; then
    check_info "Nginx version: $nginx_version"
fi

echo

# Test 11: Redis Configuration
echo "11. Checking Redis Configuration"
command -v redis-server > /dev/null 2>&1
redis_installed=$?
check_status $redis_installed "Redis is installed"

systemctl is-active --quiet redis > /dev/null 2>&1 || systemctl is-active --quiet redis-server > /dev/null 2>&1
redis_active=$?
check_status $redis_active "Redis service is running"

redis-cli ping > /dev/null 2>&1
redis_ping_check=$?
check_status $redis_ping_check "Redis is responding to ping"

echo

# Test 12: Network Connectivity
echo "12. Checking Network Connectivity"
# Test if ports are listening
netstat -tlnp 2>/dev/null | grep -q ":2222" > /dev/null 2>&1
ssh_port_listening=$?
check_status $ssh_port_listening "SSH port 2222 is listening"

netstat -tlnp 2>/dev/null | grep -q ":8080" > /dev/null 2>&1
port_8080_check=$?
if [ $port_8080_check -eq 0 ]; then
    check_status 0 "Blocklet Server port 8080 is listening"
else
    check_warning "Port 8080 is not listening (service may be starting)"
fi

netstat -tlnp 2>/dev/null | grep -q ":8443" > /dev/null 2>&1
port_8443_check=$?
if [ $port_8443_check -eq 0 ]; then
    check_status 0 "Blocklet Server HTTPS port 8443 is listening"
else
    check_warning "Port 8443 is not listening (HTTPS may not be configured)"
fi

netstat -tlnp 2>/dev/null | grep -q ":80" > /dev/null 2>&1
nginx_port_80_check=$?
check_status $nginx_port_80_check "Nginx port 80 is listening"

# Test HTTP endpoints
curl -sf --max-time 10 http://localhost:8080 >/dev/null 2>&1
http_endpoint_check=$?
if [ $http_endpoint_check -eq 0 ]; then
    check_status 0 "Blocklet Server HTTP endpoint is responding"
else
    check_warning "Blocklet Server HTTP endpoint not responding (may still be initializing)"
fi

curl -sf --max-time 10 http://localhost:80 >/dev/null 2>&1
nginx_proxy_check=$?
if [ $nginx_proxy_check -eq 0 ]; then
    check_status 0 "Nginx proxy is responding"
else
    check_warning "Nginx proxy not responding properly"
fi

echo

# Test 13: System Resources
echo "13. Checking System Resources"
total_mem=$(free -m | awk 'NR==2{printf "%.0f", $2}')
if [ "$total_mem" -gt 8000 ]; then
    check_status 0 "Memory: ${total_mem}MB (excellent)"
elif [ "$total_mem" -gt 4000 ]; then
    check_status 0 "Memory: ${total_mem}MB (good)"
elif [ "$total_mem" -gt 2000 ]; then
    check_warning "Memory: ${total_mem}MB (minimum requirements met)"
else
    check_status 1 "Memory: ${total_mem}MB (insufficient - recommended 4GB+)"
fi

total_disk=$(df /opt/blocklet-server 2>/dev/null | awk 'NR==2 {print $2}' || echo "0")
total_disk_gb=$((total_disk / 1024 / 1024))
if [ "$total_disk_gb" -gt 80 ]; then
    check_status 0 "Disk space: ${total_disk_gb}GB (excellent)"
elif [ "$total_disk_gb" -gt 40 ]; then
    check_status 0 "Disk space: ${total_disk_gb}GB (good)"
elif [ "$total_disk_gb" -gt 20 ]; then
    check_warning "Disk space: ${total_disk_gb}GB (minimum requirements met)"
else
    check_status 1 "Disk space: ${total_disk_gb}GB (insufficient - recommended 40GB+)"
fi

# Check disk usage
disk_usage=$(df /opt/blocklet-server 2>/dev/null | awk 'NR==2 {print $(NF-1)}' | sed 's/%//' || echo "0")
if [ "$disk_usage" -lt 80 ]; then
    check_status 0 "Disk usage: ${disk_usage}% (healthy)"
else
    check_warning "Disk usage: ${disk_usage}% (high usage detected)"
fi

echo

# Test 14: Monitoring and Health Checks
echo "14. Checking Monitoring and Health Checks"
if [ -f "/opt/blocklet-server/healthcheck.sh" ]; then
    check_status 0 "Health check script exists"
else
    check_status 1 "Health check script exists"
fi

if [ -x "/opt/blocklet-server/healthcheck.sh" ]; then
    check_status 0 "Health check script is executable"
else
    check_status 1 "Health check script is executable"
fi

# Check cron jobs
sudo -u arcblock crontab -l 2>/dev/null | grep -q "healthcheck.sh" > /dev/null 2>&1
cron_check=$?
check_status $cron_check "Health check cron job is configured"

# Try running health check
if sudo -u arcblock /opt/blocklet-server/healthcheck.sh > /dev/null 2>&1; then
    check_status 0 "Health check script runs successfully"
else
    check_warning "Health check script failed or has issues"
fi

echo

# Test 15: Log Files and Health
echo "15. Checking Logs and Health"
if [ -f "/var/log/cloud-init.log" ]; then
    check_status 0 "Cloud-init log exists"
else
    check_status 1 "Cloud-init log exists"
fi

# Check if health check has run
if [ -f "/opt/blocklet-server/logs/health.log" ]; then
    check_status 0 "Health check log exists"
    
    # Check recent health check entries
    if tail -n 5 "/opt/blocklet-server/logs/health.log" | grep -q "$(date +%Y-%m-%d)" > /dev/null 2>&1; then
        check_status 0 "Recent health check entries found"
    else
        check_warning "No recent health check entries found"
    fi
else
    check_warning "Health check log not found (monitoring may not have started)"
fi

# Check service logs
if sudo journalctl -u blocklet-server --no-pager -n 1 2>/dev/null | grep -q "." > /dev/null 2>&1; then
    check_status 0 "Service logs are available"
else
    check_warning "Service logs are empty or unavailable"
fi

echo

# Test 16: Installation Completion
echo "16. Checking Installation Completion"
if [ -f "/opt/blocklet-server/.native-install-complete" ]; then
    check_status 0 "Native installation completion marker exists"
else
    check_status 1 "Native installation completion marker exists"
fi

# Check Blocklet Server configuration
if sudo -u arcblock blocklet server config list > /dev/null 2>&1; then
    check_status 0 "Blocklet Server configuration is accessible"
else
    check_warning "Cannot access Blocklet Server configuration"
fi

echo

# System Information
echo "17. System Information"
echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"

if command -v node > /dev/null 2>&1; then
    echo "Node.js Version: $(node --version)"
fi

if command -v nginx > /dev/null 2>&1; then
    echo "Nginx Version: $(nginx -v 2>&1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')"
fi

if command -v redis-server > /dev/null 2>&1; then
    echo "Redis Version: $(redis-server --version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')"
fi

echo "IPv4 Address: $(hostname -I | awk '{print $1}' || echo 'Not available')"

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
    echo "Your Blocklet Server native installation is fully operational."
elif [ $FAILED -eq 0 ]; then
    echo -e "${YELLOW}✓ Good! All critical checks passed with some warnings.${NC}"
    echo "Your Blocklet Server installation is operational but may need attention."
else
    echo -e "${RED}✗ Issues detected! Some critical checks failed.${NC}"
    echo "Please review the failed items above before proceeding."
fi

echo

# Quick Access Information
echo "=== Quick Access Information ==="
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "SSH Access: ssh -p 2222 arcblock@$SERVER_IP"
echo "Web Interface (Direct): http://$SERVER_IP:8080"
echo "Web Interface (Nginx): http://$SERVER_IP"
echo "HTTPS Interface: https://$SERVER_IP:8443"
echo "Service Status: sudo systemctl status blocklet-server"
echo "Service Logs: sudo journalctl -u blocklet-server -f"
echo "Health Check: sudo -u arcblock /opt/blocklet-server/healthcheck.sh"
echo "Blocklet CLI: sudo -u arcblock blocklet server status"

echo

# Troubleshooting Commands
echo "=== Troubleshooting Commands ==="
echo "View cloud-init logs: sudo tail -f /var/log/cloud-init-output.log"
echo "View service logs: sudo journalctl -u blocklet-server -f"
echo "Restart service: sudo systemctl restart blocklet-server"
echo "Check Blocklet config: sudo -u arcblock blocklet server config list"
echo "View firewall rules: sudo ufw status verbose"
echo "Check fail2ban status: sudo fail2ban-client status"
echo "Test nginx config: sudo nginx -t"
echo "Restart nginx: sudo systemctl restart nginx"
echo "Check Redis: redis-cli ping"

echo
echo "For detailed troubleshooting, check the README.md file in this repository."