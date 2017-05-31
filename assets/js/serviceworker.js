const version = BUILD_TIMESTAMP + '::'

const coreCacheName = version + 'core'
const dataCacheName = version + 'data'
const assetsCacheName = version + 'assets'

var coreCacheUrls = [
    '/',
    '/index.html',
    '/css/app.css',
    '/js/app.js',
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

    let url = new URL(request.url)

    if (acceptHeader.indexOf('application/json') !== -1) {
        event.respondWith(fetch(request).then(function(response) {
            addToCache(dataCacheName, request, response.clone())
            return response
        }).catch(function() {
            return caches.match(request).then(function(response) {
                return response || caches.match('/offline/')
            })
        }))
    } else if ((request.url.startsWith('http://') || request.url.startsWith('https://')) && request.method === 'GET') {
        event.respondWith(caches.match(request).then(function(response) {
            if (response)
                return response

            if (url.pathname.startsWith('/images') || url.pathname.startsWith('/fonts') || url.origin == 'https://www.google-analytics.com') {
                return fetch(request).then(function(response) {
                    addToCache(assetsCacheName, request, response.clone())
                    return response
                }).catch(function() {
                    return caches.match('/index.html')
                })
            }

            return caches.match('/index.html')
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