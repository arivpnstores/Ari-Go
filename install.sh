#!/bin/bash
# =========================================
# Menu Install Golang + Ari-go + systemctl
# Author : Ari Setiawan 
# =========================================

GO_VERSION="1.22.0"
SERVICE_PATH="/etc/systemd/system/ari-go.service"

install_golang() {
    echo "=== Installing Dependencies ==="
    apt update -y
    apt upgrade -y
    apt install inotify-tools -y
    apt install wget curl build-essential gcc -y

    echo "=== Installing Golang v$GO_VERSION ==="
    wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -O go${GO_VERSION}.linux-amd64.tar.gz
    rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin

    go version
    echo "=== Golang installation complete! ==="
}

install_ari-go() {
    echo "=== Installing Go Modules ==="
    apt install wget unzip -y   # Debian/Ubuntu
    wget https://github.com/arivpnstores/Ari-Go/raw/main/Ari-go.zip -O Ari-go.zip
    unzip Ari-go.zip
    cd Ari-go
    go get
    echo "=== Ari-go installation complete! ==="
}

start_ari-go() {
    echo "=============================="
    echo " 🚀 Setup Kirim QR Code via Telegram"
    echo "=============================="
    echo ""

    # Minta Token & Chat ID
    read -p "Masukkan Bot Token Telegram: " BOT_TOKEN
    read -p "Masukkan Chat ID Telegram: " CHAT_ID

    echo "=== Menjalankan Ari-go (Tekan CTRL+C untuk stop) ==="
    cd /root/Ari-go
    /usr/local/go/bin/go run main.go &

    echo "⏳ Menunggu /root/Ari-go/qrcode.png dibuat atau diupdate..."
    while inotifywait -e create -e modify /root/Ari-go/qrcode.png; do
        # Copy ke /root biar aman
        cp -f /root/Ari-go/qrcode.png /root/qrcode.png

        echo "📤 Mengirim QR Code ke Telegram..."
        curl -s -F photo=@/root/qrcode.png \
        "https://api.telegram.org/bot${BOT_TOKEN}/sendPhoto?chat_id=${CHAT_ID}&caption=Scan QR Code"

        if [ $? -eq 0 ]; then
            echo "✅ QR Code berhasil dikirim ke Telegram!"
        else
            echo "⚠️ Gagal mengirim QR Code!"
        fi
    done
}



setup_systemctl() {
    echo "=== Creating systemd service ==="
    cat > $SERVICE_PATH << EOF
[Unit]
Description=ari-go Go WhatsApp Bot
After=network.target

[Service]
Type=simple
WorkingDirectory=/root/Ari-go
ExecStart=/usr/local/go/bin/go run main.go
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reexec
    systemctl daemon-reload
    systemctl enable ari-go.service
    systemctl start ari-go.service

    echo "=== systemctl service created & started ==="
    echo "Cek status: systemctl status ari-go.service"
    echo "Cek log   : journalctl -u ari-go.service -f"
}

# Menu
# Password keamanan
SEC_PASS="GolangBotJpm"

# Minta password sebelum masuk menu
read -sp "🔑 Masukkan Password: " input_pass
echo
if [[ $input_pass != "$SEC_PASS" ]]; then
    echo "❌ Password salah! Keluar..."
    exit 1
fi

# Kalau password benar, lanjut ke menu
while true; do
    clear
    echo "==============================="
    echo "      MENU INSTALL BOT GO"
    echo "==============================="
    echo "1. Install Golang ($GO_VERSION)"
    echo "2. Install Ari-go"
    echo "3. Start Ari-go (Manual)"
    echo "4. Buat & Jalankan systemctl"
    echo "0. Keluar"
    echo "==============================="
    read -p "Pilih menu [0-4]: " choice

    case $choice in
        1) install_golang ;;
        2) install_ari-go ;;
        3) start_ari-go ;;
        4) setup_systemctl ;;
        0) echo "Keluar..."; exit 0 ;;
        *) echo "Pilihan tidak valid!" ;;
    esac
    read -p "Tekan Enter untuk kembali ke menu..."
done