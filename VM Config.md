# 1. Connect to Ubuntu VM from Windows

```powershell
ssh -i "D:/~/ssh-key-2026-04-15.key" ubuntu@12.123.12.12
```

---

# 2. Update Server First

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y curl git unzip net-tools ufw
```

---

# 3. Install Mosquitto MQTT Broker

```bash
sudo apt install -y mosquitto mosquitto-clients
sudo systemctl enable mosquitto
sudo systemctl start mosquitto
sudo systemctl status mosquitto
```

---

# 4. Configure MQTT Basic Port 1883

Create config:

```bash
sudo nano /etc/mosquitto/conf.d/external.conf
```

Paste:

```conf
listener 1883 0.0.0.0
allow_anonymous false
password_file /etc/mosquitto/passwd
```

---

# 5. Create MQTT Username & Password

```bash
sudo mosquitto_passwd -c /etc/mosquitto/passwd central-link
sudo chown mosquitto:mosquitto /etc/mosquitto/passwd
sudo chmod 600 /etc/mosquitto/passwd
```

---

# 6. Restart Mosquitto

```bash
sudo systemctl restart mosquitto
sudo systemctl status mosquitto
```

---

# 7. Open Firewall Ports

## Using UFW (Recommended)

```bash
sudo ufw allow 1883/tcp
sudo ufw allow 8883/tcp
sudo ufw allow 3000/tcp
sudo ufw enable
sudo ufw status
```

## OR Using iptables

```bash
sudo iptables -I INPUT 1 -p tcp --dport 1883 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 8883 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 3000 -j ACCEPT

