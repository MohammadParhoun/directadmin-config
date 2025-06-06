#!/bin/bash
# ======================================================================================================
# Script Name: directadmin-config.sh
# Description: A Bash script for initial configuration of DirectAdmin servers.
# Author: Mohammad Parhoun <mohammad.parhoun.7@gmail.com>
# Version: 1.0
#
# Copyright (c) 2025 Mohammad Parhoun. All Rights Reserved.
# This script is licensed under the MIT License.
#
# ======================================================================================================


GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
BRIGHT_WHITE="\e[1;37m"
RESET="\e[0m"

# ─── Root Check ─────────────────────────────────────
if [[ "$EUID" -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run as root.${RESET}" >&2
    exit 1
fi

# ─── Ask Server Type ───────────────────────────────
read -p "$(echo -e "${CYAN}Is it a [D]edicated or [V]irtual server? ${RESET}")" SERVER
SERVER=`echo $SERVER | tr '[:upper:]' '[:lower:]'`
if [[ "$SERVER" == "v" || "$SERVER" == "virtual" ]]; then
    da_port="1234"
elif [[ "$SERVER" == "d" || "$SERVER" == "dedicated" ]]; then
    da_port="4321"
else
    echo -e "${RED}invalid input${RESET}" >&2
    exit 1
fi

# ─── Ask if Hostname & NS Should Be Set ───────────
read -p "$(echo -e "${CYAN}Do you want to change Server's Hostname and NS fields in the Administrator Settings? [N]o or [Y]es? ${RESET}")" decision
decision=`echo $decision | tr '[:upper:]' '[:lower:]'`
    if [[ $decision == "y" || $decision == "yes" ]]; then
        read -p "$(echo -e "${CYAN}Enter the domain address e.g. google.com : ${RESET}")" domain
        if [[ -z "$domain" ]]; then
        echo -e "${RED}invalid input. Domain cannot be empty.${RESET}"
        exit 1
        fi
        domain=`echo $domain | tr '[:upper:]' '[:lower:]'`
        if $(echo $domain | grep -Eq "^.*\..*\..*"); then
            hostname="$domain"
        else
            hostname="server.$domain"
        fi
        da config-set servername $hostname && hostnamectl set-hostname $hostname && echo -e "${GREEN}✓ Server's Hostname changed to ${RESET}${BRIGHT_WHITE}$hostname${RESET}${GREEN} in the Administrator Settings and Linux.${RESET}" || echo -e "${RED}error while changing Server's Hostname ${RESET}"
        da config-set ns1 "ns1.$domain" && echo -e "${GREEN}✓ NS1 field changed to ${RESET}${BRIGHT_WHITE}ns1.$domain${RESET}${GREEN} in the Administrator Settings. This won't modify DNS zone file.${RESET}" || echo -e "${RED}error while changing ns1 field ${RESET}"
        da config-set ns2 "ns2.$domain" && echo -e "${GREEN}✓ NS2 field changed to ${RESET}${BRIGHT_WHITE}ns2.$domain${RESET}${GREEN} in the Administrator Settings. This won't modify DNS zone file.${RESET}" || echo -e "${RED}error while changing ns2 field ${RESET}"
        sed -i "s/ns1=.*$/ns1=ns1.$domain/" /usr/local/directadmin/data/users/admin/reseller.conf && sed -i "s/ns2=.*$/ns2=ns2.$domain/" /usr/local/directadmin/data/users/admin/reseller.conf && echo -e "${GREEN}✓ NS records updated in Name Servers section.${RESET}" || echo -e "${RED}failed to update Name Server section.${RESET}"
    elif [[ $decision == "n" || $decision == "no" ]]; then
        echo "skipped.."
    else
        echo -e "${RED}invalid input${RESET}" >&2
        exit 1
    fi
    

# ─── Install chrony if not installed ───────────────
if ! command -v chronyd &> /dev/null ; then
    if [[ -f /etc/redhat-release ]]; then
        echo "Installing chrony package..."
        dnf install -y chrony &> /dev/null && echo -e "${GREEN}✓ Chrony package installed successfully.${RESET}"
    elif [[ -f /etc/debian_version ]]; then
        echo "Installing chrony package..."
        apt install -y chrony &> /dev/null && echo -e "${GREEN}✓ Chrony package installed successfully.${RESET}"
    else
        echo -e "${RED}Not supported distro. Couldn't install chrony package.${RESET}" >&2
        exit 1
    fi
fi

# ─── Timezone and NTP Sync ─────────────────────────
timedatectl set-timezone Asia/Tehran && systemctl restart chronyd && echo -e "${GREEN}✓ Timezone set to Asia/Tehran and NTP synchronization restarted successfully.${RESET}" || echo -e "${RED}Failed to set timezone or restart NTP sync.${RESET}"

# ─── Roundcube DA Port Fix ─────────────────────────
sed -i "s/^\$config\['password_directadmin_port'\] = .*$/\$config\['password_directadmin_port'\] = $da_port;/" /var/www/html/roundcube/plugins/password/config.inc.php && echo -e "${GREEN}✓ DirectAdmin port updated in Roundcube config file to fix email password change issue.${RESET}" || echo -e "${RED}error while changing Roundcube config.${RESET}"

# ─── Set Encoding for Enhanced Skin ────────────────
sed -i "s/LANG_ENCODING=.*$/LANG_ENCODING=utf-8/" /usr/local/directadmin/data/skins/enhanced/lang/en/lf_standard.html && echo -e "${GREEN}✓ Updated language encoding to UTF-8 in DirectAdmin's Enhanced skin.${RESET}" || echo -e "${RED}Failed to update language encoding${RESET}"

# ─── Install NcFTP via DA script ───────────────────
if [[ ! -f /usr/bin/ncftp ]]; then
    echo "Installing NcFTP..."
    /usr/local/directadmin/scripts/ncftp.sh >/dev/null 2>&1 && echo -e "${GREEN}✓ NcFTP client is installed and ready to use for remote FTP backups.${RESET}" || echo -e "${RED}Failed to install or initialize ncftp.${RESET}"
else
    echo -e "${YELLOW}✓ NcFTP is already installed. No further action required.${RESET}"
fi



# ─── Enable HISTTIMEFORMAT in Bash ────────────────
HISTORY_LINE='export HISTTIMEFORMAT="%F %T "'
if [[ -f ~/.bashrc ]]; then
    if grep -q 'HISTTIMEFORMAT' ~/.bashrc; then
        echo "HISTTIMEFORMAT is already set in ~/.bashrc"
    else
        echo "$HISTORY_LINE" >> ~/.bashrc
        echo -e "${GREEN}✓ Enabled timestamp for Bash history in ~/.bashrc${RESET}"
    fi
    export HISTTIMEFORMAT="%F %T "
else
    echo -e "${RED}Couldn't find ~/.bashrc to enable timestamp for Bash history.${RESET}"
fi

# ─── DirectAdmin Configuration Function ────────────
da_function() {
    da config-set port $da_port && echo -e "${GREEN}✓ DirectAdmin port changed to ${RESET}${BRIGHT_WHITE}$da_port${RESET}" || echo -e "${RED}error while changing directadmin port${RESET}"
    da config-set timeout 300 && echo -e "${GREEN}✓ timeout changed to ${RESET}${BRIGHT_WHITE}300${RESET}" || echo -e "${RED}error while changing timeout${RESET}"
    da config-set session_minutes 300 && echo -e "${GREEN}✓ session_minutes changed to ${RESET}${BRIGHT_WHITE}300${RESET}" || echo -e "${RED}error while changing session_minutes${RESET}"
    da config-set maxfilesize 1073741824 && echo -e "${GREEN}✓ maxfilesize changed to ${RESET}${BRIGHT_WHITE}1GB${RESET}" || echo -e "${RED} error while changing maxfilesize${RESET}"
    da config-set max_username_length 16 && echo -e "${GREEN}✓ max_username_length changed to ${RESET}${BRIGHT_WHITE}16${RESET}" || echo -e "${RED} error while changing max_username_length${RESET}"
    da config-set awstats 1 && echo -e "${GREEN}✓ awstats has been enabled.${RESET}" || echo -e "${RED} error while enabling awstats${RESET}"
    echo -e "Restarting Directadmin..."
    systemctl restart directadmin || echo -e "${RED} error while restarting directadmin${RESET}"
    echo -e "Adding DA port to the CSF config file..."
    if [[ -e /etc/csf/csf.conf ]]; then
        cp /etc/csf/csf.conf /etc/csf/csf.conf.bak-$(date +%F-%T) 
        if ! `grep '^TCP_IN =' /etc/csf/csf.conf | grep -Eq "\b$da_port\b"`; then
            sed -i "/^TCP_IN =/ s/\"$/,$da_port\"/" /etc/csf/csf.conf && csf -r &> /dev/null && echo -e "${GREEN}✓ DirectAdmin port $da_port has been successfully opened in CSF firewall.${RESET}"
        else
            echo -e "${YELLOW}DirectAdmin port $da_port is already open in CSF firewall. No changes were made.${RESET}"
        fi
    else
        echo "Couldn't find CSF config file. Exiting.."
        exit 1
    fi
}

da_function

echo -e "---------------------------------------------------"
echo -e "${GREEN}Login Information:${RESET}"
echo -e "${GREEN}Login webpage:${RESET}${BRIGHT_WHITE} http://$(hostname -I | awk '{print $1}'):$da_port${RESET}"
echo -e "${GREEN}Username:${RESET}${BRIGHT_WHITE} admin${RESET}"
adminpassword=$(grep "adminpass" /usr/local/directadmin/conf/setup.txt | cut -d "=" -f 2) && echo -e "${GREEN}Admin Password: ${RESET}${BRIGHT_WHITE}$adminpassword${RESET}"

