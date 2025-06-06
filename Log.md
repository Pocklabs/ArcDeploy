arcblock@blocklet-server:~$ id arcblock
uid=1000(arcblock) gid=1001(arcblock) groups=1001(arcblock),100(users),1000(admin)




arcblock@blocklet-server:~$ sudo cat /var/log/cloud-init.log | tail -50
2025-06-06 01:02:06,550 - modules.py[DEBUG]: Running module ssh-authkey-fingerprints (<module 'cloudinit.config.cc_ssh_authkey_fingerprints' from '/usr/lib/python3/dist-packages/cloudinit/config/cc_ssh_authkey_fingerprints.py'>) with frequency once-per-instance
2025-06-06 01:02:06,550 - handlers.py[DEBUG]: start: modules-final/config-ssh-authkey-fingerprints: running config-ssh-authkey-fingerprints with frequency once-per-instance
2025-06-06 01:02:06,550 - util.py[DEBUG]: Writing to /var/lib/cloud/instances/65303520/sem/config_ssh_authkey_fingerprints - wb: [644] 24 bytes
2025-06-06 01:02:06,552 - helpers.py[DEBUG]: Running config-ssh-authkey-fingerprints using lock (<FileLock using file '/var/lib/cloud/instances/65303520/sem/config_ssh_authkey_fingerprints'>)
2025-06-06 01:02:06,553 - util.py[DEBUG]: Reading from /etc/ssh/sshd_config (quiet=False)
2025-06-06 01:02:06,553 - util.py[DEBUG]: Reading 3254 bytes from /etc/ssh/sshd_config
2025-06-06 01:02:06,553 - util.py[DEBUG]: Reading from /home/arcblock/.ssh/authorized_keys (quiet=False)
2025-06-06 01:02:06,553 - util.py[DEBUG]: Reading 103 bytes from /home/arcblock/.ssh/authorized_keys
2025-06-06 01:02:06,555 - handlers.py[DEBUG]: finish: modules-final/config-ssh-authkey-fingerprints: SUCCESS: config-ssh-authkey-fingerprints ran successfully and took 0.005 seconds
2025-06-06 01:02:06,555 - modules.py[DEBUG]: Running module keys-to-console (<module 'cloudinit.config.cc_keys_to_console' from '/usr/lib/python3/dist-packages/cloudinit/config/cc_keys_to_console.py'>) with frequency once-per-instance
2025-06-06 01:02:06,556 - handlers.py[DEBUG]: start: modules-final/config-keys-to-console: running config-keys-to-console with frequency once-per-instance
2025-06-06 01:02:06,556 - util.py[DEBUG]: Writing to /var/lib/cloud/instances/65303520/sem/config_keys_to_console- wb: [644] 23 bytes
2025-06-06 01:02:06,556 - helpers.py[DEBUG]: Running config-keys-to-console using lock (<FileLock using file '/var/lib/cloud/instances/65303520/sem/config_keys_to_console'>)
2025-06-06 01:02:06,557 - subp.py[DEBUG]: Running command ['/usr/lib/cloud-init/write-ssh-key-fingerprints', '', ''] with allowed return codes [0] (shell=False, capture=True)
2025-06-06 01:02:06,584 - performance.py[DEBUG]: Running ['/usr/lib/cloud-init/write-ssh-key-fingerprints', '', ''] took 0.026 seconds
2025-06-06 01:02:06,585 - handlers.py[DEBUG]: finish: modules-final/config-keys-to-console: SUCCESS: config-keys-to-console ran successfully and took 0.028 seconds
2025-06-06 01:02:06,585 - modules.py[DEBUG]: Running module install-hotplug (<module 'cloudinit.config.cc_install_hotplug' from '/usr/lib/python3/dist-packages/cloudinit/config/cc_install_hotplug.py'>) with frequency once-per-instance
2025-06-06 01:02:06,585 - handlers.py[DEBUG]: start: modules-final/config-install-hotplug: running config-install-hotplug with frequency once-per-instance
2025-06-06 01:02:06,585 - util.py[DEBUG]: Writing to /var/lib/cloud/instances/65303520/sem/config_install_hotplug- wb: [644] 23 bytes
2025-06-06 01:02:06,586 - helpers.py[DEBUG]: Running config-install-hotplug using lock (<FileLock using file '/var/lib/cloud/instances/65303520/sem/config_install_hotplug'>)
2025-06-06 01:02:06,586 - util.py[DEBUG]: Reading from /var/lib/cloud/hotplug.enabled (quiet=False)
2025-06-06 01:02:06,586 - util.py[DEBUG]: File not found: /var/lib/cloud/hotplug.enabled
2025-06-06 01:02:06,586 - stages.py[DEBUG]: Allowed events: {<EventScope.NETWORK: 'network'>: {<EventType.BOOT_NEW_INSTANCE: 'boot-new-instance'>}}
2025-06-06 01:02:06,586 - stages.py[DEBUG]: Event Denied: scopes=['network'] EventType=hotplug
2025-06-06 01:02:06,586 - cc_install_hotplug.py[DEBUG]: Skipping hotplug install, not enabled
2025-06-06 01:02:06,586 - handlers.py[DEBUG]: finish: modules-final/config-install-hotplug: SUCCESS: config-install-hotplug ran successfully and took 0.001 seconds
2025-06-06 01:02:06,586 - modules.py[DEBUG]: Running module final-message (<module 'cloudinit.config.cc_final_message' from '/usr/lib/python3/dist-packages/cloudinit/config/cc_final_message.py'>) with frequency always
2025-06-06 01:02:06,586 - handlers.py[DEBUG]: start: modules-final/config-final-message: running config-final-message with frequency always
2025-06-06 01:02:06,587 - helpers.py[DEBUG]: Running config-final-message using lock (<cloudinit.helpers.DummyLock object at 0x7f6f2416a260>)
2025-06-06 01:02:06,587 - util.py[DEBUG]: Reading from /proc/uptime (quiet=False)
2025-06-06 01:02:06,587 - util.py[DEBUG]: Reading 13 bytes from /proc/uptime
2025-06-06 01:02:06,587 - log_util.py[DEBUG]: Arcblock Blocklet Server setup completed!

