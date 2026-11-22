// Service Worker: macht die App offline-fähig.
// Strategie: sofort aus dem Cache antworten, im Hintergrund aktualisieren (Updates greifen beim nächsten Start).

const CACHE = 'boulderplan-v5';
const ASSETS = [
  './', './index.html', './manifest.webmanifest', './plan_seed.json', './css/styles.css',
  './js/main.js', './js/views.js', './js/plan.js', './js/store.js', './js/dates.js', './js/ui.js', './js/levels.js', './js/timer.js',
  './fonts/archivo-latin.woff2', './fonts/inter-latin.woff2', './icons/icon-180.png', './icons/icon-192.png', './icons/icon-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE).then((c) => c.addAll(ASSETS)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET' || new URL(req.url).origin !== self.location.origin) return;
  const key = req.mode === 'navigate' ? './index.html' : req;
  event.respondWith(
    caches.open(CACHE).then(async (cache) => {
      const cached = await cache.match(key, { ignoreSearch: true });
      const network = fetch(req)
        .then((res) => {
          // Als App-Seite (index.html) nur HTML speichern – sonst würde z. B. das direkte Öffnen
          // der Manifest-Datei die gespeicherte Startseite überschreiben.
          const isHTML = (res.headers.get('content-type') || '').includes('text/html');
          if (res.ok && (req.mode !== 'navigate' || isHTML)) cache.put(key, res.clone());
          return res;
        })
        .catch(() => cached);
      return cached || network;
    }),
  );
});
