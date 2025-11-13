# PocketBase CLI Setup for SnapParty

Automated setup scripts for PocketBase with all collections and CORS pre-configured.

## 🚀 Quick Setup (Ubuntu Server)

### Option 1: One-Line Install & Run

```bash
# Download and run the setup script
curl -O https://raw.githubusercontent.com/YOUR_REPO/main/pocketbase_setup/setup.sh
chmod +x setup.sh
./setup.sh
```

### Option 2: Manual Setup

1. **Upload files to your Ubuntu server:**
```bash
# On your local machine, copy files to server
scp -r pocketbase_setup/ user@your-server-ip:~/
```

2. **Run setup script on server:**
```bash
ssh user@your-server-ip
cd ~/pocketbase_setup
chmod +x setup.sh
./setup.sh
```

That's it! The script will:
- ✅ Download PocketBase
- ✅ Create all 3 collections (events, participants, photos)
- ✅ Configure CORS
- ✅ Set up proper indexes
- ✅ Start the server

## 📁 What Gets Created

```
~/snapparty-pocketbase/
├── pocketbase                          # Binary
├── pb_data/                            # Database
├── pb_migrations/
│   └── 1699000000_create_collections.js  # Auto-creates schema
└── pb_hooks/
    └── cors.pb.js                      # CORS config
```

## 🔧 Run as System Service (Production)

To keep PocketBase running even after you log out:

```bash
sudo ./setup-service.sh
```

This creates a systemd service that:
- ✅ Starts on boot
- ✅ Restarts on crash
- ✅ Runs in background
- ✅ Logs to system journal

### Service Commands

```bash
# Check status
sudo systemctl status snapparty-pocketbase

# View logs
sudo journalctl -u snapparty-pocketbase -f

# Restart
sudo systemctl restart snapparty-pocketbase

# Stop
sudo systemctl stop snapparty-pocketbase
```

## 🌐 Configure Firewall

If using UFW:

```bash
sudo ufw allow 8090/tcp
sudo ufw reload
```

## 📱 iOS App Configuration

After setup completes, you'll see your server IP. Use it in the app:

```
Settings → Server URL: http://YOUR_SERVER_IP:8090
```

## 🔍 Verify Setup

1. **Check collections were created:**
```bash
# Admin UI
open http://YOUR_SERVER_IP:8090/_/

# Or via curl
curl http://YOUR_SERVER_IP:8090/api/collections
```

2. **Test CORS:**
```bash
curl -H "Origin: http://example.com" \
     -H "Access-Control-Request-Method: POST" \
     -X OPTIONS \
     http://YOUR_SERVER_IP:8090/api/collections/events/records
```

Should return CORS headers.

## 🛠️ Manual Commands

If you prefer to run manually:

```bash
cd ~/snapparty-pocketbase
./pocketbase serve --http="0.0.0.0:8090"
```

## 📊 What Each Collection Stores

### `events`
- Event name
- Creator device ID
- Unique QR code

### `participants`
- Link to event
- User device ID
- Username
- Shots remaining (0-10)

### `photos`
- Link to event
- User device ID
- Image file (JPEG/PNG, max 10MB)
- Auto-generated thumbnails (300x300, 600x600)

## 🔐 Security Notes

**Current setup (Development):**
- ✅ CORS allows all origins
- ✅ All API rules allow all requests

**For Production:**
1. Edit `pb_hooks/cors.pb.js`:
   ```javascript
   // Change this line:
   c.response().header().set('Access-Control-Allow-Origin', '*')
   // To your domain:
   c.response().header().set('Access-Control-Allow-Origin', 'https://yourdomain.com')
   ```

2. Update collection rules in Admin UI or migrations

## 📞 Troubleshooting

### Can't connect from iOS app
```bash
# Check if PocketBase is running
ps aux | grep pocketbase

# Check port is open
sudo netstat -tlnp | grep 8090

# Check firewall
sudo ufw status
```

### Migrations not running
```bash
# Check migration files exist
ls -la pb_migrations/

# Force re-run migrations (destructive!)
rm -rf pb_data/data.db
./pocketbase serve --http="0.0.0.0:8090"
```

### View logs
```bash
# If running as service
sudo journalctl -u snapparty-pocketbase -n 100

# If running manually, check console output
```

## 🔄 Update PocketBase

```bash
cd ~/snapparty-pocketbase
sudo systemctl stop snapparty-pocketbase  # If running as service

# Backup
cp -r pb_data pb_data_backup

# Download new version
wget https://github.com/pocketbase/pocketbase/releases/latest/download/pocketbase_linux_amd64.zip
unzip -o pocketbase_linux_amd64.zip
chmod +x pocketbase

sudo systemctl start snapparty-pocketbase
```

## 📦 Complete File Structure

After running all scripts:

```
~/snapparty-pocketbase/
├── pocketbase                              # Main binary
├── pb_data/
│   ├── data.db                            # SQLite database
│   ├── logs.db                            # Request logs
│   └── storage/                           # Uploaded photos
│       └── photos/
│           └── [photo-id]/
│               ├── [filename].jpg
│               ├── thumb_300x300_[filename].jpg
│               └── thumb_600x600_[filename].jpg
├── pb_migrations/
│   └── 1699000000_create_collections.js   # Schema definition
└── pb_hooks/
    └── cors.pb.js                         # CORS middleware
```

## 🎉 That's It!

Your PocketBase server is now fully configured and ready for SnapParty!

Next steps:
1. Note your server IP from the setup output
2. Open SnapParty app
3. Go to Settings
4. Enter: `http://YOUR_SERVER_IP:8090`
5. Create an event and start snapping! 📸
