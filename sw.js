// Minimal service worker: lets the browser treat the site as an installable
// app. Everything goes straight to the network (no cache), so updates are
// never stale.
self.addEventListener('install', function () { self.skipWaiting(); });
self.addEventListener('activate', function (e) { e.waitUntil(self.clients.claim()); });
self.addEventListener('fetch', function (e) { e.respondWith(fetch(e.request)); });
