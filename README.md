<p align="center">
  <img src="./media/logo.jpg" alt="Remnawave Installer" />
</p>

---

# Remnawave Installer

Installer for the **Remnawave** panel and VPN nodes — a ready-made solution for running your own VPN infrastructure. Everything is configured automatically: after installation the panel is working, the inbound is created, keys are generated, and the subscription is ready.

Supports **Remnawave 3.x** (latest) and **Remnawave 2.8.0** (legacy stable).

---

## Features

- **Panel + node** — on one server or on separate servers
- **Remnawave 3.x** — installed from official docker images (`backend:latest`); the installer checks and shows the current version from the official remnawave/panel repository
- **Remnawave 2.8.0** — legacy stable version, pinned images (`backend:2.8.0`, `node:2.8.0`, postgres 16, subscription-page 7.2.6)
- **Everything out of the box** — a working config is created automatically: keys are generated, your domain is substituted, nothing needs to be configured manually
- **Reality inbounds** — TCP, gRPC and XHTTP (VLESS + Reality), see `setup.sh` for multi-protocol nodes ([4] All three: 1+2+3)
- **nginx** — the only supported web server
- **Camouflage site** — the server masquerades as a regular website: your clients get VPN, strangers see a regular site
- **SSL certificates** — issued and renewed automatically
- **Panel protection** — access only via a secret address, without it the panel is invisible
- **Multilingual installer** — English, Russian, Chinese (Simplified)

---

## Requirements

- **OS:** Debian 11 / 12 / 13 or Ubuntu 22.04 / 24.04, fresh installation
- **Access:** root
- **Domains:** your own domain + subdomains (panel, subscription page, node/camouflage domain)

---

## Preparation

**⚡️ System update**

Before installing Remnawave, update the system:

```shell
apt update && apt full-upgrade -y
```

**✅ DNS check**

Make sure the DNS records already point to your VPS IP address before running the installer. This helps avoid errors when issuing SSL certificates and configuring the panel.

Check the records:

```shell
dig +short panel.your-domain.com
dig +short sub.your-domain.com
dig +short node.your-domain.com
```

All three commands must return the **IP address of your VPS**. If nothing is shown or a different address is returned, wait for DNS propagation and check again.

---

## Quick start

### Remnawave 3.x (latest)

```bash
bash <(curl -Ls https://raw.githubusercontent.com/properr/remnawave-installer/refs/heads/main/install_remnawave.sh)
```

### Remnawave 2.8.0 (legacy stable)

```bash
bash <(curl -Ls https://raw.githubusercontent.com/properr/remnawave-installer/refs/heads/main/2.8.0/install_remnawave.sh)
```

The script does everything itself: installs, configures, generates keys and shows the panel login and password.

<p align="center">
  <img src="./media/remnawave-installer.png" alt="Installer interface" />
</p>

---

## Installation modes

| Mode | When to use |
|------|-------------|
| **Panel + node on one server** | Compact installation, moderate traffic |
| **Panel only** | Control center without a VPN node |
| **Node only** | A separate VPN server connected to the panel by key |

---

## Node protocols (setup.sh)

For nodes with multiple protocols use `setup.sh` (from Rrezzak09VPN/remnanode-VLESS-Reality-Hysteria2, adapted):

```bash
bash <(curl -Ls https://raw.githubusercontent.com/properr/remnawave-installer/refs/heads/main/2.8.0/setup.sh)
```

Protocol selection at install time:

| Option | Protocol | Port |
|--------|----------|------|
| [1] | Hysteria2 (QUIC) | 443/udp |
| [2] | VLESS gRPC + Reality | 8443/tcp |
| [3] | VLESS XHTTP + Reality | 4443/tcp |
| [4] | **All three (1+2+3)** | — |

> [!NOTE]
> Recommended choice: **[4] All three**. Base VLESS TCP Reality (443/tcp) is always installed.

---

## DNS setup

**Single server (panel + node):**

| Type | Name | Value | Proxy |
|------|------|-------|-------|
| A | example.com | server IP | DNS only |
| CNAME | panel.example.com | example.com | DNS only |
| CNAME | sub.example.com | example.com | DNS only |
| CNAME | node.example.com | example.com | DNS only |

**Separate installation:** `node.example.com` → node server IP, everything else → panel IP.

---

## Update

The installer can update itself from this repository — menu item "Update".

---

## Repository structure

```
install_remnawave.sh      — main script, Remnawave 3.x (installation menu)
2.8.0/                    — Remnawave 2.8.0 installer (panel + node)
   ├── install_remnawave.sh  — 2.8.0 installer (menu: panel/node/reinstall)
   ├── setup.sh              — multi-protocol node setup ([4] All three)
   └── src/                  — modules (nginx/caddy/api/lang)
src/nginx/                — installation modules for nginx (3.x)
src/modules/              — panel, node and template management
src/api/                  — Remnawave panel API functions
src/lang/                 — language files (en, ru, zh-CN)
```

---

## Remnawave 2.8.0 notes

- Node key: `SECRET_KEY` = **public key of the panel** from `GET /api/keygen` → `.response.pubKey` (not the 3.x secret bundle)
- API tokens are required for `/api/*` (admin JWT is rejected with 403 in 2.8.0) — create one in Settings → API Tokens
- More details: [`2.8.0/README.md`](./2.8.0/README.md)

---

> [!CAUTION]
> The tool is intended for administering your own servers. Use at your own risk.

---

## ☁️ Support the project
