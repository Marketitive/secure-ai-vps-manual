#!/bin/bash

# 🛡️ Universal VPS Hardening & AI Environment Template (2026)
# Target: Ubuntu 24.04 (Noble Numbat)
# Features: SSH Hardening, Tailscale (Auto-Auth), Docker, Node.js 22, msmtp

# --- 1. PRE-FLIGHT CHECKS ---
set -e 
if [[ $EUID -ne 0 ]]; then 
   echo "❌ This script must be run as root (use sudo)." 
   exit 1
fi

# --- 2. INTERACTIVE / SILENT INPUT ---
[[ -z "${NEW_USER}" ]] && read -p "Enter desired username: " NEW_USER
[[ -z "${SSH_KEY}" ]] && read -p "Paste your Public SSH Key: " SSH_KEY
[[ -z "${GMAIL_USER}" ]] && read -p "Enter Gmail address for alerts: " GMAIL_USER
[[ -z "${GMAIL_PASS}" ]] && read -p "Enter Gmail App Password: " GMAIL_PASS
[[ -z "${TS_AUTH_KEY}" ]] && read -p "Enter Tailscale Auth Key (Optional - hit Enter to skip): " TS_AUTH_KEY

echo "🚀 Provisioning process started..."

# --- 3. SYSTEM UPDATES & SSH FIXES ---
apt update && apt upgrade -y
apt install -y sudo curl unzip msmtp msmtp-mta bsd-mailx unattended-upgrades
systemctl stop ssh.socket && systemctl disable ssh.socket && systemctl mask ssh.socket
systemctl enable --now ssh.service

# --- 4. IDENTITY MANAGEMENT ---
id -u "$NEW_USER" &>/dev/null || adduser --disabled-password --gecos "" "$NEW_USER"
echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$NEW_USER"
mkdir -p "/home/$NEW_USER/.ssh"
echo "$SSH_KEY" > "/home/$NEW_USER/.ssh/authorized_keys"
chown -R "$NEW_USER:$NEW_USER" "/home/$NEW_USER/.ssh"
chmod 700 "/home/$NEW_USER/.ssh" && chmod 600 "/home/$NEW_USER/.ssh/authorized_keys"

# --- 5. THE BRAIN: NODE.JS 22 ---
sudo -u "$NEW_USER" bash <<EOF
curl -fsSL https://fnm.vercel.app/install | bash
export PATH="/home/$NEW_USER/.local/share/fnm:\$PATH"
eval "\$(fnm env)"
fnm install 22 && fnm use 22
EOF

# --- 6. THE CELLS: DOCKER ENGINE ---
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker "$NEW_USER"

# --- 7. THE CLOAK: TAILSCALE (AUTO-AUTH) ---
curl -fsSL https://tailscale.com/install.sh | sh
if [ -n "$TS_AUTH_KEY" ]; then
    echo "🌪️ Authenticating Tailscale automatically..."
    tailscale up --auth-key="$TS_AUTH_KEY" --hostname="superclaw-$(hostname)"
else
    echo "⚠️ No Auth Key provided. Tailscale will require manual login later."
fi

# --- 8. THE SHIELD: FIREWALL ---
ufw allow in on tailscale0 to any port 22
ufw allow 80/tcp && ufw allow 443/tcp
ufw default deny incoming && ufw default allow outgoing
echo "y" | ufw enable

# --- 9. THE VOICE: MSMTP EMAIL ---
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
chown "$NEW_USER:$NEW_USER" "/home/$NEW_USER/.msmtprc" && chmod 600 "/home/$NEW_USER/.msmtprc"

# --- 10. SECURITY HARDENING ---
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh

echo "✅ PROVISIONING COMPLETE!"