Access Information:
- SSH: ssh -p 2222 arcblock@YOUR_SERVER_IP
- Web Interface: http://YOUR_SERVER_IP:8089
- Service Status: systemctl status blocklet-server
- Container Status: sudo -u arcblock podman ps

Setup completed successfully!
2025-06-06 01:02:06,587 - util.py[DEBUG]: Writing to /var/lib/cloud/instance/boot-finished - wb: [644] 69 bytes
2025-06-06 01:02:06,588 - handlers.py[DEBUG]: finish: modules-final/config-final-message: SUCCESS: config-final-message ran successfully and took 0.001 seconds
2025-06-06 01:02:06,588 - main.py[DEBUG]: Ran 12 modules with 0 failures
2025-06-06 01:02:06,588 - util.py[DEBUG]: Reading from /proc/uptime (quiet=False)
2025-06-06 01:02:06,588 - util.py[DEBUG]: Reading 13 bytes from /proc/uptime
2025-06-06 01:02:06,589 - atomic_helper.py[DEBUG]: Atomically writing to file /var/lib/cloud/data/status.json (via temporary file /var/lib/cloud/data/tmpl2a5ghqp) - w: [644] 1571 bytes/chars
2025-06-06 01:02:06,589 - atomic_helper.py[DEBUG]: Atomically writing to file /var/lib/cloud/data/result.json (via temporary file /var/lib/cloud/data/tmpy9ar1e9k) - w: [644] 174 bytes/chars
2025-06-06 01:02:06,589 - util.py[DEBUG]: Creating symbolic link from '/run/cloud-init/result.json' => '../../var/lib/cloud/data/result.json'
2025-06-06 01:02:06,590 - performance.py[DEBUG]: cloud-init stage: 'modules-final' took 65.073 seconds
2025-06-06 01:02:06,590 - handlers.py[DEBUG]: finish: modules-final: SUCCESS: running modules for final



