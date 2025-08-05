#!/bin/bash
# Author: Mihir Savla
# Script for VPS/DEDI detailed disk usage analysis

# Color Setup
red=$(tput setaf 1)
gre=$(tput setaf 2)
yel=$(tput setaf 3)
vio=$(tput setaf 5)
cya=$(tput setaf 6)
res=$(tput sgr0)
bold=$(tput bold)

disk() {
    clear

    # Get disk usage of root partition
    tot=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    echo -e "\n${bold}${cya}Disk Usage Report:${res}"
    echo -e "----------------------------"
    echo -e "Disk usage of the server is at: ${red}${tot}%${res}\n"

    # Clear some system logs (truncate only)
    : > /var/log/btmp
    : > /var/log/secure

    echo -e "${bold}${cya}Top Disk-Consuming Directories under /:${res}"
    echo "----------------------------------------"
    find / -maxdepth 1 -mindepth 1 -type d -exec du -sh {} \; 2>/dev/null \
        | egrep -v 'virtfs|usr|lib|proc|swap|boot|sql' \
        | sort -rh | head -3

    echo -e "\n${bold}${gre}Top Large Files:${res}"
    echo "----------------------------------------"
    find / -type f -exec du -Sh {} + 2>/dev/null \
        | egrep -v 'virtfs|usr|lib|swap|boot|sql' \
        | sort -rh | head -n 5 | tee /root/diskusagedata.txt

    echo -e "\n${bold}${vio}Top Large Directories:${res}"
    echo "---------------------------------------------"
    find / -mindepth 2 -type d -exec du -Sh {} + 2>/dev/null \
        | egrep -v 'virtfs|usr|lib|swap|boot|sql' \
        | sort -rh | uniq | head -n 5 | tee /root/diskusage.txt

    echo -e "\n${bold}${yel}Suggestions for Possible Cleanup:${res}"
    echo "------------------------------------------"

    # Backup/Archive files suggestion
    if grep -Ei 'backup|\.tar|\.zip|\.gz|\.sql' /root/diskusagedata.txt > /dev/null; then
        echo -e "${bold}${gre}🧳 Archive/Backup Files (Consider Deleting):${res}"
        grep -Ei 'backup|\.tar|\.zip|\.gz|\.sql' /root/diskusagedata.txt | head -5
        echo
    fi

    # Log files suggestion
    if grep -i 'log' /root/diskusagedata.txt > /dev/null; then
        echo -e "${bold}${cya}📜 Log Files (Consider Truncating):${res}"
        grep -i 'log' /root/diskusagedata.txt | head -3
        echo
    fi

    # Mail directories
    if grep -i 'mail' /root/diskusage.txt | grep -v 'cpanel' > /dev/null; then
        echo -e "${bold}${vio}📬 Mail Folders (Suggest to Archive/Delete):${res}"
        grep -i 'mail' /root/diskusage.txt | grep -v 'cpanel' | head -3
        echo
    fi

    echo -e "${red}${bold}Important Note:${res}"
    echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    echo -e "Please avoid direct deletion of any files without confirmation."
    echo -e "Logs should be truncated safely, not removed."
    echo -e "Use the following references:"
    echo "- https://computingforgeeks.com/how-to-empty-truncate-log-files-in-linux/"
    echo "- https://www.cyberciti.biz/faq/remove-log-files-in-linux-unix-bsd/"
    echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
}

# Root user check
if [[ $(id -u) -eq 0 ]]; then
    disk
else
    echo -e "${red}Please run the script as root user.${res}"
    exit 1
fi
#!/bin/bash
# Author: Mihir Savla
# Script for VPS/DEDI detailed disk usage analysis

# Color Setup
red=$(tput setaf 1)
gre=$(tput setaf 2)
yel=$(tput setaf 3)
vio=$(tput setaf 5)
cya=$(tput setaf 6)
res=$(tput sgr0)
bold=$(tput bold)

disk() {
    clear

    # Get disk usage of root partition
    tot=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    echo -e "\n${bold}${cya}Disk Usage Report:${res}"
    echo -e "----------------------------"
    echo -e "Disk usage of the server is at: ${red}${tot}%${res}\n"

    # Clear some system logs (truncate only)
    : > /var/log/btmp
    : > /var/log/secure

    echo -e "${bold}${cya}Top Disk-Consuming Directories under /:${res}"
    echo "----------------------------------------"
    find / -maxdepth 1 -mindepth 1 -type d -exec du -sh {} \; 2>/dev/null \
        | egrep -v 'virtfs|usr|lib|proc|swap|boot|sql' \
        | sort -rh | head -3

    echo -e "\n${bold}${gre}Top Large Files:${res}"
    echo "----------------------------------------"
    find / -type f -exec du -Sh {} + 2>/dev/null \
        | egrep -v 'virtfs|usr|lib|swap|boot|sql' \
        | sort -rh | head -n 5 | tee /root/diskusagedata.txt

    echo -e "\n${bold}${vio}Top Large Directories:${res}"
    echo "---------------------------------------------"
    find / -mindepth 2 -type d -exec du -Sh {} + 2>/dev/null \
        | egrep -v 'virtfs|usr|lib|swap|boot|sql' \
        | sort -rh | uniq | head -n 5 | tee /root/diskusage.txt

    echo -e "\n${bold}${yel}Suggestions for Possible Cleanup:${res}"
    echo "------------------------------------------"

    # Backup/Archive files suggestion
    if grep -Ei 'backup|\.tar|\.zip|\.gz|\.sql' /root/diskusagedata.txt > /dev/null; then
        echo -e "${bold}${gre}🧳 Archive/Backup Files (Consider Deleting):${res}"
        grep -Ei 'backup|\.tar|\.zip|\.gz|\.sql' /root/diskusagedata.txt | head -5
        echo
    fi

    # Log files suggestion
    if grep -i 'log' /root/diskusagedata.txt > /dev/null; then
        echo -e "${bold}${cya}📜 Log Files (Consider Truncating):${res}"
        grep -i 'log' /root/diskusagedata.txt | head -3
        echo
    fi

    # Mail directories
    if grep -i 'mail' /root/diskusage.txt | grep -v 'cpanel' > /dev/null; then
        echo -e "${bold}${vio}📬 Mail Folders (Suggest to Archive/Delete):${res}"
        grep -i 'mail' /root/diskusage.txt | grep -v 'cpanel' | head -3
        echo
    fi

    echo -e "${red}${bold}Important Note:${res}"
    echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    echo -e "Please avoid direct deletion of any files without confirmation."
    echo -e "Logs should be truncated safely, not removed."
    echo -e "Use the following references:"
    echo "- https://computingforgeeks.com/how-to-empty-truncate-log-files-in-linux/"
    echo "- https://www.cyberciti.biz/faq/remove-log-files-in-linux-unix-bsd/"
    echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
}

# Root user check
if [[ $(id -u) -eq 0 ]]; then
    disk
else
    echo -e "${red}Please run the script as root user.${res}"
    exit 1
fi

