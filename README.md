## 🛠️ Script Capabilities & Architecture

This script transforms a "vanilla" Ubuntu 24.04 VPS into a professional-grade AI development environment using a **Zero-Trust** security model.

### 🛡️ Security & Hardening
* **SSH Socket-to-Service Migration:** Ubuntu 24.04 uses `ssh.socket` by default, which can cause connectivity drops with VPNs. The script reverts this to the classic `ssh.service` for maximum reliability with Tailscale.
* **Root Account Disablement:** Disables direct root login to prevent brute-force attacks on the most targeted username.
* **Key-Based Authentication (No Passwords):** Enforces `PasswordAuthentication no`. Only holders of the specific private key can enter the system.
* **Zero-Trust Firewall (UFW):** Implements a strict "Deny by Default" policy. SSH access is restricted exclusively to the **Tailscale** private network interface (`tailscale0`).

### 🌪️ Networking & Connectivity
* **Tailscale Integration:** Automatically installs the Tailscale client, enabling a Mesh VPN tunnel. This hides your management ports from the public internet entirely.
* **Web-Ready Ports:** Pre-configures the firewall to allow HTTP (**80**) and HTTPS (**443**) traffic, preparing the server for future web deployments or OpenClaw dashboard exposure.

### 🧠 Runtime & Development Environment
* **Node.js 22 LTS:** Installs the latest Long Term Support version of Node.js using `fnm` (Fast Node Manager). This is optimized for high-performance AI streaming and WebSocket handling.
* **Docker Engine & Compose:** Installs the official Docker repository version (not the outdated `apt` default). This provides the **Security Sandboxing** required by OpenClaw to safely run untrusted code from messaging channels.
* **Non-Root Execution:** Automatically configures permissions so your primary user can manage Docker containers without requiring `sudo`, reducing accidental system-level risks.

### 📧 Automated Communication
* **msmtp (The System Voice):** A lightweight SMTP client configured to use Gmail as a relay. This allows the server to send outgoing emails for security alerts, maintenance reports, or AI-generated notifications.
* **Unattended Upgrades:** Activates Ubuntu's automated security patching system, ensuring the server stays up-to-date against new vulnerabilities without manual intervention.

---

### 📦 Key Components Table

| Component | Tool Used | Purpose |
| :--- | :--- | :--- |
| **OS** | Ubuntu 24.04 | Modern, stable Linux base (Noble Numbat). |
| **VPN** | Tailscale | Private network tunnel; hides server from public scans. |
| **Runtime** | Node.js 22 | Optimized engine for OpenClaw and modern JS apps. |
| **Sandboxing** | Docker Engine | Isolates AI sessions from the main OS files. |
| **Mail** | msmtp | Sends outbound alerts via Gmail SMTP. |
| **Node Manager** | fnm | Fast, reliable Node.js version management. |
| **Firewall** | UFW | Restricts all public traffic except intended web ports. |

### 🚀 How to Use This Professionally

#### **Method A: The "One-Liner" (Silent Pro Mode)**
Use this if you want to launch a server and walk away for a coffee. By exporting the variables first, the script runs entirely without human input.

Method A: The "One-Liner" Mode
Use this if you want to set everything up in a single command.

```bash
export NEW_USER="your-user-name" \
       SSH_KEY="your-ssh-key" \
       GMAIL_USER="your-email-address" \
       GMAIL_PASS="your-gmail-app-password"

curl -s [https://raw.githubusercontent.com/your-repo/infra-scripts/main/vps_template.sh](https://raw.githubusercontent.com/your-repo/infra-scripts/main/vps_template.sh) | bash
```

Method B: The "Interactive" Mode
If you run the script without setting variables, it will detect the missing information and prompt you for each detail step-by-step.

```bash
curl -s https://raw.githubusercontent.com/your-repo/infra-scripts/main/vps_template.sh | bash
```

[!IMPORTANT] Security Note: If you use Method A, your Gmail App Password may remain in your terminal's history. Run history -c after setup to clear it, or use a Private GitHub Repository for your personal script.

You have officially turned your manual server chores into a scalable infrastructure system. Have fun!
