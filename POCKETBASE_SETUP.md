# PocketBase Setup Guide for SnapParty

## 1. Install PocketBase on Ubuntu Server

```bash
# Download PocketBase
wget https://github.com/pocketbase/pocketbase/releases/download/v0.22.0/pocketbase_0.22.0_linux_amd64.zip

# Extract
unzip pocketbase_0.22.0_linux_amd64.zip

# Make executable
chmod +x pocketbase

# Run PocketBase
./pocketbase serve --http="0.0.0.0:8090"
```

## 2. Create Collections

Access the Admin UI at `http://your-server-ip:8090/_/` and create these collections:

### Collection: `events`
Fields:
- `name` (Text, Required)
- `createdBy` (Text, Required) - Device ID of creator
- `qrCode` (Text, Required, Unique) - UUID for event

### Collection: `participants`
Fields:
- `eventId` (Relation to events, Required)
- `userId` (Text, Required) - Device ID
- `userName` (Text, Required)
- `shotsRemaining` (Number, Required, Default: 10)

### Collection: `photos`
Fields:
- `eventId` (Relation to events, Required)
- `userId` (Text, Required) - Device ID of uploader
- `image` (File, Required) - The photo file

## 3. Configure API Rules

For each collection, set these API rules in the PocketBase Admin UI:

### events
- List/View: `@request.auth.id != ""` (or make public for simplicity)
- Create: Allow all
- Update: Only creator
- Delete: Only creator

### participants
- List/View: Allow all
- Create: Allow all
- Update: Only owner
- Delete: Only owner

### photos
- List/View: Allow all
- Create: Allow all
- Update: No one
- Delete: Only uploader

**For development/testing**, you can set all rules to allow all requests:
```
// Simply leave empty or use:
@request.data != null
```

## 4. Enable CORS

Create a file `pb_hooks/main.pb.js`:

```javascript
onBeforeServe((e) => {
    e.router.use((next) => {
        return (c) => {
            c.response().header().set('Access-Control-Allow-Origin', '*')
            c.response().header().set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
            c.response().header().set('Access-Control-Allow-Headers', 'Content-Type, Authorization')

            if (c.request().method == 'OPTIONS') {
                return c.noContent(204)
            }

            return next(c)
        }
    })
})
```

## 5. Run as a Service (Production)

Create `/etc/systemd/system/pocketbase.service`:

```ini
[Unit]
Description=PocketBase
After=network.target

[Service]
Type=simple
User=YOUR_USER
WorkingDirectory=/path/to/pocketbase
ExecStart=/path/to/pocketbase/pocketbase serve --http="0.0.0.0:8090"
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable pocketbase
sudo systemctl start pocketbase
```

## 6. Configure App

1. Open SnapParty app
2. Tap Settings (gear icon)
3. Enter your server URL: `http://your-server-ip:8090`
4. Save

## Testing Locally

For testing on your Mac before deploying:

```bash
# Run PocketBase locally
./pocketbase serve

# Use this URL in the app settings:
http://localhost:8090
```

## Firewall Configuration

If using UFW on Ubuntu:
```bash
sudo ufw allow 8090/tcp
```

## Troubleshooting

### Can't connect from iOS app
- Check firewall settings
- Ensure PocketBase is running on 0.0.0.0, not localhost
- Verify IP address is correct
- Check CORS settings

### Photos not uploading
- Check `photos` collection has `image` field of type File
- Verify API rules allow creating photos
- Check file size limits in PocketBase settings

### Events not found
- Verify `qrCode` field exists and is properly indexed
- Check API rules for events collection
