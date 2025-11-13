#!/bin/bash

# Create systemd service for PocketBase
# Run this script with sudo

set -e

echo "🔧 Setting up PocketBase as a system service"
echo "============================================"
echo ""

# Configuration
POCKETBASE_DIR="$HOME/snapparty-pocketbase"
SERVICE_NAME="snapparty-pocketbase"
PORT=8090

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run with sudo"
    exit 1
fi

# Get the actual user (not root)
ACTUAL_USER=${SUDO_USER:-$USER}
ACTUAL_HOME=$(eval echo ~$ACTUAL_USER)
POCKETBASE_DIR="$ACTUAL_HOME/snapparty-pocketbase"

# Verify PocketBase directory exists
if [ ! -d "$POCKETBASE_DIR" ]; then
    echo "❌ PocketBase directory not found: $POCKETBASE_DIR"
    echo "   Run setup.sh first!"
    exit 1
fi

# Create systemd service file
echo "📝 Creating systemd service..."
cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=SnapParty PocketBase Server
After=network.target
Documentation=https://pocketbase.io/docs/

[Service]
Type=simple
User=$ACTUAL_USER
Group=$ACTUAL_USER
WorkingDirectory=$POCKETBASE_DIR
ExecStart=$POCKETBASE_DIR/pocketbase serve --http="0.0.0.0:$PORT"
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=snapparty-pocketbase

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=$POCKETBASE_DIR

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
echo "🔄 Reloading systemd..."
systemctl daemon-reload

# Enable service
echo "✅ Enabling service..."
systemctl enable ${SERVICE_NAME}.service

# Start service
echo "🚀 Starting service..."
systemctl start ${SERVICE_NAME}.service

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "✅ Service setup complete!"
echo ""
echo "📊 Service Commands:"
echo "   Status:  sudo systemctl status ${SERVICE_NAME}"
echo "   Stop:    sudo systemctl stop ${SERVICE_NAME}"
echo "   Start:   sudo systemctl start ${SERVICE_NAME}"
echo "   Restart: sudo systemctl restart ${SERVICE_NAME}"
echo "   Logs:    sudo journalctl -u ${SERVICE_NAME} -f"
echo ""
echo "🌐 Server URL: http://$SERVER_IP:$PORT"
echo "🔧 Admin UI:   http://$SERVER_IP:$PORT/_/"
echo ""
echo "🎉 PocketBase is now running as a service!"
