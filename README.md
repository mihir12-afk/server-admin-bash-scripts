# 🖥️ Server Administration Bash Scripts

I have created **three Bash scripts** for common Linux server administration tasks.  
These scripts are designed for CentOS, AlmaLinux, or similar distributions.  

---

## 📜 Scripts & Short Descriptions

1. **diskreport.sh**  
   - Displays disk usage statistics in a clear, color-coded format.  
   - Helps identify partitions nearing capacity.

2. **emailreport.sh**  
   - Analyzes email delivery logs (Exim) for a given time range.  
   - Shows total sent emails, bounces, top senders, recipients, and per-user stats.

3. **cronreport.sh**  
   - Lists all cron jobs on the server.  
   - Shows recent executions, durations, and flags suspicious jobs.

---

## 🚀 How to Execute the Scripts

### 1. **Local Execution**
```bash
# Make the script executable
chmod +x scriptname.sh

# Run with sudo
sudo ./scriptname.sh
```
---
### 2. **Run Directly via wget**
You can run the script without downloading it permanently:
```bash
sudo bash <(wget -qO- http://your-server-ip/scriptname.sh)
```
## 🛠️Create a Service for the Script (CentOS / AlmaLinux)
Creating a service lets you run the script automatically or trigger it easily without navigating to its folder.

Basic Steps:

1️⃣ Place your script in /usr/local/bin/
This location is in the system's $PATH, so the script can be run from anywhere.

2️⃣ Create a service file
```bash
sudo nano /etc/systemd/system/myscript.service
```
Example service file:
```ini
[Unit]
Description=My Custom Script Service

[Service]
Type=simple
ExecStart=/usr/local/bin/myscript.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
3️⃣ Enable and start the service
```bash
sudo systemctl daemon-reload
sudo systemctl enable myscript.service
sudo systemctl start myscript.service
```
4️⃣ Check service status
```bash
sudo systemctl status myscript.service
```
🌍 Run from Anywhere via wget
If hosted on a web server:
```bash
sudo bash <(wget -qO- http://your-server-ip/myscript.sh)
```
👤 Author

Mihir Savla

Linux Server Administration & DevOps Enthusiast
