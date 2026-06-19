# 📡 SMS Gateway — Setup Guide

Flask web interface to send and receive SMS via a **4G/5G router** (Huawei, Netgear, GL.iNet, TP-Link, ZTE). Rate limiting, secure logging (password masked), French phone number validation.

## 🖼️ Overview

| Simple | Expert | Bulk file |
|--------|--------|-----------|
| ![Simple mode](docs/simple.png) | ![Expert mode](docs/expert.png) | ![File send](docs/file.png) |

| Inbox | Outbox |
|-------|--------|
| ![Inbox](docs/inbox.png) | ![Outbox](docs/outbox.png) |

| Multi-router configuration |
|---------------------------|
| ![Config](docs/config.png) |

---

## 🔌 Multi-router configuration

The **⚙️ Config** tab lets you connect any supported 4G/5G router directly from the web interface — no config files to edit.

| Brand | Tested / compatible models | Library | Inbox | Outbox |
|-------|---------------------------|---------|-------|--------|
| **Huawei** | B525s, B535, B818, B628, B715, E5186… | `huawei-lte-api` | ✅ | ✅ |
| **Netgear** | LB1120, LB2120, LB1111, MR1100, MR2100… | `eternalegypt` | ✅ | ❌ |
| **GL.iNet** | X3000, XE3000, X750 (Spitz), E750 (Mudi), MiFi, AP1300LTE… | `python-glinet` | ✅ | ❌ |
| **TP-Link** | MR6400, MR600, MR500, MR200, Archer MR550, MR400, MR450… | `tplinkrouterc6u` | ✅ | ❌ |
| **ZTE** | MC801a, MC889, MF286, MF286D, MF289, MF28D, MF90… | `python-zte-mc801a` | ✅ | ❌ |

**Connection fields:**
- **IP address** of the router on the local network
- **Username** (not required for Netgear, TP-Link and ZTE — fixed username on firmware side)
- **Password**

The **Test** button checks connectivity without saving. The **Save** button applies the configuration immediately, no service restart needed.

> The configuration is stored in `router_config.json` (not versioned). The password never appears in logs.

---

## ✅ Prerequisites

| Component | Detail |
|-----------|--------|
| OS | Debian 11+, Raspbian (aarch64) |
| Python | 3.9+ |
| Router | Huawei, Netgear, GL.iNet, TP-Link or ZTE LTE/5G on the local network |
| Internet | For apt + pip (install only) |

---

## 🚀 Quick install

```bash
git clone https://github.com/Wr1ghtShade/sms-gateway.git
cd sms-gateway
chmod +x install.sh
sudo ./install.sh
```

Then start the service:

```bash
sudo systemctl start gateway-sms
```

Open the interface in your browser: **`http://<server-ip>:5000`**

Go to the **⚙️ Config** tab, enter the router brand, IP and credentials, then click **Test** and **Save**.

> **Alternative**: manually create `/var/www/sms-gateway/router_config.json` before first start:
> ```json
> {
>   "brand": "huawei",
>   "ip": "192.168.16.1",
>   "user": "admin",
>   "pass": "your_password"
> }
> ```
> Valid values for `brand`: `huawei`, `netgear`, `glinet`, `tplink`, `zte`.

---

## 📁 Deployed structure

```
/var/www/sms-gateway/
├── gateway-sms-webui.py   # Flask backend (port 5000)
├── adapters/              # Multi-router adapters
│   ├── __init__.py        # Factory get_adapter()
│   ├── base.py            # Abstract class RouterAdapter
│   ├── huawei.py          # Huawei LTE (huawei-lte-api)
│   ├── netgear.py         # Netgear LTE (eternalegypt)
│   ├── glinet.py          # GL.iNet LTE/5G (python-glinet)
│   ├── tplink.py          # TP-Link MR LTE (tplinkrouterc6u)
│   └── zte.py             # ZTE MC/MF LTE (goform HTTP API)
├── templates/index.html   # Frontend HTML/CSS/JS
├── static/favicon.svg
├── requirements.txt
├── router_config.json     # Active config (not versioned, written by UI or manually)
├── fix-perms.sh           # Restore permissions after root edits
├── gateway-sms.service    # systemd unit file
└── venv/                  # Python virtual environment
```

