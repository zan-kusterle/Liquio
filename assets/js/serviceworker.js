const version = BUILD_TIMESTAMP + '::'

const coreCacheName = version + 'core'
const dataCacheName = version + 'data'
const assetsCacheName = version + 'assets'

var coreCacheUrls = [
	'/',
	'/css/app.css',
	'/js/app.js',
	'/fonts/element-icons.woff',
	'/fonts/element-icons.ttf',
	'/images/logo.svg',
]

function addToCache(cacheName, request, response) {
	caches.open(cacheName)
		.then( cache => cache.put(request, response) )
}

self.addEventListener('install', function(event) {
	event.waitUntil(
		caches.open(coreCacheName)
			.then(function(cache) {
				return cache.addAll(coreCacheUrls)
			})
	)
})

self.addEventListener('fetch', function(event) {
	let request = event.request
	let acceptHeader = request.headers.get('Accept')

	if (acceptHeader.indexOf('application/json') !== -1) {
		event.respondWith(fetch(request).then(response => {
			addToCache(dataCacheName, request, response.clone())
			return response
		}).catch( () => {
			return caches.match(request).then(response => { 
				return response || caches.match('/offline/') 
			})
		}))
	} else {
		event.respondWith(caches.match(request).then(response => { 
			return response || fetch(request).then( response => {
				addToCache(assetsCacheName, request, response.clone())
				return response
			}).catch( () => { 
				return new Response('<svg role="img" aria-labelledby="offline-title" viewBox="0 0 400 300" xmlns="http://www.w3.org/2000/svg"><title id="offline-title">Offline</title><g fill="none" fill-rule="evenodd"><path fill="#D8D8D8" d="M0 0h400v300H0z"/><text fill="#9B9B9B" font-family="Helvetica Neue,Arial,Helvetica,sans-serif" font-size="72" font-weight="bold"><tspan x="93" y="172">offline</tspan></text></g></svg>', { headers: { 'Content-Type': 'image/svg+xml' }})
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
			})
		)
	})
}

self.addEventListener('activate', event => {
	event.waitUntil(
		clearCaches().then( () => { 
			return self.clients.claim() 
		})
	)
})