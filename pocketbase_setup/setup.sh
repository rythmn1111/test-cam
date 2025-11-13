#!/bin/bash

# SnapParty PocketBase Setup Script
# This script downloads, configures, and runs PocketBase with the required schema

set -e  # Exit on error

echo "🎉 SnapParty PocketBase Setup"
echo "=============================="
echo ""

# Configuration
POCKETBASE_VERSION="0.22.20"
INSTALL_DIR="$HOME/snapparty-pocketbase"
PORT=8090

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo -e "${YELLOW}Warning: This script is designed for Linux (Ubuntu). You're running: $OSTYPE${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create installation directory
echo "📁 Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Download PocketBase
if [ ! -f "pocketbase" ]; then
    echo "⬇️  Downloading PocketBase v$POCKETBASE_VERSION..."
    wget -q --show-progress "https://github.com/pocketbase/pocketbase/releases/download/v${POCKETBASE_VERSION}/pocketbase_${POCKETBASE_VERSION}_linux_amd64.zip"

    echo "📦 Extracting..."
    unzip -q "pocketbase_${POCKETBASE_VERSION}_linux_amd64.zip"
    rm "pocketbase_${POCKETBASE_VERSION}_linux_amd64.zip"

    chmod +x pocketbase
    echo -e "${GREEN}✓ PocketBase downloaded${NC}"
else
    echo -e "${GREEN}✓ PocketBase already exists${NC}"
fi

# Create directories
echo "📂 Creating directories..."
mkdir -p pb_migrations
mkdir -p pb_hooks
mkdir -p pb_data

# Copy migration files
echo "📝 Setting up database schema..."
cat > pb_migrations/1699000000_create_collections.js << 'EOF'
/// <reference path="../pb_data/types.d.ts" />

// Create events collection
migrate((db) => {
  const collection = new Collection({
    name: "events",
    type: "base",
    system: false,
    schema: [
      {
        name: "name",
        type: "text",
        required: true,
      },
      {
        name: "createdBy",
        type: "text",
        required: true,
      },
      {
        name: "qrCode",
        type: "text",
        required: true,
      },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_qrCode ON events (qrCode)",
    ],
    listRule: "",
    viewRule: "",
    createRule: "",
    updateRule: "",
    deleteRule: "",
  });

  return Dao(db).saveCollection(collection);
}, (db) => {
  const dao = new Dao(db);
  const collection = dao.findCollectionByNameOrId("events");
  return dao.deleteCollection(collection);
});

// Create participants collection
migrate((db) => {
  const collection = new Collection({
    name: "participants",
    type: "base",
    system: false,
    schema: [
      {
        name: "eventId",
        type: "relation",
        required: true,
        options: {
          collectionId: "",
          cascadeDelete: true,
          maxSelect: 1,
          displayFields: ["name"],
        },
      },
      {
        name: "userId",
        type: "text",
        required: true,
      },
      {
        name: "userName",
        type: "text",
        required: true,
      },
      {
        name: "shotsRemaining",
        type: "number",
        required: true,
        options: {
          min: 0,
          max: 10,
        },
      },
    ],
    listRule: "",
    viewRule: "",
    createRule: "",
    updateRule: "",
    deleteRule: "",
  });

  const eventsCollection = Dao(db).findCollectionByNameOrId("events");
  collection.schema[0].options.collectionId = eventsCollection.id;

  return Dao(db).saveCollection(collection);
}, (db) => {
  const dao = new Dao(db);
  const collection = dao.findCollectionByNameOrId("participants");
  return dao.deleteCollection(collection);
});

// Create photos collection
migrate((db) => {
  const collection = new Collection({
    name: "photos",
    type: "base",
    system: false,
    schema: [
      {
        name: "eventId",
        type: "relation",
        required: true,
        options: {
          collectionId: "",
          cascadeDelete: true,
          maxSelect: 1,
          displayFields: ["name"],
        },
      },
      {
        name: "userId",
        type: "text",
        required: true,
      },
      {
        name: "image",
        type: "file",
        required: true,
        options: {
          maxSelect: 1,
          maxSize: 10485760,
          mimeTypes: ["image/jpeg", "image/png", "image/jpg"],
          thumbs: ["300x300", "600x600"],
          protected: false,
        },
      },
    ],
    listRule: "",
    viewRule: "",
    createRule: "",
    updateRule: "",
    deleteRule: "",
  });

  const eventsCollection = Dao(db).findCollectionByNameOrId("events");
  collection.schema[0].options.collectionId = eventsCollection.id;

  return Dao(db).saveCollection(collection);
}, (db) => {
  const dao = new Dao(db);
  const collection = dao.findCollectionByNameOrId("photos");
  return dao.deleteCollection(collection);
});
EOF

# Skip CORS hook - will configure via environment variable instead
echo "🌐 CORS will be configured via environment variable"
echo -e "${GREEN}✓ Schema configured${NC}"

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "✅ Setup complete!"
echo ""
echo "📱 iOS App Configuration:"
echo -e "   Server URL: ${GREEN}http://$SERVER_IP:$PORT${NC}"
echo ""
echo "🚀 To start PocketBase:"
echo "   cd $INSTALL_DIR"
echo "   ./pocketbase serve --http=\"0.0.0.0:$PORT\""
echo ""
echo "🔧 Admin UI will be available at:"
echo -e "   ${GREEN}http://$SERVER_IP:$PORT/_/${NC}"
echo ""
echo "📋 Collections will be created automatically on first run!"
echo ""

# Ask if user wants to start now
read -p "Start PocketBase now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🎉 Starting PocketBase with CORS enabled..."
    echo "   Press Ctrl+C to stop"
    echo ""
    # Start with CORS environment variable
    PB_CORS_ALLOW_ORIGINS="*" ./pocketbase serve --http="0.0.0.0:$PORT"
fi
