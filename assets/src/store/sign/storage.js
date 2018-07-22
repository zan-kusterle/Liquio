/* globals chrome, IS_EXTENSION */

let storage = {
	get (key, type) {
		let decode = (v) => {
			if (!v) return null
			if (type === Array && !Array.isArray(v)) { return v.split(',') }
			return v
		}

		return new Promise((resolve) => {
			if (IS_EXTENSION) {
				chrome.storage.local.get(key, (data) => {
					resolve(decode(data[key]))
				})
			} else {
				resolve(decode(localStorage.getItem(key)))
			}
		})
	},
	set (key, value) {
		let encoded = value
		if (Array.isArray(value)) { encoded = value.join(',') }

		if (IS_EXTENSION) {
			let data = {}
			data[key] = encoded
			chrome.storage.local.set(data)
		} else {
			localStorage.setItem(key, encoded)
		}
	}
}

export default {
	getSeeds () {
		return storage.get('seeds', Array)
	},
	getUsername () {
		return storage.get('username')
	},
	getWhitelistUrl () {
		return storage.get('whitelistUrl')
	},
	addSeed (seed) {
		storage.get('seeds', Array).then(seeds => {
			if (!seeds) { seeds = [] }
			seeds.push(seed)
			storage.set('seeds', seeds)
		})
	},
	removeSeed (index) {
		storage.get('seeds', Array).then(seeds => {
			if (seeds && seeds.length >= index) {
				seeds.splice(index, 1)
				storage.set('seeds', seeds)
			}
		})
	},
	setUsername (username) {
		storage.set('username', username)
	},
	isAlertDismissed () {
		return storage.get('alertDismissed')
	},
	dismissAlert () {
		storage.set('alertDismissed', true)
	}
}
