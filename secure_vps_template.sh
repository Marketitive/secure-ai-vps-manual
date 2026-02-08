#!/bin/bash

# 🛡️ Ultra-Secure n8n Environment (2026)
# Stack: Ubuntu 24.04, Tailscale, Docker, Cloudflared, Caddy

set -e 

if [[ $EUID -ne 0 ]]; then 
   echo "❌ This script must be run as root." 
   exit 1
fi

# --- 1. INTERACTIVE INPUT ---
[[ -z "${NEW_USER}" ]] && read -p "Enter desired username: " NEW_USER
[[ -z "${SSH_KEY}" ]] && read -p "Paste your Public SSH Key: " SSH_KEY

echo "🚀 Starting Provisioning..."

# --- 2. SYSTEM & SWAP ---
apt update && apt upgrade -y
apt install -y sudo curl unzip fail2ban ufw

# Create 2GB Swap for n8n stability
if [ ! -f /swapfile ]; then
    fallocate -l 2G /swapfile && chmod 600 /swapfile
    mkswap /swapfile && swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# SSH Socket Fix for Ubuntu 24.04
systemctl stop ssh.socket && systemctl disable ssh.socket && systemctl mask ssh.socket
systemctl enable --now ssh.service

# --- 3. USER MANAGEMENT ---
id -u "$NEW_USER" &>/dev/null || adduser --disabled-password --gecos "" "$NEW_USER"
echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$NEW_USER"

mkdir -p "/home/$NEW_USER/.ssh"
echo "$SSH_KEY" > "/home/$NEW_USER/.ssh/authorized_keys"
chown -R "$NEW_USER:$NEW_USER" "/home/$NEW_USER/.ssh"
chmod 700 "/home/$NEW_USER/.ssh"

# --- 4. DOCKER INSTALL ---
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker "$NEW_USER"

# --- 5. TAILSCALE & FIREWALL ---
curl -fsSL https://tailscale.com/install.sh | sh

echo "🧱 Hardening Firewall..."
ufw default deny incoming
ufw default allow outgoing
# Allow SSH ONLY through Tailscale
ufw allow in on tailscale0 to any port 22
echo "y" | ufw enable

# --- 6. SSH HARDENING ---
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
systemctl restart ssh

echo "✅ System Hardened! Use 'sudo tailscale up' to finish."
