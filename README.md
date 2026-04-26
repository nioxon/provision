# NioxPlay Provision CLI

```text
    _   ___           ____  __           
   / | / (_)___  _  _/ __ \/ /___ ___  __
  /  |/ / / __ \| |/_/ /_/ / / __ `/ / / /
 / /|  / / /_/ />  </ ____/ / /_/ / /_/ / 
/_/ |_/_/\____/_/|_/_/   /_/\__,_/\__, /  
                                 /____/   
```

**Enterprise Provisioning & Captive Portal CLI** built for local, offline, and bare-metal Ubuntu servers. 

NioxPlay Provision is an ultra-fast, visually polished command-line application that automates the deployment of the LEMP stack, manages Laravel/HTML sites, configures secure SSL, and routes offline networks into a fully functional Captive Portal (perfect for buses, cafes, or local offline environments).

---

## 🚀 Features

- **Full LEMP+ Stack:** Automatically installs Nginx, PHP 8.3 (with FPM & Composer), MariaDB (MySQL), Node.js (v22), Redis, and Supervisor.
- **Captive Portal Routing:** Installs and configures `dnsmasq` and `iptables` to intercept offline WiFi traffic and redirect users to a local Welcome Page (10.10.10.2).
- **Let's Encrypt DNS-01 Validation:** Generate globally trusted, warning-free SSL certificates for your local offline sites using Cloudflare APIs.
- **Automated Git Deployments:** Pull code securely from private GitHub repositories using automatically generated SSH keys or Personal Access Tokens.
- **API Ready (Hybrid Mode):** Use the beautifully formatted interactive wizard, or pass arguments (with JSON output support) to control the CLI from a web UI like Laravel.
- **Elite UI/UX:** Features dynamic progress bars, animated spinners, and clear color-coded terminal output.

---

## 📦 Installation

Run the automated bootstrap script on a fresh Ubuntu server as the `root` user:

```bash
curl -s https://raw.githubusercontent.com/nioxon/provision/main/bootstrap.sh | sudo bash
```

*(The bootstrap script installs dependencies, clones the repository to `/opt/nioxplay-provision`, and links the executable to `/usr/local/bin/nioxplay`.)*

---

## 💻 Usage

The `nioxplay` CLI commands are divided into functional categories. 

### Server Provisioning

| Command | Description |
|---------|-------------|
| `nioxplay provision` | Runs the master sequence to provision the bare-metal server. Installs all packages, configures UFW/Fail2ban, sets up the `forge` user, and configures the static LAN interface. |

### Site Management

| Command | Description |
|---------|-------------|
| `nioxplay site:create` | Interactive wizard to create a new Nginx virtual host, allocate a database, generate SSL, and pull a GitHub repository. |
| `nioxplay site:bulk` | Bulk deploy multiple domains at once from a fixed repository. |
| `nioxplay site:list` | Displays a formatted ASCII table of all installed domains, IPs, and webroots. |
| `nioxplay site:update-all` | Scans all sites in `/home/forge`, performs a `git pull`, runs composer updates, and fixes ownership permissions. |

> **Note on Web Automation:** `site:create` supports inline arguments and a `json` format flag for seamless integration with web control panels.

### Security & Networking

| Command | Description |
|---------|-------------|
| `nioxplay captive:install` | Configures the server as a local gateway. Sets up multiple virtual IP aliases, DHCP/DNS, and network interception via iptables. |
| `nioxplay ssl:renew` | Checks for an active internet connection and safely renews Let's Encrypt certificates using the DNS challenge hook. |

### System Maintenance

| Command | Description |
|---------|-------------|
| `nioxplay self-update` | Pulls the latest CLI scripts directly from GitHub to upgrade your provisioning toolkit instantly. |

---

## ⚙️ Configuration (`config.env`)

You can place a `config.env` file in the root of the project (`/opt/nioxplay-provision/config.env`) to automate and bypass interactive prompts.

```env
# Network Setup
LAN_INTERFACE="eth0"
LAN_IP="10.10.10.2"
LAN_NET="192.168.1.0/24"

# Captive Portal Defaults
CAPTIVE_PAGE="/var/www/captive"
DEFAULT_WEBROOT="/home/forge"

# GitHub Integration (Optional)
GITHUB_PAT="ghp_YOUR_PERSONAL_ACCESS_TOKEN"
GITHUB_REPO_URL="git@github.com:nioxon/my-private-app.git"
```

*If `GITHUB_PAT` is provided, the `provision` command will automatically register the server's SSH key with your GitHub account.*

---

## 🏗️ Architecture

The application relies on a modular, easily extensible architecture:

```text
/opt/nioxplay-provision/
├── bin/
│   └── nioxplay.sh              # The main router & CLI executable
├── core/
│   ├── utils.sh                 # Global utilities (Spinners, Colors)
│   ├── provision.sh             # Master orchestrator for base setup
│   ├── site-*.sh                # Orchestrators for site commands
│   └── captive-install.sh       # Orchestrator for the captive portal
├── steps/
│   ├── base/                    # System dependencies (PHP, Nginx, MySQL)
│   ├── site/                    # Granular site actions (DB, Vhost, Git)
│   ├── network/                 # WAN/LAN interfaces and WiFi checks
│   └── captive/                 # iptables, dnsmasq, welcome page configs
├── config.env                   # Local configuration overrides
└── bootstrap.sh                 # Installer script
```

### Adding New Steps
To add a new software package (e.g., MeiliSearch), simply create `steps/base/08-meilisearch.sh`, utilize the `run_with_spinner` utility, and inject it into `core/provision.sh`.

---

## 🔒 SSL & Offline Certificates

Because this system is designed to run locally on a captive network, standard HTTP Let's Encrypt validation fails. 

When setting up a site, NioxPlay supports the **Let's Encrypt DNS-01 Challenge** via Cloudflare. This verifies your domain ownership publicly *without* exposing the server, delivering a perfect, warning-free HTTPS experience to offline users.

To use this, place your API token in `/root/.secrets/cloudflare.ini`:
```ini
dns_cloudflare_api_token = your_token_here
```

---

## 🛡️ Best Practices
- **Never commit `config.env` or `.secrets/` to version control.**
- The server provisions sites into `/home/forge/` and assigns ownership to the `forge` user to ensure secure application execution boundaries.

---
*Built with precision for Laravel and Enterprise offline deployments.*