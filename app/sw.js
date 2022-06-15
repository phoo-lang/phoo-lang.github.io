// https://web.dev/learn/pwa/serving/#stale-while-revalidate
addEventListener('fetch', e => {
    e.respondWith(
        caches.match(e.request).then(cachedResponse => {
            const networkFetch = fetch(e.request).then(response => {
                // update the cache with a clone of the network response (if it didn't 404 or not connected)
                if (response.ok)
                    caches.open('pwa-assets').then(cache => {
                        cache.put(e.request, response.clone());
                    });
                return response;
            });
            // prioritize cached response over network
            return cachedResponse || networkFetch;
        }
        )
    )
});

addEventListener('install', e => {
    console.log('Service worker installed');
    skipWaiting();
});

addEventListener('activate', e => {
    console.log('Service worker activated');
    e.waitUntil(clients.claim());
});

addEventListener('notificationclick', e => {
    console.log('Notification clicked:', e.notification.id, e.action);
    e.waitUntil(async () => {
        const allClients = await clients.matchAll({ type: 'window' });
        for (var client of allClients) {
            client.postMessage({
                event: 'notificationclick',
                notification: e.notification,
                action: e.action,
            });
        }
    });
});
