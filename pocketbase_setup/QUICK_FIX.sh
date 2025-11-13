#!/bin/bash

# Quick fix for CORS issue on running server
# Run this on your Ubuntu server

echo "🔧 Fixing CORS Configuration"
echo "============================"
echo ""

cd ~/snapparty-pocketbase

# Stop PocketBase if running
echo "⏹️  Stopping PocketBase..."
pkill -f pocketbase 2>/dev/null
sleep 2

# Remove the problematic CORS hook
if [ -f "pb_hooks/cors.pb.js" ]; then
    echo "🗑️  Removing problematic CORS hook..."
    rm pb_hooks/cors.pb.js
fi

# Create a working startup script
echo "📝 Creating startup script with CORS..."
cat > start.sh << 'EOF'
#!/bin/bash
cd ~/snapparty-pocketbase
PB_CORS_ALLOW_ORIGINS="*" ./pocketbase serve --http="0.0.0.0:8090"
EOF

chmod +x start.sh

echo ""
echo "✅ Fix applied!"
echo ""
echo "🚀 Start PocketBase with:"
echo "   cd ~/snapparty-pocketbase"
echo "   ./start.sh"
echo ""
echo "Or run directly:"
echo "   PB_CORS_ALLOW_ORIGINS=\"*\" ./pocketbase serve --http=\"0.0.0.0:8090\""
echo ""
