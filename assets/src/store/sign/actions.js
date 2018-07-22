/* globals PUBLIC_URL, DEFAULT_WHITELIST_URL */

import axios from 'axios'
import nacl from 'tweetnacl'
import storage from './storage'
import { wordsToSeed, generateRandomWords, stringToBytes, encodeBase64 } from './utils'

export default {
	initialize ({ state, commit }) {
		storage.getSeeds().then(seeds => {
			if (seeds && seeds.length > 0) {
				seeds.forEach(seed => {
					if (seed.length > 0) {
						state.seeds.push(seed)
					}
				})
			}
		})
        
		storage.getUsername().then(username => {
			state.username = username
		})


		window.addEventListener('liquio-sign', (e) => {
			commit('setItems', e.detail)
			state.signDialogVisible = state.messages.length > 0
		})
	},
	/*
    for each message the user wants to sign:
        make a POST request:
            public_key field is base 64 encoded public key
            signature is the message signature using current private key
            message is a slightly extended message with:
                name field prepended to key field
                datetime field set to current time
    wait for all requests to finish and close the dialog
    */
	signItems ({ state, getters, commit }) {
		let keypair = getters.currentKey
		if (!keypair)
			return

		let getSignature = (message, secretKey) => {
			let keys = Object.keys(message).sort()
			let serializeValue = (v) => {
				if (!v && v !== 0)
					return '/'
				if (Array.isArray(v)) {
					return v.join(' ')
				}
				return v.toString().replace(/[\n\r]/g, '')
			}
			let serialized = keys.map(k => k + ': ' + serializeValue(message[k])).join('\n')

			let messageHash = nacl.hash(stringToBytes(serialized))
			return nacl.sign.detached(messageHash, secretKey)
		}
        
		let now = new Date() // This can easily be faked

		let promises = state.messages.map(message => {
			let raw_message = {
				...message,
				key: [message.name].concat(message.key),
				datetime: now.toISOString()
			}
            
			let params = {
				public_key: encodeBase64(keypair.publicKey),
				signature: encodeBase64(getSignature(raw_message, keypair.secretKey)),
				message: raw_message
			}
			return axios.post(PUBLIC_URL + '/messages', params)
		})

		return new Promise((resolve, reject) => {
			axios.all(promises).then(() => {
				commit('setItems', [])
				state.signDialogVisible = false
				let event = new CustomEvent('liquio-sign-done')
				window.dispatchEvent(event)
				resolve()
			}).catch(error => {
				throw error
			})
		})
	},
	loadWhitelist ({ state }) {
		storage.getWhitelistUrl().then(whitelistUrl => {
			axios.get(PUBLIC_URL + '/whitelists/' + encodeURIComponent(whitelistUrl || DEFAULT_WHITELIST_URL)).then(response => {
				state.whitelistUsernames = response.data.data.usernames
			})
		})
	},
	loadMessages ({ state }, username) {
		axios.get(PUBLIC_URL + '/messages/?usernames=' + encodeURIComponent(username)).then(response => {
			state.userMessages = response.data.data
		})
	},
	removeUsername ({ state, getters }, username) {
		let index = getters.usernames.indexOf(username)
		if (index >= 0) {
			storage.removeSeed(state.seeds[index])
			state.seeds.splice(index, 1)
			state.username = getters.usernames.length > 0 ? getters.usernames[index - 1] : null
			storage.setUsername(state.username)
		}
	},
	switchToUsername ({ state }, username) {
		state.username = username
		storage.setUsername(username)
	},
	downloadIdentity ({ state, getters }) {
		var filename = `${getters.newKey.username}-login.txt`
		var text = state.randomWords

		var file = URL.createObjectURL(new Blob([text], { type: 'text/plain' }))
		var a = document.createElement('a')
		a.href = file
		a.download = filename
		a.style.display = 'none'
		document.body.appendChild(a)
		a.click()
	},
	login ({ state, getters }, words) {
		let seed = wordsToSeed(words)
		if (seed) {
			storage.addSeed(seed)
			state.seeds.push(seed)

			state.username = getters.keys[getters.keys.length - 1].username
			storage.setUsername(state.username)
		}
	},
	createUser ({ commit }) {
		commit('setRandomWords', generateRandomWords())
	},
	chooseUser ({ state }) {
		state.randomWords = null
	},
	setTrust ({ state, commit }, { username, ratio }) {
		commit('setItems', this.messages.concat([{
			name: 'trust',
			key: ['username'],
			username: username,
			ratio: ratio,
		}]))
		state.signDialogVisible = true
	}
}
