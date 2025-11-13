# SnapParty 📸

A collaborative disposable camera app for events! Perfect for parties, weddings, and gatherings where you want everyone to capture memories together.

## 🎯 Concept

SnapParty brings the nostalgia of disposable cameras to your events with a digital twist:

- **Create an event** and get a QR code
- **Share the QR code** with guests
- **Everyone gets 10 shots** (just like a real disposable camera!)
- **All photos collected in one place** in real-time
- **Disposable camera aesthetic** with flash effects and shot counters

## ✨ Features

### For Event Creators
- 🎉 Create events instantly
- 📱 Generate QR codes for easy sharing
- 📸 View all event photos in real-time
- 💾 Download entire event album

### For Participants
- 🔍 Join by scanning QR code or entering event code
- 📷 Classic disposable camera interface (yellow/plastic design)
- ⚡ Flash animation when taking photos
- 🎯 10-shot limit per person (just like real disposables!)
- 🖼️ View event gallery as photos are taken
- 🎨 Automatic film simulation filter (Fuji Classic Chrome style)

### Technical Features
- 🔄 Real-time photo syncing
- 🎞️ Film simulation filters for authentic look
- 📊 Shot counter display
- 🌐 Self-hosted backend (PocketBase)
- 🔒 Privacy-focused (your server, your data)
- 📱 Native iOS app

## 🏗️ Architecture

```
┌─────────────────┐
│   iOS App       │
│   (SwiftUI)     │
└────────┬────────┘
         │
         │ REST API
         │
┌────────▼────────┐
│  PocketBase     │
│  (Ubuntu)       │
└─────────────────┘
```

## 📋 Setup

### 1. Server Setup

See [POCKETBASE_SETUP.md](POCKETBASE_SETUP.md) for detailed PocketBase installation and configuration.

Quick start:
```bash
# Download and run PocketBase
wget https://github.com/pocketbase/pocketbase/releases/latest/download/pocketbase_linux_amd64.zip
unzip pocketbase_linux_amd64.zip
./pocketbase serve --http="0.0.0.0:8090"
```

### 2. iOS App Setup

1. Open `test-cam.xcodeproj` in Xcode
2. Build and run (⌘+R)
3. Go to Settings and enter your PocketBase server URL
4. Start creating events!

## 🎮 How to Use

### Creating an Event

1. Open SnapParty
2. Tap **"Create Event"**
3. Enter event name (e.g., "Sarah's Birthday")
4. Enter your name
5. Share the QR code with guests!

### Joining an Event

1. Open SnapParty
2. Tap **"Join Event"**
3. Either:
   - Scan the QR code, or
   - Enter the event code manually
4. Enter your name
5. Start taking photos!

### Taking Photos

- You get **10 shots** per event
- Tap the yellow shutter button to capture
- Flash effect animates on each shot
- Preview and confirm or retake
- Photos upload automatically to the event

### Viewing Gallery

- Tap the gallery icon (top right)
- See all event photos in real-time
- Tap any photo for full view
- Download individual photos or entire event

## 🎨 Design Philosophy

SnapParty captures the essence of disposable cameras:

- **Limited shots** create intentionality
- **No filters or edits** before taking the shot
- **Community aspect** of shared event memories
- **Nostalgic aesthetic** with yellow camera design
- **Instant gratification** with real-time gallery

## 🛠️ Tech Stack

- **Frontend**: SwiftUI (iOS 17+)
- **Backend**: PocketBase
- **Camera**: AVFoundation
- **Image Processing**: CoreImage
- **QR Codes**: CoreImage filters
- **Networking**: URLSession

## 📁 Project Structure

```
test-cam/
├── Models.swift              # Data models
├── PocketBaseService.swift   # API client
├── CameraManager.swift       # Camera functionality
├── FujifilmFilter.swift      # Image filters
├── HomeView.swift            # Landing page
├── CreateEventView.swift     # Event creation
├── JoinEventView.swift       # Event joining + QR scanner
├── EventCameraView.swift     # Main camera interface
├── EventGalleryView.swift    # Photo gallery
└── SettingsView.swift        # Server configuration
```

## 🚀 Future Ideas

- [ ] Event expiration/auto-delete
- [ ] Push notifications when new photos are added
- [ ] Multiple filter options
- [ ] Video support (like disposable video cameras!)
- [ ] Physical photo prints integration
- [ ] Event statistics and analytics
- [ ] Social sharing features
- [ ] Android version

## 🤝 Contributing

This is a personal project, but feel free to fork and customize for your own events!

## 📝 License

Personal project - use as you wish!

## 🎉 Perfect For

- 🎂 Birthday parties
- 💍 Weddings
- 🎓 Graduations
- 🏖️ Vacations
- 🎭 Festivals
- 🏠 House parties
- Any gathering where memories matter!

---

Made with ❤️ for capturing authentic moments
