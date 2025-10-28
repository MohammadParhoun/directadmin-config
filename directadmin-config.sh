#!/bin/bash
# ======================================================================================================
# Script Name: directadmin-config.sh
# Description: A Bash script for initial configuration of DirectAdmin servers.
# Author: Mohammad Parhoun <mohammad.parhoun.7@gmail.com>
# Version: 2.0
#
# Copyright (c) 2025 Mohammad Parhoun. All Rights Reserved.
# This script is licensed under the MIT License.
#
# ======================================================================================================


GREEN="\e[32m"
BRIGHT_GREEN="\e[1;32m"
RED="\e[31m"
BRIGHT_RED="\e[1;31m"
YELLOW="\e[33m"
CYAN="\e[36m"
BRIGHT_CYAN="\e[1;36m"
BRIGHT_WHITE="\e[1;37m"
RESET="\e[0m"
server_ip=$(hostname -I | awk '{ print $1}')
adminpassword=$(grep "adminpass" /usr/local/directadmin/conf/setup.txt | cut -d "=" -f 2)
user_password=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c16; echo)

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
        domain=`echo $domain | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]'`
        
        if [[ ! "$domain" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.[A-Za-z]{2,63}$ ]]; then
            echo -e "${RED}Error: Invalid domain format. Please enter only a main domain like ${RESET}${BRIGHT_RED}'google.com'${RESET}${RED} (no subdomain allowed).${RESET}"
            exit 1
        else
            hostname="server.$domain"
        fi

        read -p "$(echo -e "${CYAN}Enter user's email address: ${RESET}")" email
        if [[ -z "$email" ]]; then
        echo -e "${RED}invalid input. Email cannot be empty.${RESET}"
        exit 1
        fi
        if ! [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
            echo -e "${RED}Invalid email format. Please enter a valid email.${RESET}"
            exit 1
        fi



#backup1
    read -p "$(echo -e "${CYAN}Do you want to set Backup Settings? [N]o or [Y]es? ${RESET}")" decision2
    decision2=`echo $decision2 | tr '[:upper:]' '[:lower:]'`
    if [[ $decision2 == "y" || $decision2 == "yes" ]]; then
        BACKUP_CONF="/usr/local/directadmin/data/admin/backup.conf"
        read -p "$(echo -e "${CYAN}Enter FTP server IP [default: ${RESET}${BRIGHT_CYAN}noc.netmihan.com${RESET}${CYAN}]: ${RESET}")" backup_ip
        backup_ip="${backup_ip:-noc.netmihan.com}"
        read -p "$(echo -e "${CYAN}Enter FTP backup username: ${RESET}")" backup_username
        if [[ -z "$backup_username" ]]; then
        echo -e "${RED}invalid input. Username cannot be empty.${RESET}"
        exit 1
        fi
        read -p "$(echo -e "${CYAN}Enter FTP backup password: ${RESET}")" backup_password
        if [[ -z "$backup_password" ]]; then
        echo -e "${RED}invalid input. Password cannot be empty.${RESET}"
        exit 1
        else
        encoded_password=$(echo -n "$backup_password" | base64)
        backup_state="enabled"
        fi
    elif  [[ $decision2 == "n" || $decision2 == "no" ]]; then
        echo "backup skipped.."
    else
        echo -e "${RED}invalid input${RESET}" >&2
        exit 1
    fi

        echo
        echo
        echo -e "${GREEN}##########################################################${RESET}"
        echo -e "${GREEN}##                                                      ##${RESET}"
        echo -e "${GREEN}##          ${RESET}${BRIGHT_GREEN}DirectAdmin Automated Setup Report${RESET}${GREEN}          ##${RESET}"
        echo -e "${GREEN}##                                                      ##${RESET}"
        echo -e "${GREEN}#####################################################ُ#####${RESET}"
        echo -e ""
        echo -e ""
        echo -e "${BRIGHT_GREEN}Starting DirectAdmin Automation Script...${RESET}"
        echo -e ""
        echo -e ""

        echo -e "${BRIGHT_GREEN}1) Server Identity & DNS Setup${RESET}"

        da config-set servername $hostname && hostnamectl set-hostname $hostname && echo -e "${GREEN}✓ Server's Hostname changed to ${RESET}${BRIGHT_WHITE}$hostname${RESET}${GREEN} in the Administrator Settings and Linux.${RESET}" || echo -e "${RED}error while changing Server's Hostname ${RESET}"
        da config-set ns1 "ns1.$domain" && echo -e "${GREEN}✓ NS1 field changed to ${RESET}${BRIGHT_WHITE}ns1.$domain${RESET}${GREEN} in the Administrator Settings. This won't modify DNS zone file.${RESET}" || echo -e "${RED}error while changing ns1 field ${RESET}"
        da config-set ns2 "ns2.$domain" && echo -e "${GREEN}✓ NS2 field changed to ${RESET}${BRIGHT_WHITE}ns2.$domain${RESET}${GREEN} in the Administrator Settings. This won't modify DNS zone file.${RESET}" || echo -e "${RED}error while changing ns2 field ${RESET}"
        sed -i "s/ns1=.*$/ns1=ns1.$domain/" /usr/local/directadmin/data/users/admin/reseller.conf && sed -i "s/ns2=.*$/ns2=ns2.$domain/" /usr/local/directadmin/data/users/admin/reseller.conf && echo -e "${GREEN}✓ NS records updated in Name Servers section.${RESET}" || echo -e "${RED} Failed to update Name Server section.${RESET}"
        sed -i "s/email=.*$/email=$email/" /usr/local/directadmin/data/users/admin/ticket.conf && sed -i "s/email=.*$/email=$email/" /usr/local/directadmin/data/users/admin/user.conf && echo -e "${GREEN}✓ Email address updated successfully in DirectAdmin configuration.${RESET}" || echo -e "${RED} Failed to update email address in DirectAdmin configuration.${RESET}"
        if [[ $backup_state == "enabled" ]]; then
            if [[ -f $BACKUP_CONF ]]; then
            cp $BACKUP_CONF $BACKUP_CONF.bak-$(date +%F-%T)
            fi
cat > "$BACKUP_CONF" <<EOF
append_to_path=nothing
ftp_ip=$backup_ip
ftp_password=$encoded_password
ftp_path=/weekly
ftp_port=21
ftp_secure=no
ftp_username=$backup_username
local_path=/home/admin/admin_backups
message=yes
EOF

        fi

    elif [[ $decision == "n" || $decision == "no" ]]; then
        echo "skipped.."
    else
        echo -e "${RED}invalid input${RESET}" >&2
        exit 1
    fi
    
echo
echo -e "${BRIGHT_GREEN}2) System Environment & Utility Configuration${RESET}"


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
    /usr/local/directadmin/scripts/ncftp.sh >/dev/null 2>&1 && echo -e "${GREEN}✓ NcFTP client is installed and ready to use for remote FTP backups.${RESET}"; ncftp_state="enabled" || echo -e "${RED}Failed to install or initialize ncftp.${RESET}"
else
    echo -e "${YELLOW}✓ NcFTP is already installed. No further action required.${RESET}"
    ncftp_state="enabled"
fi


# ─── Enable HISTTIMEFORMAT in Bash ────────────────
HISTORY_LINE='export HISTTIMEFORMAT="%F %T "'
if [[ -f ~/.bashrc ]]; then
    if grep -q 'HISTTIMEFORMAT' ~/.bashrc; then
        echo -e "${YELLOW}✓ HISTTIMEFORMAT is already set in ~/.bashrc${RESET}"
    else
        echo "$HISTORY_LINE" >> ~/.bashrc
        echo -e "${GREEN}✓ Enabled timestamp for Bash history in ~/.bashrc${RESET}"
    fi
    export HISTTIMEFORMAT="%F %T "
else
    echo -e "${RED}Couldn't find ~/.bashrc to enable timestamp for Bash history.${RESET}"
fi

echo
echo -e "${BRIGHT_GREEN}3) DirectAdmin Security & Performance Tuning${RESET}"

# ─── DirectAdmin Configuration Function ────────────
da_function() {
    da config-set port $da_port && echo -e "${GREEN}✓ DirectAdmin port changed to ${RESET}${BRIGHT_WHITE}$da_port${RESET}" || echo -e "${RED}error while changing directadmin port${RESET}"
    da config-set timeout 300 && echo -e "${GREEN}✓ timeout changed to ${RESET}${BRIGHT_WHITE}300${RESET}" || echo -e "${RED}error while changing timeout${RESET}"
    da config-set session_minutes 300 && echo -e "${GREEN}✓ session_minutes changed to ${RESET}${BRIGHT_WHITE}300${RESET}" || echo -e "${RED}error while changing session_minutes${RESET}"
    da config-set maxfilesize 1073741824 && echo -e "${GREEN}✓ maxfilesize changed to ${RESET}${BRIGHT_WHITE}1GB${RESET}" || echo -e "${RED} error while changing maxfilesize${RESET}"
    da config-set max_username_length 14 && echo -e "${GREEN}✓ max_username_length changed to ${RESET}${BRIGHT_WHITE}14${RESET}" || echo -e "${RED} error while changing max_username_length${RESET}"
    da config-set awstats 1 && echo -e "${GREEN}✓ awstats has been enabled.${RESET}" || echo -e "${RED} error while enabling awstats${RESET}"
    #echo -e "  Restarting Directadmin..."
    systemctl restart directadmin || echo -e "${RED} Error while restarting directadmin${RESET}"
    #echo -e "  Adding DA port to the CSF config file..."
    if [[ -e /etc/csf/csf.conf ]]; then
        cp /etc/csf/csf.conf /etc/csf/csf.conf.bak-$(date +%F-%T) 
        if ! `grep '^TCP_IN =' /etc/csf/csf.conf | grep -Eq "\b$da_port\b"`; then
            sed -i "/^TCP_IN =/ s/\"$/,$da_port\"/" /etc/csf/csf.conf && csf -r &> /dev/null && echo -e "${GREEN}✓ DirectAdmin port $da_port has been successfully opened in CSF firewall.${RESET}"
        else
            echo -e "${YELLOW}✓ DirectAdmin port $da_port is already open in CSF firewall. No changes were made.${RESET}"
        fi
        if ! `grep '^TCP_OUT =' /etc/csf/csf.conf | grep -Eq "\b10000:65535\b"`; then
            sed -i "/^TCP_OUT =/ s/\"$/,10000:65535\"/" /etc/csf/csf.conf && csf -r &> /dev/null && echo -e "${GREEN}✓ Passive FTP ports have been successfully added to CSF and firewall reloaded.${RESET}"
        else
            echo -e "${YELLOW}✓ Passive FTP ports are already allowed in CSF firewall. No changes were made.${RESET}"
        fi
    else
        echo "Couldn't find CSF config file. Exiting.."
        exit 1
    fi
}

da_function

echo
echo -e "${BRIGHT_GREEN}4) Hosting Package & User Account Creation${RESET}"

# ─── DirectAdmin Package Creation ────────────────────────────────
API_TIMEOUT=45

PACKAGE_NAME="newpackage" 

if grep -qi "ubuntu" /etc/os-release; then
    PROTOCOL="https"
else
    PROTOCOL="http"
fi

response=$(curl -Lk -s -m $API_TIMEOUT -u "admin:$adminpassword" \
-d "add=Save" \
-d "packagename=$PACKAGE_NAME" \
-d "aftp=OFF" \
-d "auto_security_txt=OFF" \
-d "bandwidth=unlimited" \
-d "catchall=OFF" \
-d "cgi=OFF" \
-d "cron=ON" \
-d "dnscontrol=ON" \
-d "domainptr=unlimited" \
-d "email_daily_limit=unlimited" \
-d "ftp=unlimited" \
-d "inode=unlimited" \
-d "jail=ON" \
-d "language=en" \
-d "login_keys=ON" \
-d "mysql=unlimited" \
-d "nemailf=unlimited" \
-d "nemailml=unlimited" \
-d "nemailr=unlimited" \
-d "nemails=unlimited" \
-d "nsubdomains=unlimited" \
-d "php=ON" \
-d "quota=unlimited" \
-d "skin=evolution" \
-d "spam=ON" \
-d "ssh=OFF" \
-d "ssl=ON" \
-d "suspend_at_limit=ON" \
-d "sysinfo=ON" \
-d "vdomains=unlimited" \
"$PROTOCOL://127.0.0.1:$da_port/CMD_API_MANAGE_USER_PACKAGES")

if echo "$response" | grep -q "error=0"; then
    if echo "$response" | grep -q "text=Saved"; then
        echo -e "${GREEN}✓ DirectAdmin package '$PACKAGE_NAME' created successfully.${RESET}"
    else
        echo -e "${YELLOW}Warning: DirectAdmin package '$PACKAGE_NAME' operation finished with 'error=0', but 'Saved' message is missing.${RESET}"
        decoded_response=$(printf '%b' "${response//%/\\x}")
        echo -e "${YELLOW}API Response:${RESET} $decoded_response"
    fi
else
    echo -e "${RED}Failed to create DirectAdmin package '$PACKAGE_NAME'.${RESET}"
    decoded_response=$(printf '%b' "${response//%/\\x}")
    echo -e "${YELLOW}API Response:${RESET} $decoded_response"
    exit 1 
fi



# ─── Creating DirectAdmin User ────────────────────────────────
user_name=$(echo $domain | tr '[:upper:]' '[:lower:]' | awk -F '.' '{ print $1 }' | tr -d '-' | cut -c 1-10)

response=$(curl -Lk -s -m $API_TIMEOUT -u "admin:$adminpassword" "$PROTOCOL://127.0.0.1:$da_port/CMD_API_ACCOUNT_USER" \
-d "action=create" \
-d "add=Submit" \
-d "username=$user_name" \
-d "email=$email" \
-d "passwd=$user_password" \
-d "passwd2=$user_password" \
-d "domain=$domain" \
-d "ip=$server_ip" \
-d "package=$PACKAGE_NAME" \
-d "notify=yes")


if echo "$response" | grep -q "error=0"; then
    echo -e "${GREEN}✓ DirectAdmin user '$user_name' created successfully for domain '$domain'.${RESET}"
else
    echo -e "${RED}Failed to create DirectAdmin user '$user_name'.${RESET}"
    decoded_response=$(printf '%b' "${response//%/\\x}")
    echo -e "${YELLOW}API Response:${RESET} $decoded_response"
    exit 1
fi

echo
echo -e "${BRIGHT_GREEN}5) Backup Configuration & Validation${RESET}"

#backup2
echo -e "${GREEN}✓ Backup settings saved to $BACKUP_CONF${RESET}"    #set in backup1

if [[ $backup_state == "enabled" && $ncftp_state == "enabled" ]]; then
        ncftp -u $backup_username -p $backup_password $backup_ip >/dev/null 2>&1 <<EOF
mkdir daily
mkdir weekly
quit
EOF
  if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ Successfully connected to FTP server and ensured 'daily' and 'weekly' directories exist.${RESET}"


#jq package installation
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW} jq package not found. Installing...${RESET}"
        if command -v apt &> /dev/null; then
            if ! sudo apt update -qq >/dev/null 2>&1 || ! sudo apt install -y jq >/dev/null 2>&1; then
                echo -e "${RED}Failed to install jq via apt.${RESET}" >&2
                exit 1
            fi
        elif command -v dnf &> /dev/null; then
            if ! sudo dnf install -y jq >/dev/null 2>&1; then
                echo -e "${RED}Failed to install jq via dnf.${RESET}" >&2
                exit 1
            fi
        elif command -v yum &> /dev/null; then
            if ! sudo yum install -y jq >/dev/null 2>&1; then
                echo -e "${RED}Failed to install jq via yum.${RESET}" >&2
                exit 1
            fi
        else
            echo -e "${RED}No supported package manager found. Install jq package manually.${RESET}" >&2
            exit 1
        fi

        echo -e "${GREEN}✓ jq package installed successfully.${RESET}"
    fi



        BACKUP_CRON_FILE="/usr/local/directadmin/data/admin/backup_crons.list"

