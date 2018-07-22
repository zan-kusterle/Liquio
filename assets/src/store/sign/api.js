import axios from 'axios'
import storage from './storage'

export function makeRequest(method, url, params) {
	return new Promise((resolve, reject) => {
		Promise.all([storage.getWhitelistUrl(), storage.getUsername()]).then(values => {
			if (values.length > 0) {
				params.whitelist_url = values[0]
			}
			if (values.length > 1) {
				params.whitelist_usernames = values[1]
			}
					
			
			axios({ method, url, params }).then((response) => {
				resolve(response.data.data)
			}).catch(e => reject(e))
		})
	})
}
