/// <reference path="../pb_data/types.d.ts" />

// CORS configuration for SnapParty app
routerAdd("GET", "/*", (c) => {
  c.response().header().set('Access-Control-Allow-Origin', '*')
  return c.next()
}, $apis.requireGuestOnly())

routerAdd("POST", "/*", (c) => {
  c.response().header().set('Access-Control-Allow-Origin', '*')
  return c.next()
}, $apis.requireGuestOnly())

routerAdd("PATCH", "/*", (c) => {
  c.response().header().set('Access-Control-Allow-Origin', '*')
  return c.next()
}, $apis.requireGuestOnly())

routerAdd("DELETE", "/*", (c) => {
  c.next()
}, $apis.requireGuestOnly())

routerAdd("OPTIONS", "/*", (c) => {
  c.response().header().set('Access-Control-Allow-Origin', '*')
  c.response().header().set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS')
  c.response().header().set('Access-Control-Allow-Headers', 'Content-Type, Authorization')
  c.response().header().set('Access-Control-Max-Age', '86400')
  return c.noContent(204)
}, $apis.requireGuestOnly())