arcblock@blocklet-server:~$ sudo cat /var/log/cloud-init-output.log | tail -50
Get:1 https://deb.nodesource.com/node_22.x nodistro InRelease [12.1 kB]
Hit:2 https://mirror.hetzner.com/ubuntu/packages jammy InRelease
Hit:3 https://mirror.hetzner.com/ubuntu/packages jammy-updates InRelease
Hit:4 https://mirror.hetzner.com/ubuntu/packages jammy-backports InRelease
Hit:5 https://mirror.hetzner.com/ubuntu/security jammy-security InRelease
Get:6 https://deb.nodesource.com/node_22.x nodistro/main amd64 Packages [6,478 B]
Fetched 18.6 kB in 1s (28.2 kB/s)
Reading package lists...
2025-06-06 01:01:59 - Repository configured successfully.
2025-06-06 01:01:59 - To install Node.js, run: apt-get install nodejs -y
2025-06-06 01:01:59 - You can use N|solid Runtime as a node.js alternative
2025-06-06 01:01:59 - To install N|solid Runtime, run: apt-get install nsolid -y

Reading package lists...
Building dependency tree...
Reading state information...
The following NEW packages will be installed:
nodejs
0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
Need to get 36.9 MB of archives.
After this operation, 225 MB of additional disk space will be used.
Get:1 https://deb.nodesource.com/node_22.x nodistro/main amd64 nodejs amd64 22.16.0-1nodesource1 [36.9 MB]
dpkg-preconfigure: unable to re-open stdin: No such file or directory
Fetched 36.9 MB in 0s (111 MB/s)
Selecting previously unselected package nodejs.
(Reading database ... 44529 files and directories currently installed.)
Preparing to unpack .../nodejs_22.16.0-1nodesource1_amd64.deb ...
Unpacking nodejs (22.16.0-1nodesource1) ...
Setting up nodejs (22.16.0-1nodesource1) ...
Processing triggers for man-db (2.10.2-1) ...
Collecting podman-compose
Downloading podman_compose-1.4.0-py2.py3-none-any.whl (44 kB)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 44.5/44.5 KB 4.1 MB/s eta 0:00:00
Collecting python-dotenv
Downloading python_dotenv-1.1.0-py3-none-any.whl (20 kB)
Requirement already satisfied: pyyaml in /usr/lib/python3/dist-packages (from podman-compose) (5.4.1)
Installing collected packages: python-dotenv, podman-compose
Successfully installed podman-compose-1.4.0 python-dotenv-1.1.0
WARNING: Running pip as the 'root' user can result in broken permissions and conflicting behaviour with the system package manager. It is recommended to use a virtual environment instead: https://pip.pypa.io/warnings/venv
/var/lib/cloud/instance/scripts/runcmd: 8: /home/arcblock/setup-post-install.sh: not found
WARNING Service may still be starting
Arcblock Blocklet Server setup completed!

Access Information:
- SSH: ssh -p 2222 arcblock@YOUR_SERVER_IP
- Web Interface: http://YOUR_SERVER_IP:8089
- Service Status: systemctl status blocklet-server
- Container Status: sudo -u arcblock podman ps

Setup completed successfully!






arcblock@blocklet-server:~$ sudo cat /var/lib/cloud/instance/user-data.txt
#cloud-config

users:
- name: arcblock
groups: users, admin
sudo: ALL=(ALL) NOPASSWD:ALL
shell: /bin/bash
ssh_authorized_keys:
- ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIReplaceWithYourActualEd25519PublicKey your-email@example.com

packages:
- curl
- wget
- git
- fail2ban
- ufw
- podman
- python3
- python3-pip

package_update: true
package_upgrade: true

write_files:
- path: /home/arcblock/blocklet-server/compose.yaml
content: |
version: '3.8'
services:
blocklet-server:
image: arcblock/blocklet-server:latest
container_name: blocklet-server
restart: unless-stopped
ports:
- "8089:8089"
- "80:80"
- "443:443"
volumes:
- blocklet-data:/opt/abtnode/data
- blocklet-config:/opt/abtnode/config
environment:
- ABT_NODE_LOG_LEVEL=info
- ABT_NODE_ENV=production
- ABT_NODE_HOST=0.0.0.0
- ABT_NODE_PORT=8089
healthcheck:
test: ["CMD", "curl", "-f", "http://localhost:8089/api/did"]
interval: 30s
timeout: 10s
retries: 3
volumes:
blocklet-data:
blocklet-config:
owner: arcblock:arcblock
permissions: '0644'