sudo apt install -y iptables-persistent
sudo netfilter-persistent save
```

---

# 8. Verify Listening Ports

```bash
sudo netstat -tulpn | grep -E '1883|8883|3000'
```

---

# 9. Test Mosquitto Verbose Mode (Optional Debugging)

```bash
sudo systemctl stop mosquitto
sudo mosquitto -v -c /etc/mosquitto/conf.d/external.conf
```

Then stop with:

```bash
CTRL + C
sudo systemctl start mosquitto
```

---

# 10. Create TLS Certificates

```bash
cd /etc/mosquitto
sudo mkdir -p certs
cd certs
```

## Create CA

```bash
sudo openssl req -new -x509 -days 3650 -nodes \
-out ca.crt -keyout ca.key
```

## Create Server Certificate

```bash
sudo openssl genrsa -out server.key 2048
sudo openssl req -new -key server.key -out server.csr
sudo openssl x509 -req -in server.csr \
-CA ca.crt -CAkey ca.key -CAcreateserial \
-out server.crt -days 3650
sudo openssl rsa -in server.key -out server.key
```

## Create Client Certificate

```bash
sudo openssl genrsa -out client.key 2048
sudo openssl req -new -key client.key -out client.csr
sudo openssl x509 -req -in client.csr \
-CA ca.crt -CAkey ca.key -CAcreateserial \
-out client.crt -days 3650
sudo openssl rsa -in client.key -out client.key
```

---

# 11. Fix Certificate Permissions

```bash
sudo chown -R mosquitto:mosquitto /etc/mosquitto/certs
sudo chmod 600 /etc/mosquitto/certs/*
```

---

# 12. Enable Secure MQTT TLS Port 8883

Edit config:

```bash
sudo nano /etc/mosquitto/conf.d/external.conf
```

Use:

```conf
listener 1883 0.0.0.0

listener 8883 0.0.0.0
cafile /etc/mosquitto/certs/ca.crt
certfile /etc/mosquitto/certs/server.crt
keyfile /etc/mosquitto/certs/server.key
require_certificate true

allow_anonymous false
password_file /etc/mosquitto/passwd
```

Restart:

```bash
sudo systemctl restart mosquitto
```

---

# 13. Copy Client Certificates to Home

```bash
cp ca.crt ~
cp client.crt ~
cp client.key ~
```

---

# 14. Download Certificates to Windows

```powershell
scp -i "D:\~\ssh-key-2026-04-15.key" ubuntu@12.123.12.12:~/ca.crt "D:\~\"
scp -i "D:\~\ssh-key-2026-04-15.key" ubuntu@12.123.12.12:~/client.crt "D:\~\"
scp -i "D:\~\ssh-key-2026-04-15.key" ubuntu@12.123.12.12:~/client.key "D:\~\"
```

---

# 15. Install Node.js LTS

```bash
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
node -v
npm -v
```

---

# 16. Clone Backend Project

```bash
cd /opt
sudo git clone https://github.com/ahmedhossamfarag/clinic-iot-backend.git
sudo chown -R ubuntu:ubuntu clinic-iot-backend
cd clinic-iot-backend
npm install --omit=dev
```

---

# 17. Configure Environment Variables

```bash
nano .env
```

---

# 18. Run Backend Manually (Test)

```bash
node server.js
```

---

# 19. Run Backend as Background Service

```bash
sudo npm install -g pm2

pm2 start server.js --name clinic-iot-backend
pm2 save
pm2 startup systemd
```

Then run command shown by PM2.

---

# 20. PM2 Useful Commands

```bash
pm2 status
pm2 logs clinic-iot-backend
pm2 restart clinic-iot-backend
pm2 stop clinic-iot-backend
pm2 delete clinic-iot-backend
```

---

# 21. Update Backend Later

```bash
cd /opt/clinic-iot-backend
git fetch
git pull
npm install --omit=dev
pm2 restart clinic-iot-backend
```

---

# 22. Upload Oracle Wallet Files

```powershell
scp -i "D:\~\ssh-key-2026-04-15.key" "D:\~\ahmd-xxxx-560Z.pem" ubuntu@89.168.76.70:~/
scp -i "D:\~\ssh-key-2026-04-15.key" "D:\~\Wallet_ClinicIoT.zip" ubuntu@89.168.76.70:~/
```

---

# 23. Install Wallet Files

```bash
cd ~
unzip Wallet_ClinicIoT.zip -d /opt/clinic-iot-backend/services/wallet
mkdir -p /opt/clinic-iot-backend/services/.oci
mv ahmd-xxxx-560Z.pem /opt/clinic-iot-backend/services/.oci/
```

---

# 24. Create OCI Config

```bash
cd /opt/clinic-iot-backend/services/.oci
nano config
```

---

# 25. Test Server Port from Windows

```powershell
Test-NetConnection -ComputerName 89.168.76.70 -Port 1883
Test-NetConnection -ComputerName 89.168.76.70 -Port 8883
Test-NetConnection -ComputerName 89.168.76.70 -Port 3000
```

sudo git clone https://github.com/DottierDark/clinc-iot-frontend.git
sudo apt update
sudo apt install python3-pip -y
sudo apt install python3-venv -y
sudo python3 -m venv venv
sudo chown -R $USER:$USER /opt/clinic-iot-frontend/venv
sudo iptables -I INPUT 1 -p tcp --dport 8050 -j ACCEPT
sudo netfilter-persistent save
source venv/bin/activate
pip install -r requirements.txt
python app.py
gunicorn app:server
deactivate
pm2 start "/opt/clinic-iot-frontend/venv/bin/gunicorn app:server" --name clinic-iot-frontend
pm2 save
pm2 startup


sudo apt install nginx -y
sudo iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT
sudo netfilter-persistent save
sudo nano /etc/nginx/sites-available/clinic-iot

server {
    listen 80 default_server;

    location /api/ {
        proxy_pass http://127.0.0.1:3000/;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location / {
        proxy_pass http://127.0.0.1:8050/;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/clinic-iot /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

sudo nano /opt/clinin-iot-backend/.env
pm2 restart clinic-iot-backend
sudo nano /opt/clinin-iot-frontend/.env
pm2 restart clinic-iot-frontend

sudo iptables -L INPUT --line-numbers -n
# Delete rule 4 (Port 3000)
sudo iptables -D INPUT 4
# Delete rule 2 (Port 8050)
sudo iptables -D INPUT 2
sudo netfilter-persistent save

sudo apt update
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d central-link-iot.duckdns.org
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
sudo netfilter-persistent save

# Allow the mosquitto group to access the directories
sudo chgrp -R mosquitto /etc/letsencrypt/live/
sudo chgrp -R mosquitto /etc/letsencrypt/archive/
# Ensure the directories are readable by the group
sudo chmod -R 750 /etc/letsencrypt/live/
sudo chmod -R 750 /etc/letsencrypt/archive/
cafile /etc/letsencrypt/live/central-link-iot.duckdns.org/chain.pem
certfile /etc/letsencrypt/live/central-link-iot.duckdns.org/fullchain.pem
keyfile /etc/letsencrypt/live/central-link-iot.duckdns.org/privkey.pem

sudo nano /etc/letsencrypt/renewal/central-link-iot.duckdns.org.conf
renew_hook = systemctl restart mosquito

sudo nano /etc/letsencrypt/live/central-link-iot.duckdns.org/chain.pem
sudo systemctl restart mosquitto
pm2 restart clinic-iot-backend
-------
curl -I http://12.123.12.12
curl -I http://central-link-iot.duckdns.org
curl -k -I https://central-link-iot.duckdns.orgsudo git clone https://github.com/DottierDark/clinc-iot-frontend.git
sudo apt update
sudo apt install python3-pip -y
sudo apt install python3-venv -y
sudo python3 -m venv venv
sudo chown -R $USER:$USER /opt/clinic-iot-frontend/venv
sudo iptables -I INPUT 1 -p tcp --dport 8050 -j ACCEPT
sudo netfilter-persistent save
source venv/bin/activate
pip install -r requirements.txt
python app.py
gunicorn app:server
deactivate
pm2 start "/opt/clinic-iot-frontend/venv/bin/gunicorn app:server" --name clinic-iot-frontend
pm2 save
pm2 startup


sudo apt install nginx -y
sudo iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT
sudo netfilter-persistent save
sudo nano /etc/nginx/sites-available/clinic-iot

server {
    listen 80 default_server;

    location /api/ {
        proxy_pass http://127.0.0.1:3000/;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location / {
        proxy_pass http://127.0.0.1:8050/;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/clinic-iot /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

sudo nano /opt/clinin-iot-backend/.env
pm2 restart clinic-iot-backend
sudo nano /opt/clinin-iot-frontend/.env
pm2 restart clinic-iot-frontend

sudo iptables -L INPUT --line-numbers -n
# Delete rule 4 (Port 3000)
sudo iptables -D INPUT 4
# Delete rule 2 (Port 8050)
sudo iptables -D INPUT 2
sudo netfilter-persistent save

sudo apt update
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d central-link-iot.duckdns.org
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
sudo netfilter-persistent save

# Allow the mosquitto group to access the directories
sudo chgrp -R mosquitto /etc/letsencrypt/live/
sudo chgrp -R mosquitto /etc/letsencrypt/archive/
# Ensure the directories are readable by the group
sudo chmod -R 750 /etc/letsencrypt/live/
sudo chmod -R 750 /etc/letsencrypt/archive/
cafile /etc/letsencrypt/live/central-link-iot.duckdns.org/chain.pem
certfile /etc/letsencrypt/live/central-link-iot.duckdns.org/fullchain.pem
keyfile /etc/letsencrypt/live/central-link-iot.duckdns.org/privkey.pem

sudo nano /etc/letsencrypt/renewal/central-link-iot.duckdns.org.conf
renew_hook = systemctl restart mosquito

sudo nano /etc/letsencrypt/live/central-link-iot.duckdns.org/chain.pem
sudo systemctl restart mosquitto
pm2 restart clinic-iot-backend
-------
curl -I http://12.123.12.12
curl -I http://central-link-iot.duckdns.org
curl -k -I https://central-link-iot.duckdns.org