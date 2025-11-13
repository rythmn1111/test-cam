# CORS Configuration Fix

Your PocketBase server is running! ✅

The CORS error is non-fatal - your server is working at:
**http://217.217.249.170:8090**

## Quick Fix Options

### Option 1: Delete the Hook File (Simplest)

```bash
# Stop PocketBase (Ctrl+C)
cd ~/snapparty-pocketbase
rm pb_hooks/cors.pb.js

# Restart
./pocketbase serve --http="0.0.0.0:8090"
```

Then configure CORS through the Admin UI:
1. Go to **Settings** → **Application**
2. Add to "CORS allowed origins": `*` (for development)

### Option 2: Use Environment Variable

```bash
# Set CORS via environment variable
export PB_CORS_ALLOW_ORIGINS="*"
./pocketbase serve --http="0.0.0.0:8090"
```

### Option 3: Update the Hook File

Replace `pb_hooks/cors.pb.js` with this simpler version:

```javascript
// Simple CORS middleware
onBeforeApiRequest((e) => {
  const origin = e.httpContext.request().header.get('Origin')

  e.httpContext.response().header().set('Access-Control-Allow-Origin', '*')
  e.httpContext.response().header().set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS')
  e.httpContext.response().header().set('Access-Control-Allow-Headers', 'Content-Type, Authorization')

  if (e.httpContext.request().method == 'OPTIONS') {
    e.httpContext.response().header().set('Access-Control-Max-Age', '86400')
  }
})
```

## Test if CORS is Working

```bash
curl -H "Origin: http://example.com" \
     -H "Access-Control-Request-Method: POST" \
     -X OPTIONS \
     http://217.217.249.170:8090/api/collections/events/records
```

Should return headers with `Access-Control-Allow-Origin: *`

## For Now: Try the App Anyway!

The app might work even without the hook because:
1. iOS apps sometimes don't enforce CORS like browsers do
2. PocketBase has some default CORS handling

**Test it:**
1. Open SnapParty app
2. Settings → Enter: `http://217.217.249.170:8090`
3. Try creating an event

If it works, you're good! If not, apply one of the fixes above.

## Best Production Setup

For production, use **Option 1** (delete hook + Admin UI) because:
- ✅ Most reliable
- ✅ Easy to configure
- ✅ No hook syntax issues
- ✅ Built-in PocketBase feature
