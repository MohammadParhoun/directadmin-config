# da-config.sh

A Bash script to assist with initial configuration of a DirectAdmin server, including setting hostname and nameservers, configuring DirectAdmin port, enabling system time sync, updating Roundcube and skin settings, and more.

---

## 📦 Features

- Prompts for server type (Virtual/Dedicated) and adjusts DirectAdmin port accordingly
- Optionally sets hostname and nameservers via DirectAdmin CLI
- Installs `chrony` and sets timezone to `Asia/Tehran`
- Fixes Roundcube password plugin to match DA port
- Ensures UTF-8 encoding in DirectAdmin Enhanced skin
- Installs `ncftp` for remote FTP backup support
- Enables timestamp in Bash history
- Applies additional DA settings (e.g., session timeouts, file limits, AWStats)
- Opens DirectAdmin port in CSF firewall (if installed and configured)

---

## 🚀 Usage

```bash da-config.sh```

⚠️ Run the script as root. It checks for root privileges at the start and will exit if not run as root.

## 🧾 Requirements
A DirectAdmin server 

CSF installed 
da command-line tool available (DirectAdmin must be installed)

## 📄 License
This project is licensed under the MIT License – see the LICENSE file for details.

## ✍️ Author
Mohammad Parhoun
📧 mohammad.parhoun.7@gmail.com

## 📝 Changelog
v1.0 – 2025-04-24 - Initial release