- path: /etc/systemd/system/blocklet-server.service
content: |
[Unit]
Description=Arcblock Blocklet Server
After=network-online.target
Wants=network-online.target
RequiresMountsFor=/home/arcblock

[Service]
Type=oneshot
RemainAfterExit=yes
User=arcblock
Group=arcblock
WorkingDirectory=/home/arcblock/blocklet-server
Environment=XDG_RUNTIME_DIR=/run/user/1000
ExecStartPre=/usr/bin/podman compose down --remove-orphans
ExecStart=/usr/bin/podman compose up -d
ExecStop=/usr/bin/podman compose down --timeout 30
TimeoutStartSec=300
TimeoutStopSec=120

[Install]
WantedBy=multi-user.target
owner: root:root
permissions: '0644'

- path: /etc/fail2ban/jail.local
content: |
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 2222
banaction = iptables-multiport
owner: root:root
permissions: '0644'

- path: /tmp/ssh-config.txt
content: |
Port 2222
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
X11Forwarding no
AllowTcpForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers arcblock
owner: root:root
permissions: '0644'

- path: /home/arcblock/setup-post-install.sh
content: |
#!/bin/bash
set -e

echo "Starting post-installation setup..."

# Configure Podman for rootless
echo 'arcblock:100000:65536' >> /etc/subuid
echo 'arcblock:100000:65536' >> /etc/subgid
loginctl enable-linger arcblock

# Setup Podman socket
sudo -u arcblock systemctl --user enable podman.socket
sudo -u arcblock systemctl --user start podman.socket

# Install Blocklet CLI
sudo -u arcblock npm install -g @arcblock/cli

# Pull container image
sudo -u arcblock podman pull arcblock/blocklet-server:latest

# Configure SSH
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
cp /tmp/ssh-config.txt /etc/ssh/sshd_config

# Configure firewall
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 2222/tcp
ufw allow 8089/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Start services
systemctl enable fail2ban
systemctl start fail2ban
systemctl daemon-reload
systemctl enable blocklet-server
systemctl start blocklet-server

# Wait for service
echo "Waiting for Blocklet Server to become ready..."
for i in {1..24}; do
if curl -sf http://localhost:8089/api/did >/dev/null 2>&1; then
echo "Blocklet Server is ready!"
break
fi
echo "Attempt $i/24 - waiting 15 seconds..."
sleep 15
done

# Restart SSH
systemctl restart ssh

# Clean up
rm -f /tmp/ssh-config.txt

echo "Setup completed at $(date)" > /home/arcblock/setup-complete.log
echo "Post-installation setup completed successfully!"
owner: root:root
permissions: '0755'

runcmd:
- mkdir -p /home/arcblock/blocklet-server
- chown -R arcblock:arcblock /home/arcblock

# Install Node.js LTS
- curl -fsSL https://deb.nodesource.com/setup_lts.x -o /tmp/nodesource_setup.sh
- bash /tmp/nodesource_setup.sh
- apt-get install -y nodejs

# Install podman-compose
- pip3 install podman-compose

# Run post-installation setup
- /home/arcblock/setup-post-install.sh

# Final verification
- systemctl is-active --quiet blocklet-server || echo "WARNING Service may still be starting"

# Create completion marker
- touch /home/arcblock/.setup-complete
- chown arcblock:arcblock /home/arcblock/.setup-complete

timezone: UTC
hostname: blocklet-server
package_reboot_if_required: false

final_message: |
Arcblock Blocklet Server setup completed!

Access Information:
- SSH: ssh -p 2222 arcblock@YOUR_SERVER_IP
- Web Interface: http://YOUR_SERVER_IP:8089
- Service Status: systemctl status blocklet-server
- Container Status: sudo -u arcblock podman ps

Setup completed successfully!







arcblock@blocklet-server:~$ cat /etc/passwd | grep -E "(arcblock|1000)"
arcblock:x:1000:1001::/home/arcblock:/bin/bash






arcblock@blocklet-server:~$ ls -la /home/ | grep arcbloc
drwxr-xr-x  7 arcblock arcblock 4096 Jun  6 11:52 arcblock







arcblock@blocklet-server:~$ ls -la /etc/systemd/system/ | grep blocklet
No cmd output.
