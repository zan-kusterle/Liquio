import axios from 'axios'
import storage from './storage'

export function makeRequest(method, url, params) {
	let whitelistUrl = storage.getWhitelistUrl()
	let whitelistUsername = storage.getUsername()

	if (whitelistUrl) {
		params.whitelist_url = whitelistUrl
	}
	if (whitelistUsername) {
		params.whitelist_usernames = whitelistUsername
	}

	return new Promise((resolve, reject) => {
		axios({ method, url, params }).then((response) => {
			resolve(response.data.data)
		}).catch(e => reject(e))
	})
}
