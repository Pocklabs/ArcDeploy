#!/bin/bash

echo "=== ArcDeploy Debugging Script ==="
echo "Timestamp: $(date)"
echo "======================================"

echo "1. Check cloud-init status:"
sudo cloud-init status --long
echo ""

echo "2. Check arcblock user details:"
id arcblock
echo ""

echo "3. Check home directory structure:"
ls -la /home/arcblock/
echo ""

echo "4. Check if setup files were created:"
echo "- Checking for blocklet-server directory:"
ls -la /home/arcblock/blocklet-server/ 2>/dev/null || echo "Directory not found"
echo ""

echo "- Checking for compose.yaml:"
cat /home/arcblock/blocklet-server/compose.yaml 2>/dev/null || echo "File not found"
echo ""

echo "- Checking for setup script:"
ls -la /home/arcblock/setup-post-install.sh 2>/dev/null || echo "File not found"
echo ""

echo "5. Check systemd service file:"
ls -la /etc/systemd/system/blocklet-server.service 2>/dev/null || echo "Service file not found"
echo ""

echo "6. Check if systemd service exists:"
sudo systemctl status blocklet-server 2>/dev/null || echo "Service not found"
echo ""

echo "7. Check podman installation:"
which podman
podman --version 2>/dev/null || echo "Podman not accessible"
echo ""

echo "8. Check podman user setup:"
sudo -u arcblock podman info 2>/dev/null | head -10 || echo "Podman user setup incomplete"
echo ""

echo "9. Check running containers:"
sudo -u arcblock podman ps 2>/dev/null || echo "Cannot list containers"
echo ""

echo "10. Check port 8089:"
curl -f http://localhost:8089/api/did 2>/dev/null || echo "Port 8089 not responding"
echo ""

echo "11. Check firewall status:"
sudo ufw status
echo ""

echo "12. Check SSH configuration:"
grep -E "^Port|^PasswordAuthentication|^PubkeyAuthentication" /etc/ssh/sshd_config
echo ""

echo "13. Check fail2ban status:"
sudo systemctl status fail2ban --no-pager -l
echo ""

echo "14. Check Node.js installation:"
node --version 2>/dev/null || echo "Node.js not found"
npm --version 2>/dev/null || echo "npm not found"
echo ""

echo "15. Check if @blocklet/cli is installed:"
sudo -u arcblock npm list -g @blocklet/cli 2>/dev/null || echo "@blocklet/cli not installed"
echo ""

echo "16. Check subuid/subgid configuration:"
grep arcblock /etc/subuid /etc/subgid 2>/dev/null || echo "Subuid/subgid not configured"
echo ""

echo "17. Check lingering status:"
loginctl show-user arcblock | grep Linger 2>/dev/null || echo "User not found in loginctl"
echo ""

echo "18. Check cloud-init final files:"
ls -la /home/arcblock/.setup-complete 2>/dev/null || echo "Setup completion marker not found"
echo ""

echo "======================================"
echo "Debugging complete. Save output for analysis."
echo "======================================"