cat > "$BACKUP_CRON_FILE" <<EOF
1=action=backup&append%5Fto%5Fpath=dayofweek&database%5Fdata%5Faware=yes&dayofmonth=%2A&dayofweek=%2A&email%5Fdata%5Faware=yes&hour=%35&local%5Fpath=%2Fhome%2Fadmin%2Fadmin%5Fbackups&minute=%33%30&month=%2A&owner=admin&trash%5Faware=yes&type=admin&value=multiple&when=now&where=local&who=all
2=action=backup&append%5Fto%5Fpath=dayofweek&database%5Fdata%5Faware=yes&dayofmonth=%2A&dayofweek=%2A&email%5Fdata%5Faware=yes&ftp%5Fip=$(echo -n "$backup_ip" | jq -sRr @uri)&ftp%5Fpassword=$(echo -n "$encoded_password" | jq -sRr @uri)&ftp%5Fpath=%2Fdaily&ftp%5Fport=%32%31&ftp%5Fsecure=no&ftp%5Fusername=$(echo -n "$backup_username" | jq -sRr @uri)&hour=%33&minute=%30&month=%2A&owner=admin&trash%5Faware=yes&type=admin&value=multiple&when=now&where=ftp&who=all
3=action=backup&append%5Fto%5Fpath=dayofweek&database%5Fdata%5Faware=yes&dayofmonth=%2A&dayofweek=%35&email%5Fdata%5Faware=yes&ftp%5Fip=$(echo -n "$backup_ip" | jq -sRr @uri)&ftp%5Fpassword=$(echo -n "$encoded_password" | jq -sRr @uri)&ftp%5Fpath=%2Fweekly&ftp%5Fport=%32%31&ftp%5Fsecure=no&ftp%5Fusername=$(echo -n "$backup_username" | jq -sRr @uri)&hour=%31&minute=%30&month=%2A&owner=admin&trash%5Faware=yes&type=admin&value=multiple&when=now&where=ftp&who=all
EOF
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓ Backup crons have been successfully created in DirectAdmin.${RESET}"
else
    echo -e "${RED}Failed to create backup crons in DirectAdmin!${RESET}"
    exit 1
