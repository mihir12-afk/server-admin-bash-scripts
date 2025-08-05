#!/bin/bash

# Colors
red=$(tput setaf 1)
gre=$(tput setaf 2)
yel=$(tput setaf 3)
vio=$(tput setaf 5)
cya=$(tput setaf 6)
res=$(tput sgr 0)

echo "${vio}========== CRON JOB REPORT ==========${res}"

# 1. Total cron jobs per user
echo -e "\n${cya}>> Number of active cron jobs per user:${res}"
for user in $(cut -f1 -d: /etc/passwd); do
  crontab -l -u "$user" &>/dev/null
  if [ $? -eq 0 ]; then
    count=$(crontab -l -u "$user" | grep -vE '^#|^$' | wc -l)
    echo "$user : $count job(s)"
  fi
done

# 2. Currently running cron jobs
echo -e "\n${cya}>> Currently running cron jobs:${res}"
ps -eo pid,etime,cmd | grep cron | grep -v grep | grep -v 'cronreport.sh'

# 3. Last 5 cron executions (parsed from syslog or cron log)
echo -e "\n${cya}>> Last 5 executed cron jobs (system-wide):${res}"
cronlog=$(grep -Ei 'cron.*(CMD|USER)' /var/log/cron 2>/dev/null | tail -n 5)
if [ -z "$cronlog" ]; then
  echo "No cron activity found in /var/log/cron"
else
  echo "$cronlog"
fi

# 4. Suspicious or uncommon cron jobs
echo -e "\n${yel}>> Suspicious or uncommon cron jobs (if any):${res}"

suspicious_entries=()
for user in $(cut -f1 -d: /etc/passwd); do
  tmpfile="/tmp/cron_check_$user"
  crontab -l -u "$user" 2>/dev/null > "$tmpfile"

  # Skip if user has no crontab
  if [ ! -s "$tmpfile" ]; then
    rm -f "$tmpfile"
    continue
  fi

  while IFS= read -r line; do
    # Ignore comments and SHELL/MAILTO variables
    [[ "$line" =~ ^#.*$ || "$line" =~ ^[[:space:]]*(SHELL|MAILTO|PATH)= ]] && continue

    # Skip known safe cPanel/WHM cron scripts
    if [[ "$line" =~ /usr/local/cpanel/scripts/ ]]; then
      continue
    fi

    # Look for encoded payloads or obfuscated execution
    if echo "$line" | grep -Eiq '(base64 -d|eval|bash -c|curl|wget|nc|ncat|perl -e|python -c|xxd|openssl enc)'; then
      suspicious_entries+=("$user")
      echo -e "${red}User: $user${res}"
      echo "$line"
    fi
  done < "$tmpfile"

  rm -f "$tmpfile"
done

if [ ${#suspicious_entries[@]} -eq 0 ]; then
  echo -e "${gre}No suspicious cron jobs detected.${res}"
fi

echo -e "\n${vio}========== END OF REPORT ==========${res}"
