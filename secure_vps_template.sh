#!/bin/bash

# 🛡️ Universal VPS Hardening & AI Environment Template (2026)
# Target: Ubuntu 24.04 (Noble Numbat)
# Features: SSH Hardening, Tailscale, Docker, Node.js 22, msmtp

# --- 1. PRE-FLIGHT CHECKS ---
set -e # Exit on any error
if [[ $EUID -ne 0 ]]; then 
   echo "❌ This script must be run as root (use sudo)." 
   exit 1
fi

# --- 2. INTERACTIVE INPUT ---
# If variables aren't already set, ask the user.
[[ -z "${NEW_USER}" ]] && read -p "Enter desired username (e.g., ozturk): " NEW_USER
[[ -z "${SSH_KEY}" ]] && read -p "Paste your Public SSH Key: " SSH_KEY
[[ -z "${GMAIL_USER}" ]] && read -p "Enter Gmail address for alerts: " GMAIL_USER
[[ -z "${GMAIL_PASS}" ]] && read -p "Enter Gmail App Password (16 chars): " GMAIL_PASS

echo "🚀 Provisioning process started for $NEW_USER..."

# --- 3. SYSTEM UPDATES & SSH FIXES ---
echo "📦 Updating system packages..."
apt update && apt upgrade -y
apt install -y sudo curl unzip msmtp msmtp-mta bsd-mailx unattended-upgrades

# Ubuntu 24.04 SSH Socket Fix (Switch to Classic Service)
echo "🔧 Fixing SSH Service for Tailscale compatibility..."
systemctl stop ssh.socket && systemctl disable ssh.socket && systemctl mask ssh.socket
systemctl enable --now ssh.service

# --- 4. IDENTITY MANAGEMENT ---
echo "👤 Creating user: $NEW_USER..."
id -u "$NEW_USER" &>/dev/null || adduser --disabled-password --gecos "" "$NEW_USER"
echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$NEW_USER"

# Sync SSH Keys
mkdir -p "/home/$NEW_USER/.ssh"
echo "$SSH_KEY" > "/home/$NEW_USER/.ssh/authorized_keys"
chown -R "$NEW_USER:$NEW_USER" "/home/$NEW_USER/.ssh"
chmod 700 "/home/$NEW_USER/.ssh"
chmod 600 "/home/$NEW_USER/.ssh/authorized_keys"

# --- 5. THE BRAIN: NODE.JS 22 ---
echo "🧠 Installing Node.js 22 (via fnm)..."
sudo -u "$NEW_USER" bash <<EOF
curl -fsSL https://fnm.vercel.app/install | bash
export PATH="/home/$NEW_USER/.local/share/fnm:\$PATH"
eval "\$(fnm env)"
fnm install 22 && fnm use 22
EOF

# --- 6. THE CELLS: DOCKER ENGINE ---
echo "🐳 Installing Docker Engine..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker "$NEW_USER"

# --- 7. THE CLOAK: TAILSCALE & FIREWALL ---
echo "🌪️ Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

echo "🧱 Configuring Firewall..."
ufw allow in on tailscale0 to any port 22
ufw allow 80/tcp
ufw allow 443/tcp
ufw default deny incoming
ufw default allow outgoing
echo "y" | ufw enable

# --- 8. THE VOICE: MSMTP EMAIL ---
echo "📧 Configuring system mail..."
cat <<EOF > "/home/$NEW_USER/.msmtprc"
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile /home/$NEW_USER/msmtp.log

account gmail
host smtp.gmail.com
port 587
from $GMAIL_USER
user $GMAIL_USER
password $GMAIL_PASS

account default : gmail
EOF
chown "$NEW_USER:$NEW_USER" "/home/$NEW_USER/.msmtprc"
chmod 600 "/home/$NEW_USER/.msmtprc"

# --- 9. SECURITY HARDENING ---
echo "🔒 Disabling Root & Password login..."
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh

echo "✅ PROVISIONING COMPLETE!"
echo "-------------------------------------------------------"
echo "1. Run 'sudo tailscale up' to join your network."
echo "2. Switch to your user: su - $NEW_USER"
echo "3. Run OpenClaw: npm install -g openclaw@latest && openclaw onboard"
echo "-------------------------------------------------------"