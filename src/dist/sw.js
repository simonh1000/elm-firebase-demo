var CACHE_NAME = 'my-site-cache-v1';
var urlsToCache = [
    '/',
    '/index.js'
];

self.addEventListener('install', function(event) {
    // Perform install steps
    console.log("[sw] Install event");
    event.waitUntil(
        caches.open(CACHE_NAME)
        .then(function(cache) {
            console.log('Opened cache');
            return cache.addAll(urlsToCache);
        })
    );
});

self.addEventListener('fetch', function(event) {
    event.respondWith(
        caches.match(event.request)
        .then(function(response) {
            // Cache hit - return response
            if (response) {
                console.log("[sw] Returning cached", event.request.url);
                return response;
            }
            console.log("[sw] Fetching:", event.request.url);
            return fetch(event.request);
        })
    );
});