---

## 🛠️ Daily commands

```bash
# Status
systemctl is-active gateway-sms
journalctl -u gateway-sms -n 30 --no-pager

# Restart
sudo systemctl restart gateway-sms

# Restore permissions after editing as root
sudo bash /var/www/sms-gateway/fix-perms.sh

# Quick health check
curl -s http://127.0.0.1:5000/health
curl -s http://127.0.0.1:5000/router/status
```

---

## 🔌 API routes

| Method | Route | Description |
|--------|-------|-------------|
| GET / POST | `/send` | Send an SMS |
| POST | `/send_bulk` | Background bulk send |
| GET | `/send_bulk/status` | Bulk send status |
| POST | `/send_bulk/stop` | Cancel bulk send |
| GET | `/inbox` | Received messages |
| GET | `/outbox` | Sent messages (if supported by router) |
| POST | `/delete` | Delete a single SMS |
| POST | `/delete_all_sent` | Delete entire outbox |
| GET | `/health` | Service and router health |
| GET | `/router/status` | Signal, operator, network type |
| GET | `/capabilities` | Active router capabilities (inbox/outbox) |
| GET | `/config` | Current config (password masked) |
| POST | `/config` | Save new config |
| POST | `/config/test` | Test a config without saving |

---

## 💬 Send a test SMS

```bash
curl -s -X POST http://127.0.0.1:5000/send \
  -H "Content-Type: application/json" \
  -d '{"number": "0600000000", "message": "Test 🎉"}'
```

> No CSRF token required on `/send` — external integrations (Home Assistant, NUT, scripts) don't have access to the HTML page to retrieve a token. CSRF protection is intentionally disabled on this endpoint for LAN-only deployments. All other sensitive routes (`/config`, `/delete`, etc.) remain CSRF-protected.

**Accepted number formats** — spaces, dashes and dots are automatically stripped before validation and sending:

| Format | Example |
|--------|---------|
| `06XXXXXXXX` | `0612345678` |
| `07XXXXXXXX` | `0712345678` |
| `06 XX XX XX XX` | `06 12 34 56 78` |
| `06-XX-XX-XX-XX` | `06-12-34-56-78` |
| `06.XX.XX.XX.XX` | `06.12.34.56.78` |
| `+336XXXXXXXX` | `+33612345678` |
| `+336 XX XX XX XX` | `+336 12 34 56 78` |
| `+337XXXXXXXX` | `+33712345678` |

---

## 🔗 External integration (scripts, cron, monitoring)

The `/send` endpoint accepts both GET and POST requests, making it easy to call from any shell script, cron job, Home Assistant automation or monitoring tool:

```bash
# Simple GET call (Home Assistant, NUT, shell scripts)
curl -s "http://127.0.0.1:5000/send?number=06XXXXXXXX&message=Alert:+event+detected"

# POST with form data
curl -s -X POST http://127.0.0.1:5000/send \
  --data-urlencode "number=06XXXXXXXX" \
  --data-urlencode "message=Alert: event detected"
```

**Home Assistant example** (`configuration.yaml`):
```yaml
rest_command:
  send_sms:
    url: "http://<pi-ip>:5000/send"
    method: POST
    content_type: "application/json"
    payload: '{"number": "{{ number }}", "message": "{{ message }}"}'
```

> **Note:** GET requests expose the phone number and message in plain text in server access logs and browser history. POST JSON is recommended — the payload stays out of logs and URLs.

Use cases: UPS alerts (NUT), Home Assistant automations, system monitoring, cron notifications, watchdog scripts.

---

## 🗑️ Uninstall

```bash
sudo systemctl stop gateway-sms
sudo systemctl disable gateway-sms
sudo rm /etc/systemd/system/gateway-sms.service
sudo systemctl daemon-reload
sudo rm -rf /var/www/sms-gateway
```

---

## 📄 License

MIT © 2026 [Wr1ghtShade](https://github.com/Wr1ghtShade)
