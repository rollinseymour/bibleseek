'use strict';

// Keeps the reader usable offline. Anything the app fetches from its own
// folder is cached, but a fresh copy is always preferred while online, so a
// deploy shows up on the next load. CanvasKit and fonts come from versioned
// gstatic URLs that never change, so those are served from the cache first.
// The app's Settings › Offline reading fills the same cache with whole Bibles
// (lib/web/offline.dart), so keep CACHE in step with it.

const CACHE = 'bibleseek';
const SCOPE = self.registration.scope;
const SCOPE_PATH = new URL(SCOPE).pathname;
const IMMUTABLE_HOSTS = ['www.gstatic.com', 'fonts.gstatic.com'];

// Content gets this long before a cached copy is used instead; the app shell
// always waits for the network, so a page never mixes two deploys' files.
const CONTENT_TIMEOUT_MS = 6000;

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(remember([SCOPE, SCOPE + 'manifest.json', SCOPE + 'favicon.png']));
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

function kind(url) {
  const u = new URL(url);
  if (u.href.startsWith(SCOPE)) return 'local';
  if (IMMUTABLE_HOSTS.includes(u.hostname)) return 'immutable';
  return null;
}

function cacheable(res, k) {
  if (res.redirected) return false;
  return res.ok || (k === 'immutable' && res.type === 'opaque');
}

async function put(key, res) {
  try {
    await (await caches.open(CACHE)).put(key, res);
  } catch (e) {
    // Out of quota: the page still works, it just won't be there offline.
  }
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms, null));

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const k = kind(req.url);
  if (!k) return;
  if (k === 'immutable') return event.respondWith(cacheFirst(event, req));
  const path = new URL(req.url).pathname;
  // Every address the app answers (/read/?ref=…) is the one page.
  if (req.mode === 'navigate' && (path === SCOPE_PATH || path === SCOPE_PATH + 'index.html')) {
    return event.respondWith(networkFirst(event, req, SCOPE, 0));
  }
  const timeout = path.startsWith(SCOPE_PATH + 'content/') ? CONTENT_TIMEOUT_MS : 0;
  event.respondWith(networkFirst(event, req, req, timeout));
});

async function networkFirst(event, req, key, timeout) {
  const network = fetch(req).then((res) => {
    if (cacheable(res, 'local')) event.waitUntil(put(key, res.clone()));
    return res;
  });
  const settled = network.catch(() => null);
  const quick = await (timeout ? Promise.race([settled, sleep(timeout)]) : settled);
  if (quick) return quick;
  const hit = await caches.match(key, { ignoreVary: true, ignoreSearch: key === SCOPE });
  return hit || network;
}

async function cacheFirst(event, req) {
  const hit = await caches.match(req, { ignoreVary: true });
  if (hit) return hit;
  const res = await fetch(req);
  if (cacheable(res, 'immutable')) event.waitUntil(put(req, res.clone()));
  return res;
}

// The first visit loads before this worker is in control, so the page sends
// the list of everything it fetched (see flutter_bootstrap.js) and the next
// load can start offline.
self.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.type === 'remember' && Array.isArray(data.urls)) {
    event.waitUntil(remember(data.urls));
  }
});

async function remember(urls) {
  const cache = await caches.open(CACHE);
  const wanted = [...new Set(urls)].filter((u) => typeof u === 'string' && kind(u));
  for (const url of wanted) {
    if (await cache.match(url, { ignoreVary: true })) continue;
    try {
      const res = await fetch(url);
      if (cacheable(res, kind(url))) await cache.put(url, res);
    } catch (e) {
      // Offline or refused; the fetch handler picks it up next time.
    }
  }
  // A Flutter upgrade moves CanvasKit to a new revision; drop the old ones.
  const current = new Set(
    wanted.map((u) => (u.match(/\/flutter-canvaskit\/([^/]+)\//) || [])[1]).filter(Boolean),
  );
  if (current.size === 0) return;
  for (const req of await cache.keys()) {
    const rev = (req.url.match(/\/flutter-canvaskit\/([^/]+)\//) || [])[1];
    if (rev && !current.has(rev)) await cache.delete(req);
  }
}
