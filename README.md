# directadmin-config.sh

A Bash script to automate the initial configuration of a DirectAdmin server, including setting hostname and nameservers, configuring DirectAdmin port, enabling system time sync, updating Roundcube and skin settings, creating packages and users, setting up backups, and more.

---

## 📦 Features

- Prompts for server type (Virtual/Dedicated) and sets DirectAdmin port automatically
- Optionally sets hostname and nameservers via DirectAdmin CLI
- Validates domain and email formats before applying changes
- Installs `chrony` and sets timezone to `Asia/Tehran` with NTP synchronization
- Fixes Roundcube password plugin to match DirectAdmin port
- Ensures UTF-8 encoding in DirectAdmin Enhanced skin
- Installs `ncftp` for remote FTP backup support and sets backup directories
- Enables timestamp in Bash history for all root commands
- Applies additional DirectAdmin settings (session timeout, max file size, AWStats, etc.)
- Opens DirectAdmin port and passive FTP ports in CSF firewall (if installed)
- Creates hosting package and DirectAdmin user automatically via API
- Configures backup crons for local and FTP backups

---

## 🚀 Usage

Run the script as root:

```bash
sudo bash directadmin-config.sh
```

⚠️ **The script must be run as root.**  
It checks for root privileges at the start and will exit if not run as root.

---

## 🧾 Requirements
- DirectAdmin installed and running
- CSF installed and configured (optional, for firewall setup)
- `da` command-line tool available
- Dependencies: `curl`, `base64`, `tr`, `jq` (the script will attempt to install missing packages automatically)

---

## 📄 License
This project is licensed under the MIT License – see the LICENSE file for details.

---

## ✍️ Author
**Mohammad Parhoun**  
📧 mohammad.parhoun.7@gmail.com

---

## 📝 Changelog

**v2.0 – 2025-10-18**  
- Added domain and email validation  
- Optional automatic hostname and nameserver setup  
- Automatic package creation and user account setup in DirectAdmin  
- Backup configuration with FTP support and cron creation  
- Auto-installation of `ncftp` and `jq` if missing  
- Improved DirectAdmin configuration settings (session, max file size, AWStats, etc.)  
- Firewall (CSF) integration for DA and passive FTP ports  
- Output formatting and color improvements for readability  
- Minor bug fixes and stability improvements  

**v1.0 – 2025-04-24** – Initial release