fi

# Reload DirectAdmin task queue to apply new backup schedules
if /usr/local/directadmin/dataskq d400 >/dev/null 2>&1; then
    echo -e "${GREEN}✓ DirectAdmin task queue reloaded successfully for backup schedule.${RESET}"
else
    echo -e "${RED}Failed to reload DirectAdmin task queue.${RESET}"
fi

    else
        echo -e "${RED}✗ Failed to connect to FTP server or create directories.${RESET}"
        echo -e "${YELLOW}Please check FTP credentials, connection, or directory permissions.${RESET}"
    fi
fi

echo
#echo -e "------------------------------------------------------------------------------------------------------"
echo  -e "${BRIGHT_GREEN}----------------- Final Credentials -----------------${RESET}"
echo
echo -e "${GREEN}* Admin Login Information:${RESET}"
echo -e "${GREEN}* Web Panel URL:   ${RESET}${BRIGHT_WHITE} http://$(hostname -I | awk '{print $1}'):$da_port${RESET}"
echo -e "${GREEN}* Username:        ${RESET}${BRIGHT_WHITE} admin${RESET}"
echo -e "${GREEN}* Admin Password:  ${RESET}${BRIGHT_WHITE} $adminpassword${RESET}"
echo
echo
echo -e "${GREEN}* User account information:${RESET}"
echo -e "${GREEN}* Web Panel URL:   ${RESET}${BRIGHT_WHITE} http://$(hostname -I | awk '{print $1}'):$da_port${RESET}"
echo -e "${GREEN}* Username:        ${RESET}${BRIGHT_WHITE} $user_name${RESET}"
echo -e "${GREEN}* Password:        ${RESET}${BRIGHT_WHITE} $user_password${RESET}"
echo
echo -e "${BRIGHT_GREEN}----------------------------------------------------${RESET}"
echo
echo
