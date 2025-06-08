#!/bin/bash

echo "=== ArcDeploy Native Installation Debugging Script ==="
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

echo "4. Check Blocklet Server directory structure:"
echo "- Main directory:"
ls -la /opt/blocklet-server/ 2>/dev/null || echo "Directory not found"
echo ""

echo "- Data directory:"
ls -la /opt/blocklet-server/data/ 2>/dev/null || echo "Directory not found"
echo ""

echo "- Config directory:"
ls -la /opt/blocklet-server/config/ 2>/dev/null || echo "Directory not found"
echo ""

echo "- Logs directory:"
ls -la /opt/blocklet-server/logs/ 2>/dev/null || echo "Directory not found"
echo ""

echo "5. Check systemd service file:"
ls -la /etc/systemd/system/blocklet-server.service 2>/dev/null || echo "Service file not found"
echo ""

echo "6. Check Blocklet Server service status:"
sudo systemctl status blocklet-server --no-pager -l 2>/dev/null || echo "Service not found"
echo ""

echo "7. Check Node.js installation:"
node --version 2>/dev/null || echo "Node.js not found"
npm --version 2>/dev/null || echo "npm not found"
which node 2>/dev/null || echo "Node.js not in PATH"
echo ""

echo "8. Check Blocklet CLI installation:"
which blocklet 2>/dev/null || echo "Blocklet CLI not found in PATH"
sudo -u arcblock blocklet --version 2>/dev/null || echo "Blocklet CLI not accessible to arcblock user"
sudo -u arcblock npm list -g @blocklet/cli 2>/dev/null || echo "@blocklet/cli not installed globally"
echo ""

echo "9. Check nginx installation and status:"
nginx -v 2>/dev/null || echo "Nginx not installed"
sudo systemctl status nginx --no-pager 2>/dev/null || echo "Nginx service not found"
echo ""

echo "10. Check nginx configuration:"
ls -la /etc/nginx/sites-available/blocklet-server 2>/dev/null || echo "Nginx site config not found"
ls -la /etc/nginx/sites-enabled/blocklet-server 2>/dev/null || echo "Nginx site not enabled"
echo ""

echo "11. Check Redis installation and status:"
redis-server --version 2>/dev/null || echo "Redis not installed"
sudo systemctl status redis-server --no-pager 2>/dev/null || echo "Redis service not found"
echo ""

echo "12. Check Blocklet Server ports (8080/8443):"
netstat -tlnp 2>/dev/null | grep -E ":8080|:8443" || echo "Blocklet Server ports not listening"
echo ""

echo "13. Check HTTP endpoint (port 8080):"
curl -f http://localhost:8080 2>/dev/null || echo "Port 8080 not responding"
echo ""

echo "14. Check HTTPS endpoint (port 8443):"
curl -k -f https://localhost:8443 2>/dev/null || echo "Port 8443 not responding"
echo ""

echo "15. Check nginx proxy (port 80):"
curl -f http://localhost:80 2>/dev/null || echo "Nginx proxy not responding"
echo ""

echo "16. Check firewall status:"
sudo ufw status
echo ""

echo "17. Check SSH configuration:"
grep -E "^Port|^PasswordAuthentication|^PubkeyAuthentication" /etc/ssh/sshd_config
echo ""

echo "18. Check fail2ban status:"
sudo systemctl status fail2ban --no-pager -l
echo ""

echo "19. Check health check script:"
ls -la /opt/blocklet-server/healthcheck.sh 2>/dev/null || echo "Health check script not found"
echo ""

echo "20. Run health check manually:"
sudo -u arcblock /opt/blocklet-server/healthcheck.sh 2>/dev/null || echo "Health check failed or script not executable"
echo ""

echo "21. Check service logs (last 20 lines):"
sudo journalctl -u blocklet-server --no-pager -n 20 2>/dev/null || echo "No service logs found"
echo ""

echo "22. Check nginx logs (last 10 lines):"
sudo tail -n 10 /var/log/nginx/access.log 2>/dev/null || echo "Nginx access log not found"
sudo tail -n 10 /var/log/nginx/error.log 2>/dev/null || echo "Nginx error log not found"
echo ""

echo "23. Check cloud-init logs for errors:"
grep -i error /var/log/cloud-init.log 2>/dev/null | tail -10 || echo "No cloud-init errors found"
echo ""

echo "24. Check cloud-init completion marker:"
ls -la /opt/blocklet-server/.native-install-complete 2>/dev/null || echo "Installation completion marker not found"
echo ""

echo "25. Check disk space:"
df -h /opt/blocklet-server 2>/dev/null || echo "Cannot check disk space"
echo ""

echo "26. Check memory usage:"
free -h
echo ""

echo "27. Check system load:"
uptime
echo ""

echo "28. Check running processes:"
ps aux | grep -E "blocklet|nginx|redis" | grep -v grep
echo ""

echo "29. Check listening ports:"
netstat -tlnp 2>/dev/null | grep -E ":22|:80|:443|:2222|:8080|:8443" || echo "No relevant ports listening"
echo ""

echo "30. Check Blocklet Server configuration:"
sudo -u arcblock blocklet server config list 2>/dev/null || echo "Cannot read Blocklet Server configuration"
echo ""

echo "======================================"
echo "Debugging complete. Save output for analysis."
echo ""
echo "Quick Access Commands:"
echo "- Service status: sudo systemctl status blocklet-server"
echo "- Service logs: sudo journalctl -u blocklet-server -f"
echo "- Health check: sudo -u arcblock /opt/blocklet-server/healthcheck.sh"
echo "- Restart service: sudo systemctl restart blocklet-server"
echo "- Check web interface: http://$(hostname -I | awk '{print $1}'):8080"
echo "======================================"