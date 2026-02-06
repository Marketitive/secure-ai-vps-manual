#!/bin/bash
# 🛡️ Superclaw Personal Provisioner (Batu Edition)
# Purpose: One-click setup for Ubuntu 24.04 VPS
set -e

# --- 🛠️ CONFIGURATION (YOUR SECRETS) ---
MY_USER="ozturk"
MY_SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICD... batu@marketitive.com"
GMAIL_USER="batu@marketitive.com"
GMAIL_PASS="gusm tcka coys wusi" # App Password
RECIPIENT="dev@marketitive.com"

echo "🚀 Starting Personal Provisioning..."

# 1. System Updates & SSH Socket Fix
apt update && apt upgrade -y
apt install -y sudo curl unzip msmtp msmtp-mta bsd-mailx unattended-upgrades
systemctl stop ssh.socket && systemctl disable ssh.socket && systemctl mask ssh.socket
systemctl enable --now ssh.service

# 2. User Setup
id -u $MY_USER &>/dev/null || adduser --disabled-password --gecos "" $MY_USER
usermod -aG sudo $MY_USER
mkdir -p /home/$MY_USER/.ssh
echo "$MY_SSH_KEY" > /home/$MY_USER/.ssh/authorized_keys
chown -R $MY_USER:$MY_USER /home/$MY_USER/.ssh && chmod 700 /home/$MY_USER/.ssh && chmod 600 /home/$MY_USER/.ssh/authorized_keys

# 3. Environment: Docker & Node.js 22
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt update && apt install -y docker-ce docker-ce-cli containerd.io
usermod -aG docker $MY_USER

# Node.js via fnm (Running as ozturk)
sudo -u $MY_USER bash <<EOF
curl -fsSL https://fnm.vercel.app/install | bash
export PATH="/home/$MY_USER/.local/share/fnm:\$PATH"
eval "\$(fnm env)"
fnm install 22 && fnm use 22
npm install -g openclaw@latest
EOF

# 4. Networking & Firewall
curl -fsSL https://tailscale.com/install.sh | sh
ufw allow in on tailscale0 to any port 22
ufw allow 80/tcp && ufw allow 443/tcp
ufw default deny incoming && ufw default allow outgoing
echo "y" | ufw enable

# 5. Email (msmtp)
cat <<EOF > /home/$MY_USER/.msmtprc
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile /home/$MY_USER/msmtp.log
account gmail
host smtp.gmail.com
port 587
from $GMAIL_USER
user $GMAIL_USER
password $GMAIL_PASS
account default : gmail
EOF
chown $MY_USER:$MY_USER /home/$MY_USER/.msmtprc && chmod 600 /home/$MY_USER/.msmtprc

echo "✅ Setup Finished. Login with 'ssh ozturk@your-ip' then run 'tailscale up' and 'openclaw onboard'."