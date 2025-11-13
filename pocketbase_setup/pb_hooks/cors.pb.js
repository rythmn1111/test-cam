/// <reference path="../pb_data/types.d.ts" />

// CORS configuration for SnapParty app
onBeforeServe((e) => {
  e.router.use((next) => {
    return (c) => {
      // Allow all origins (for development)
      // For production, replace * with your specific domain
      c.response().header().set('Access-Control-Allow-Origin', '*')
      c.response().header().set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS')
      c.response().header().set('Access-Control-Allow-Headers', 'Content-Type, Authorization')
      c.response().header().set('Access-Control-Max-Age', '86400') // 24 hours

      // Handle preflight requests
      if (c.request().method == 'OPTIONS') {
        return c.noContent(204)
      }

      return next(c)
    }
  })
})

// Optional: Log API requests for debugging
onBeforeServe((e) => {
  e.router.use((next) => {
    return (c) => {
      console.log(`[${new Date().toISOString()}] ${c.request().method} ${c.request().url}`)
      return next(c)
    }
  })
})
