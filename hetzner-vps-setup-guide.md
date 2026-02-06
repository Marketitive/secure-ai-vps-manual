# 🛡️ Secure VPS Setup Guide for Hetzner
**Target OS:** Ubuntu 24.04 LTS  
**Security Strategy:** Private tunnel via Tailscale + SSH key authentication + Firewall hardening

This guide walks you through setting up a secure, "zero-trust" VPS on Hetzner from scratch. By the end, your server will be invisible to the public internet for SSH access while remaining fully accessible to you through a private encrypted tunnel.

---

## Overview

| What You'll Achieve | Description |
|---------------------|-------------|
| **Private Access** | SSH only works through your Tailscale tunnel—public port 22 is blocked |
| **Key-Only Auth** | Passwords are disabled; only your SSH key works |
| **No Root Login** | Root access is disabled; you use a regular user with sudo |
| **Automated Protection** | UFW firewall protects your server on startup |
| **Docker Ready** | Run containerized applications easily |
| **Node.js 22 LTS** | JavaScript runtime for modern web applications |

---

## Prerequisites

- A [Hetzner Cloud](https://console.hetzner.cloud/) account
- A [Tailscale](https://tailscale.com/) account (free tier works)
- A Mac (or Linux) computer with Terminal access
- Basic familiarity with terminal commands

---

## Phase 1: Create Your SSH Key (On Your Mac)

Before creating the server, generate a secure SSH key on your local machine.

### 1.1 Generate an ED25519 Key

Open Terminal on your Mac and run:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/hetzner_key -C "your_email@example.com"
```

**What happens:**
- You'll be asked for a passphrase—**use a strong one** (this encrypts your key file)
- Two files are created:
  - `~/.ssh/hetzner_key` (private key—never share this)
  - `~/.ssh/hetzner_key.pub` (public key—this goes on the server)

### 1.2 Copy the Public Key

Display your public key to copy it:

```bash
cat ~/.ssh/hetzner_key.pub
```

Copy the entire output (starts with `ssh-ed25519` and ends with your email).

---

## Phase 2: Create the Server on Hetzner

### 2.1 Create a New Project

1. Log in to [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. Create  **a new Project**
3. Name your new project
4. Click **Add**

### 2.2 Create a New Server

1. Click **Add Server**
2. **Location:** Choose a datacenter near you
3. **Image:** Select **Ubuntu 24.04**
4. **Type:** Choose your server size (smallest is fine for starting)
5. **SSH Keys:** Check the box next to your key
6. Paste your copied public key
7. **Name:** Give your server a memorable name (e.g., "my-vps")
8. Click **Create & Buy now**

Write down the **IPv4 address** shown after creation—you'll need it.

---

## Phase 3: Initial Server Connection

### 3.1 Clear Old Host Keys (If Rebuilding)

If you've used this IP address before, clear the old record using the following command: (If this is your first time, you can skip to step 3.2)

```bash
ssh-keygen -R YOUR_SERVER_IP
```

### 3.2 Connect as Root

```bash
ssh -i ~/.ssh/hetzner_key root@YOUR_SERVER_IP
```

Type "yes" when asked about the host fingerprint. Enter your key passphrase when prompted.

You should see a welcome message and `root@ubuntu-...` prompt.

---

## Phase 4: System Update & User Creation

### 4.1 Update the System

Run these commands to update Ubuntu:

```bash
apt update && apt upgrade -y
```

> **Note:** If prompted about restarting services, press Enter to accept defaults.

### 4.2 Create Your User Account

Create a non-root user (replace `myuser` with your preferred username):

```bash
adduser myuser
```

**You'll be asked to:**
- Set a password (use a strong one—you'll need it for sudo commands)
- Fill in optional info (you can press Enter to skip)

### 4.3 Give Your User Admin Powers

```bash
usermod -aG sudo myuser
```

### 4.4 Copy SSH Key to Your User

Transfer your SSH key from root to your new user:

```bash
# Create the SSH directory
mkdir -p /home/myuser/.ssh

# Copy the authorized key
cp /root/.ssh/authorized_keys /home/myuser/.ssh/

# Set correct ownership
chown -R myuser:myuser /home/myuser/.ssh

# Set secure permissions
chmod 700 /home/myuser/.ssh
chmod 600 /home/myuser/.ssh/authorized_keys
```

---

## Phase 5: Fix Ubuntu 24.04 SSH Service

Ubuntu 24.04 uses a new "socket activation" system for SSH that can cause problems with VPN connections. We need to switch to the traditional SSH service.

Run these commands:

```bash
# Stop the socket-based SSH
systemctl stop ssh.socket
systemctl disable ssh.socket
systemctl mask ssh.socket

# Enable the traditional SSH service
systemctl enable --now ssh.service

# Verify SSH is listening
ss -tulpn | grep ssh
```

You should see output showing SSH listening on `0.0.0.0:22`.

---

## Phase 6: Install Tailscale (Private Tunnel)

Tailscale creates an encrypted tunnel between your devices. Once configured, you'll access your server through a private IP that's invisible to the internet.

### 6.1 Install Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

### 6.2 Authenticate Tailscale

```bash
tailscale up
```

**Important:** A URL will appear. Copy it, paste it in your browser, and log in to your Tailscale account to authorize this server.

After authorization, the terminal will say "Success!"

### 6.3 Get Your Private IP

```bash
tailscale ip -4
```

Write down this IP (starts with `100.`). This is your server's private address.

---

## Phase 7: Configure the Firewall

Now we lock down the public interface while keeping the Tailscale tunnel open.

### 7.1 Set Up Firewall Rules

```bash
# Allow all traffic from Tailscale (your private tunnel)
sudo ufw allow in on tailscale0

# Allow web traffic (if hosting websites)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Block everything else from the public internet
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Enable the firewall
sudo ufw enable
```

Type `y` when prompted.

---

## Phase 8: Harden SSH Configuration

### 8.1 Edit SSH Config

```bash
sudo nano /etc/ssh/sshd_config
```

### 8.2 Find and Change These Lines

Look for these settings and change them (remove the `#` or `//` if present):

```text
PermitRootLogin no
PasswordAuthentication no
```

### 8.3 Save and Exit

- Press `Ctrl + O` then `Enter` to save
- Press `Ctrl + X` to exit

### 8.4 Restart SSH

```bash
sudo systemctl restart ssh
```

---

## Phase 9: Set Up the Mac Shortcut

Before testing, set up a convenient shortcut on your Mac.

### 9.1 Edit SSH Config on Your Mac

Open a **new Terminal window** on your Mac and run:

```bash
nano ~/.ssh/config
```

### 9.2 Add This Entry

Replace the Tailscale IP with yours:

```text
Host my-vps
    HostName 100.x.y.z
    User myuser
    IdentityFile ~/.ssh/hetzner_key
```

Save with `Ctrl + O`, `Enter`, then exit with `Ctrl + X`.

---

## Phase 10: Test Your Connection

### 10.1 Enable Tailscale on Your Mac

Make sure Tailscale is running and connected on your Mac (check the menu bar icon).

### 10.2 Connect Using Your Shortcut

```bash
ssh my-vps
```

You should see the Ubuntu welcome message and your username prompt!

### 10.3 Verify Everything Works

Test your sudo access:

```bash
sudo whoami
```

Enter your user password—it should return `root`.

### 10.4 Reboot the Server

Apply any pending kernel updates:

```bash
sudo reboot
```

Wait 30-60 seconds, then reconnect:

```bash
ssh my-vps
```

---

## Phase 11: Install Docker & Docker Compose

Docker allows you to run applications in isolated containers, making deployment and management much easier.

### 11.1 Install Required Dependencies

```bash
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
```

### 11.2 Add Docker's Official GPG Key

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

### 11.3 Add Docker Repository

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 11.4 Install Docker Engine

```bash
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
```

### 11.5 Add Your User to Docker Group

This lets you run Docker commands without `sudo`:

```bash
sudo usermod -aG docker $USER
```

**Important:** Log out and back in (or run `newgrp docker`) for this to take effect.

### 11.6 Verify Docker Installation

```bash
docker --version
docker compose version
```

### 11.7 Test Docker

```bash
docker run hello-world
```

You should see a "Hello from Docker!" message.

---

## Phase 12: Install Node.js 22 LTS

Node.js is required for running JavaScript applications on your server.

### 12.1 Install Node Version Manager (nvm)

Using nvm makes it easy to install and switch between Node.js versions:

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
```

### 12.2 Load nvm

Run this command or log out and back in:

```bash
source ~/.bashrc
```

### 12.3 Install Node.js 22 LTS

```bash
nvm install 22
```

### 12.4 Set Node.js 22 as Default

```bash
nvm alias default 22
```

### 12.5 Verify Installation

```bash
node --version
npm --version
```

You should see versions like `v22.x.x` and `10.x.x`.

### 12.6 (Optional) Install Common Global Packages

```bash
npm install -g pm2 yarn
```

- **pm2**: Process manager for running Node.js apps in production
- **yarn**: Alternative package manager

---

## 🎉 Congratulations!

Your server is now secured with:

| Feature | Status |
|---------|--------|
| **SSH Key Authentication** | ✅ Enabled |
| **Password Login** | ❌ Disabled |
| **Root Login** | ❌ Disabled |
| **Public SSH Port** | ❌ Blocked by firewall |
| **Tailscale Tunnel** | ✅ Active |
| **UFW Firewall** | ✅ Enabled |
| **Docker & Docker Compose** | ✅ Installed |
| **Node.js 22 LTS** | ✅ Installed |

---

## Troubleshooting

### "Connection refused" when connecting

1. **Check Tailscale on your Mac**: Make sure it's connected
2. **Verify SSH is running** (via Hetzner Console): `sudo systemctl status ssh`
3. **Check firewall**: `sudo ufw status`

### Locked out completely

1. Go to [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. Select your server → Click the **Console** button (terminal icon)
3. Log in with your username and password
4. Run: `sudo ufw disable` to temporarily drop the firewall
5. Fix the issue, then re-enable: `sudo ufw enable`

### Need to reset root password

1. In Hetzner Console, go to **Rescue** → **Reset Root Password**
2. Use the new password in the web console

---

## Quick Reference

| Task | Command |
|------|---------|
| Connect to server | `ssh my-vps` |
| Check firewall status | `sudo ufw status` |
| Check Tailscale status | `tailscale status` |
| View Tailscale IP | `tailscale ip -4` |
| Restart SSH | `sudo systemctl restart ssh` |
| Update system | `sudo apt update && sudo apt upgrade -y` |
| Docker version | `docker --version` |
| List running containers | `docker ps` |
| Node.js version | `node --version` |
| Run Node app with pm2 | `pm2 start app.js` |

---

## What's Next?

Your server is ready for:

- **Deploy a web app** - Use Docker Compose to run your applications
- **Set up Nginx** - Serve websites and act as a reverse proxy
- **Add databases** - PostgreSQL, MySQL, or MongoDB (via Docker)
- **Monitoring** - Uptime Kuma, Prometheus, Grafana
- **CI/CD** - GitHub Actions with self-hosted runners

---

*Guide last updated: February 2026*
