const version = BUILD_TIMESTAMP + '::'

const coreCacheName = version + 'core'
const dataCacheName = version + 'data'
const assetsCacheName = version + 'assets'

var coreCacheUrls = [
    '/',
    '/fonts/fontawesome-webfont.woff2',
    '/fonts/element-icons.woff',
    '/fonts/element-icons.ttf',
    '/images/logo.svg',
]

function addToCache(cacheName, request, response) {
    caches.open(cacheName).then(function(cache) {
        return cache.put(request, response)
    })
}

self.addEventListener('install', function(event) {
    event.waitUntil(caches.open(coreCacheName).then(function(cache) {
        return cache.addAll(coreCacheUrls)
    }))
})

self.addEventListener('fetch', function(event) {
    var request = event.request
    var acceptHeader = request.headers.get('Accept')
    var url = new URL(request.url)

    if (url.origin !== 'https://liqu.io' || url.pathname.startsWith('/api/') || url.pathname.startsWith('/page/') || url.pathname.startsWith('/resource/')) {
        event.respondWith(fetch(request).then(function(response) {
            addToCache(dataCacheName, request, response.clone())
            return response
        }).catch(function() {
            return caches.match(request).then(function(response) {
                return response
            })
        }))
    } else if ((request.url.startsWith('http://') || request.url.startsWith('https://')) && request.method === 'GET') {
        event.respondWith(caches.match(request).then(function(response) {
            if (response)
                return response

            var is_asset = url.pathname.startsWith('/js/') || url.pathname.startsWith('/css/') || url.pathname.startsWith('/images/') || url.pathname.startsWith('/fonts/')
            if (!is_asset)
                return caches.match('/')

            return fetch(request).then(function(response) {
                addToCache(assetsCacheName, request, response.clone())
                return response
            }).catch(function() {
                return caches.match('/')
            })
        }))
    }
})

function clearCaches() {
    return caches.keys().then(function(keys) {
        return Promise.all(keys.filter(function(key) {
            return key.indexOf(version) !== 0
        }).map(function(key) {
            return caches.delete(key)
        }))
    })
}

self.addEventListener('activate', function(event) {
    event.waitUntil(
        clearCaches().then(function() {
            return self.clients.claim()
        })
    )
})