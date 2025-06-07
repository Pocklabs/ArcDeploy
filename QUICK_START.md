# ArcDeploy Quick Start Guide

Deploy a production-ready Arcblock Blocklet Server in under 10 minutes with this streamlined guide.

## Prerequisites

- Hetzner Cloud account
- SSH key pair (we'll generate one if needed)
- 10 minutes of time

## Step 1: Clone Repository

```bash
git clone https://github.com/Pocklabs/ArcDeploy.git
cd ArcDeploy
```

## Step 2: Generate SSH Key (if needed)

```bash
# Generate new SSH key pair
ssh-keygen -t ed25519 -C "your-email@example.com"

# Display your public key (copy this)
cat ~/.ssh/id_ed25519.pub
```

Copy the entire output starting with `ssh-ed25519 AAAAC3...`

## Step 3: Configure Cloud-Init

Edit `cloud-init.yaml` and replace the SSH key placeholder:

```yaml
ssh_authorized_keys:
  - YOUR_ACTUAL_SSH_PUBLIC_KEY_HERE
```

**One-liner replacement:**
```bash
# Replace SSH key placeholder
sed -i 's/ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIReplaceWithYourActualEd25519PublicKey your-email@example.com/YOUR_ACTUAL_SSH_KEY_HERE/' cloud-init.yaml
```

## Step 4: Deploy to Hetzner Cloud

### Via Hetzner Console (Recommended)

1. Login to [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. Create new server:
   - **Location:** Any (nbg1 recommended)
   - **Image:** Ubuntu 22.04
   - **Type:** CX31 or higher
   - **Networking:** Default
   - **SSH Keys:** Skip (we use cloud-init)
   - **Cloud config:** Paste entire content of `cloud-init.yaml`
3. Click "Create & Buy now"

### Via API (Alternative)

```bash
export HETZNER_API_TOKEN="your-token-here"

curl -X POST \
  -H "Authorization: Bearer $HETZNER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "image": "ubuntu-22.04",
    "location": "nbg1",
    "name": "blocklet-server",
    "server_type": "cx31",
    "user_data": "'"$(cat cloud-init.yaml)"'"
  }' \
  https://api.hetzner.cloud/v1/servers
```

## Step 5: Wait for Deployment

The installation takes 5-10 minutes. You can monitor progress via:

- Hetzner Console (Server > Graphs)
- SSH once server is running: `sudo tail -f /var/log/cloud-init-output.log`

## Step 6: Access Your Server

Once deployment completes:

```bash
# SSH access (note custom port 2222)
ssh -p 2222 arcblock@YOUR_SERVER_IP

# Web interface
open http://YOUR_SERVER_IP:8080
```

## Verification Commands

```bash
# Check deployment status
sudo cloud-init status --long

# Check Blocklet Server
sudo systemctl status blocklet-server

# Test web interface
curl -I http://localhost:8080
```

## What Gets Installed

- **Blocklet Server:** Native Node.js installation
- **Nginx:** Reverse proxy and SSL termination
- **Security:** UFW firewall, Fail2ban, SSH hardening
- **Monitoring:** System logging and health checks
- **SSL/TLS:** Automatic certificate support

## Access Points

Your server will be accessible via:

- **SSH:** `ssh -p 2222 arcblock@YOUR_SERVER_IP`
- **Web UI:** `http://YOUR_SERVER_IP:8080`
- **Secure Web:** `https://YOUR_SERVER_IP:8443`
- **Admin Panel:** `http://YOUR_SERVER_IP:8080/.well-known/server/admin/`

## Firewall Ports

The following ports are automatically configured:

| Port | Protocol | Purpose |
|------|----------|---------|
| 2222 | TCP | SSH Access |
| 8080 | TCP | HTTP Web Interface |
| 8443 | TCP | HTTPS Web Interface |

## Troubleshooting

### Can't SSH to server
```bash
# Test connectivity
telnet YOUR_SERVER_IP 2222

# Check from Hetzner Console if SSH is working
```

### Web interface not accessible
```bash
# SSH to server first, then:
sudo systemctl status blocklet-server
sudo journalctl -u blocklet-server -f
```

### Cloud-init failed
```bash
# Check cloud-init logs
sudo tail -f /var/log/cloud-init-output.log
sudo cloud-init status --long
```

## Next Steps

1. **Secure your server:** Review firewall rules, update SSH keys
2. **Configure SSL:** Set up proper domain and SSL certificates
3. **Backup strategy:** Plan for data backup and recovery
4. **Monitoring:** Set up external monitoring for uptime
5. **Updates:** Plan for regular system and Blocklet updates

## Support

- **Issues:** [GitHub Issues](https://github.com/Pocklabs/ArcDeploy/issues)
- **Documentation:** [Main README](README.md)
- **Community:** [GitHub Discussions](https://github.com/Pocklabs/ArcDeploy/discussions)

---

**Total time:** ~10 minutes | **Cost:** ~€0.10/hour for CX31 server