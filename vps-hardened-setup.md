This is the "Zero-to-Hero" blueprint. It covers every command, every common error, and every "why" behind the security choices. This is designed so that even if this is your first time seeing a terminal, you can build a professional-grade AI server.

---

## **The Ultimate "Superclaw" VPS Hardening & AI Environment Guide**

**Goal:** A completely hidden, self-updating server running **Node.js 22** and **Docker**, ready for **OpenClaw**.

---

### **Phase 1: Your Digital Passport (Local Mac)**

Before the server exists, you need a "Key" that isn't a password.

1. **Open "Terminal" on your Mac** (Cmd + Space, type "Terminal").
2. **Generate your key:** Copy and paste this:
```bash
ssh-keygen -t ed25519 -f ~/.ssh/superclaw_key -C "batu@marketitive.com"

```


* *Note: If it asks for a passphrase, just hit Enter twice for no password.*


3. **Get the code for the server:**
```bash
cat ~/.ssh/superclaw_key.pub

```


* **Action:** Copy the long string that starts with `ssh-ed25519`. This is your "Public Key".



---

### **Phase 2: The First Handshake (Server Provisioning)**

1. **Rent your VPS:** Choose **Ubuntu 24.04**.
2. **Add SSH Key:** In the provider's dashboard, look for "SSH Keys" and paste your code there.
3. **Log in for the first time:**
```bash
ssh -i ~/.ssh/superclaw_key root@YOUR_SERVER_IP

```



---

### **Phase 3: Creating Your "Safe" User**

Working as `root` is dangerous. We create a user named `ozturk` and give it power.

1. **Create user and set password:**
```bash
adduser ozturk
usermod -aG sudo ozturk

```


2. **Give `ozturk` your keys:**
```bash
mkdir -p /home/ozturk/.ssh
cp /root/.ssh/authorized_keys /home/ozturk/.ssh/
chown -R ozturk:ozturk /home/ozturk/.ssh
chmod 700 /home/ozturk/.ssh
chmod 600 /home/ozturk/.ssh/authorized_keys

```


3. **Fix Ubuntu 24.04 SSH Service:**
Ubuntu 24.04 uses a new "Socket" system that often breaks Tailscale connections. We force it back to the reliable "Classic" mode:
```bash
sudo systemctl stop ssh.socket
sudo systemctl disable ssh.socket
sudo systemctl mask ssh.socket
sudo systemctl enable --now ssh.service

```



---

### **Phase 4: The Invisibility Cloak (Tailscale)**

Tailscale creates a private tunnel. Once this is on, your server is no longer on the "public" internet for management.

1. **Install:**
```bash
curl -fsSL https://tailscale.com/install.sh | sh

```


2. **Connect:**
```bash
sudo tailscale up

```


* **Action:** Click the link it shows you and log in.


3. **Get your Private IP:**
```bash
tailscale ip -4

```


* **Action:** Save this IP (it likely starts with `100.x.x.x`). You will use this from now on.



---

### **Phase 5: Locking the Fortress (Firewall & SSH)**

Now we tell the server: "Only talk to me through the Tailscale tunnel".

1. **Set Firewall Rules:**
```bash
sudo ufw allow in on tailscale0 to any port 22
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable

```


2. **Kill Password Logins:**
```bash
sudo nano /etc/ssh/sshd_config

```


* Find `PermitRootLogin` and set it to `no`.
* Find `PasswordAuthentication` and set it to `no`.
* **Save:** `Ctrl+O`, `Enter`. **Exit:** `Ctrl+X`.


3. **Apply:** `sudo systemctl restart ssh`.

---

### **Phase 6: The "Brain" (Node.js 22 LTS)**

OpenClaw needs the latest Node.js to think.

1. **Install the Manager:**
```bash
sudo apt install unzip -y
curl -fsSL https://fnm.vercel.app/install | bash
source ~/.bashrc

```


2. **Install Node:**
```bash
fnm install 22
fnm use 22

```



---

### **Phase 7: The "Security Cells" (Docker)**

Docker creates isolated "sandboxes" so the AI can run code without touching your actual server files.

1. **Add Docker's official source:**
```bash
sudo apt update && sudo apt install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update

```


2. **Install Engine:**
```bash
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

```


3. **Permission Fix:**
```bash
sudo usermod -aG docker ozturk
newgrp docker

```



---

### **Phase 8: Email Notifications (The Voice)**

So your server can email you about updates or security issues.

1. **Install:** `sudo apt install msmtp msmtp-mta bsd-mailx -y`
2. **Config:** `nano ~/.msmtprc`
```text
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile /home/ozturk/msmtp.log

account gmail
host smtp.gmail.com
port 587
from batu@marketitive.com
user batu@marketitive.com
password YOUR_16_CHAR_GMAIL_APP_PASSWORD

account default : gmail

```


3. **Lock:** `chmod 600 ~/.msmtprc`

---

### **Phase 9: The Mac Shortcut**

On your **Mac**, make it so you only have to type `ssh superclaw`.

1. `nano ~/.ssh/config`
2. Paste this:
```text
Host superclaw
    HostName 100.X.X.X (Your Tailscale IP)
    User ozturk
    IdentityFile ~/.ssh/superclaw_key

```



---

### **🏁 Final Result & Next Step**

Your server is now a secure, invisible AI host. To install OpenClaw, you just need to run:

```bash
npm install -g openclaw@latest && openclaw onboard --install-daemon

```