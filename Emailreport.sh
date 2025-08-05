#!/bin/bash
# Author: Mihir Savla
# Script for VPS/DEDI email delivery analysis (last 24 hours)

# Color Setup
red=$(tput setaf 1)
gre=$(tput setaf 2)
yel=$(tput setaf 3)
vio=$(tput setaf 5)
cya=$(tput setaf 6)
res=$(tput sgr0)
bold=$(tput bold)

email_report() {
    clear

    echo -e "\n${bold}${cya}Email Deliverability Report (Last 24h):${res}"
    echo "---------------------------------------------"

    LOGFILE="/var/log/exim_mainlog"
    TMPFILE="/tmp/mailreport.tmp"
    BOUNCEFILE="/tmp/bouncereport.tmp"

    # Time range: last 24 hours
    since=$(date -d '24 hours ago' "+%Y-%m-%d %H:%M:%S")

    echo -e "\n${bold}${gre}Parsing emails since: $since${res}\n"

    # 1. Filter successful sent emails
    grep "<=" "$LOGFILE" | awk -v since="$since" '
        BEGIN { FS=" "; OFS="|" }
        {
            datetime = $1 " " $2
            if (datetime > since) {
                sender=""; rcpt=""; subj=""
                for(i=1;i<=NF;i++) {
                    if ($i ~ /^<=/) sender=$(i+1)
                    if ($i == "for") rcpt=$(i+1)
                    if ($i ~ /^T=/) {
                        subj=substr($i, 3)
                        for (j=i+1;j<=NF;j++) {
                            if ($j ~ /^from$/) break
                            subj = subj " " $j
                        }
                    }
                }
                print datetime, sender, rcpt, subj
            }
        }
    ' > "$TMPFILE"

    # 2. Bounce Detection
    grep -E "==|\*\*" "$LOGFILE" | awk -v since="$since" '
        BEGIN { FS=" "; OFS="|" }
        {
            datetime = $1 " " $2
            if (datetime > since) {
                for(i=1;i<=NF;i++) {
                    if ($i ~ /^==|^\*\*/) sender=$(i+1)
                }
                print datetime, sender
            }
        }
    ' > "$BOUNCEFILE"

    total=$(wc -l < "$TMPFILE")
    unique_rcpt=$(cut -d'|' -f3 "$TMPFILE" | sort | uniq | wc -l)
    bounce_count=$(wc -l < "$BOUNCEFILE")

    echo -e "${bold}${yel}Total Sent Emails: ${red}$total${res}"
    echo -e "${bold}${yel}Unique Recipients: ${red}$unique_rcpt${res}"
    echo -e "${bold}${red}Total Bounced Emails: $bounce_count${res}\n"

    echo -e "${bold}${cya}Top Senders:${res}"
    echo "----------------------"
    cut -d'|' -f2 "$TMPFILE" | sort | uniq -c | sort -nr | head -5

    echo -e "\n${bold}${cya}Top Recipients:${res}"
    echo "----------------------"
    cut -d'|' -f3 "$TMPFILE" | sort | uniq -c | sort -nr | head -5

    echo -e "\n${bold}${cya}Top Subjects:${res}"
    echo "----------------------"
    cut -d'|' -f4 "$TMPFILE" | sort | uniq -c | sort -nr | head -5

    echo -e "\n${bold}${vio}Hourly Volume:${res}"
    echo "----------------------"
    cut -d'|' -f1 "$TMPFILE" | cut -d' ' -f2 | cut -d: -f1 | sort | uniq -c

    echo -e "\n${bold}${gre}Per-User Email Volume (based on domain mapping):${res}"
    echo "---------------------------------------------------"

    if [ -f /etc/trueuserdomains ]; then
        while read -r domain user; do
            count=$(cut -d'|' -f2 "$TMPFILE" | grep -c "@$domain")
            if [ "$count" -gt 0 ]; then
                printf "$vio%-15s $res→ $yel%4s emails sent$res\n" "$user" "$count"
            fi
        done < /etc/trueuserdomains
    else
        echo -e "${red}/etc/trueuserdomains not found — cannot map senders to users.${res}"
    fi

    echo -e "\n${bold}${yel}Current Queue:${res}"
    echo "----------------------"
    exim -bp | exiqsumm

    echo -e "\n${bold}${red}Important Note:${res}"
    echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    echo "- Deliveries analyzed: '<=' lines only"
    echo "- Bounces: detected via '==' and '**'"
    echo "- User mapping based on domain ownership (/etc/trueuserdomains)"
    echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

    # Only remove temp files, not the script
    rm -f "$TMPFILE" "$BOUNCEFILE"
}

# Root user check
if [[ $(id -u) -eq 0 ]]; then
    email_report
else
    echo -e "${red}Please run the script as root user.${res}"
    exit 1
fi