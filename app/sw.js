const CACHE_NAME = 'phoo-cache';
const SYNC_TAG = 'phoo-sync-files-offline';

function log(...message) {
    console.log('[service worker]', ...message);
}

// https://web.dev/learn/pwa/serving/#stale-while-revalidate
addEventListener('fetch', e => {
    e.respondWith(async () => {
        log('fetching', e.request.url, '...');
        const cache_response = await caches.match(e.request);
        if (!navigator.onLine) {
            log('offline, checking cache...');
            if (cache_response) {
                log('cache response all good :)');
                return cache_response;
            } else {
                log('no cache, no internet :(');
                const filename = /\/([^/]*)$/.exec(e.request.url)[1];
                await queueLater(e.request, filename);
                return new Response(`You are offline; ${filename} has been queued for later download.`, { status: 499, statusText: 'You are offline' });
            }
        } else {
            log('have internet, checking cache anyway...');
            const net_response_promise = fetch(e.request).then(resp => {
                log(e.request.url, 'updated from network');
                caches.open(CACHE_NAME).then(cache => cache.put(e.request, resp.clone()));
                return resp;
            });
            if (cache_response) {
                log('has cached response');
                return cache_response;
            } else {
                log('no cached, must wait for network');
                const net_response = await net_response_promise;
                log('network done');
                return net_response;
            }
        }
    });
});

addEventListener('install', e => {
    log('installed');
    skipWaiting();
});

addEventListener('activate', e => {
    log('activated');
    e.waitUntil(async () => {
        await sync.register(SYNC_TAG);
        clients.claim();
    });
});

addEventListener('notificationclick', e => {
    log('Notification clicked:', e.notification.id, e.action);
    e.waitUntil(tellAllWindows({ event: 'notificationclick', notification: e.notification, action: e.action }));
});


async function queueLater(request, filename) {
    var count = await fakeGet('sync-queue/count') ?? 0;
    await fakeSet(`sync-queue/${count}`, { url: request.url, file: filename, method: request.method });
    count++;
    await fakeSet('sync-queue/count', count);
}

async function tellAllWindows(message) {
    const allClients = await clients.matchAll({ type: 'window' });
    allClients.forEach(client => client.postMessage(message));
}

addEventListener('sync', e => {
    if (e.tag === SYNC_TAG) {
        e.waitUntil(finishQueuedRequests());
    }
});

async function finishQueuedRequests() {
    const count = await fakeGet('sync-queue/count') ?? 0;
    log('starting sync of queued requests:', count, 'pending');
    if (!count) return;
    for (var i = 0; i < count; i++) {
        log('queued #' + i);
        var info = await fakeGet(`sync-queue/${i}`);
        if (!info) {
            log('whoops, no info for request #' + i);
            continue;
        }
        var { url, filename, method } = info;
        var req = new Request(url, { method });
        log('fetching', url);
        var resp = await fetch(req);
        log('caching...');
        await caches.open(CACHE_NAME).then(cache => cache.put(req, resp.clone()));
        log('notifying windows...');
        await tellAllWindows({ event: 'synced', filename });
    }
    log('done. zeroing count...');
    await fakeSet('sync-queue/count', 0);
    log('done.');
}

const FAKE_FOLDER = '/__service_worker__/';
async function fakeGet(resource) {
    const fakeRequest = new Request(FAKE_FOLDER + resource);
    const fakeResponse = await caches.match(fakeRequest);
    if (!fakeResponse) return null;
    const value = await fakeResponse.json();
    return value;
}

async function fakeSet(resource, value) {
    const fakeRequest = new Request(FAKE_FOLDER + resource);
    const fakeResponse = new Response(JSON.stringify(value), { status: 200, statusText: 'ok' });
    await caches.open(CACHE_NAME).then(cache => cache.put(fakeRequest, fakeResponse));
}

async function fakeDel(resource) {
    const fakeRequest = new Request(FAKE_FOLDER + resource);
    await caches.open(CACHE_NAME).then(cache => cache.delete(fakeRequest));
}
