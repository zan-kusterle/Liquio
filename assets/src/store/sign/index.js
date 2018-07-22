/* globals PUBLIC_URL, DEFAULT_WHITELIST_URL, chrome */

import storage from './storage'
import bip39 from 'bip39'
import axios from 'axios'
import nacl from 'tweetnacl'

export function encodeBase64 (u8a) {
	return btoa(String.fromCharCode.apply(null, u8a))
}
  
export function decodeBase64 (s) {
	return Uint8Array.from(atob(s).split('').map(c => c.charCodeAt(0)))
}
  
export function stringToBytes (s) {
	let buffer = []
	let bufferIndex = 0
	for (var i = 0; i < s.length; i++) {
		let code = s.charCodeAt(i)
		if (code <= 255) {
			buffer[bufferIndex] = code
			bufferIndex += 1
		} else {
			buffer[bufferIndex] = code >> 8
			buffer[bufferIndex + 1] = code & 255
			bufferIndex += 2
		}
	}
	return Uint8Array.from(buffer)
}

let wordsToSeed = (words) => {
	let filtered = words.split(' ').map(w => w.replace(/\s/g, '')).filter(w => w.length > 0)

	if (filtered.length !== 13) { return null }

	let seed = bip39.mnemonicToSeed(filtered.join(' '))
	return encodeBase64(seed)
}

let keypairFromSeed = (seed) => {
	let seedBytes = new Uint8Array(atob(seed).split('').map((c) => c.charCodeAt(0)))
	if (seedBytes.length < 32) { return null }

	let keypair = nacl.sign.keyPair.fromSeed(seedBytes.slice(0, 32))
	keypair.username = usernameFromPublicKey(keypair.publicKey)
	return keypair
}

let usernameFromPublicKey = (key) => {
	let hash = nacl.hash(key)
	return Array.from(hash.slice(0, 16)).map(byte => {
		return String.fromCharCode(97 + byte % 26)
	}).join('')
}

let crossExtensionResponse = (data) => {
	chrome.runtime.sendMessage({
		name: 'cross-extension-respond',
		data: data
	})
}

let updateWhitelist = ({ whitelistUrl, username }) => {
	crossExtensionResponse({
		request_name: 'whitelist',
		url: whitelistUrl,
		username: username
	})
}

export default {
	namespaced: true,
	state: {
		seeds: [],
		whitelistUrl: DEFAULT_WHITELIST_URL,
		messages: [],
		randomWords: null,
		username: null,
		whitelistUsernames: [],
		userMessages: [],
		messagesToSign: [],
	},
	getters: {
		keys (state) {
			return state.seeds.map(keypairFromSeed).filter(k => k)
		},
		usernames (getters) {
			return getters.keys.map(k => k.username)
		},
		currentKey (state, getters) {
			return getters.keys.find(k => k.username === state.username)
		},
		newKey (state) {
			if (!state.randomWords)
				return null
			return keypairFromSeed(wordsToSeed(state.randomWords))
		},
		colorOnSpectrum () {
			let colorOnGradient = (colorA, colorB, ratio) => {
				let hex = (x) => {
					x = x.toString(16)
					return (x.length == 1) ? '0' + x : x
				}
    
				let r = Math.ceil(parseInt(colorB.substring(0, 2), 16) * ratio + parseInt(colorA.substring(0, 2), 16) * (1 - ratio))
				let g = Math.ceil(parseInt(colorB.substring(2, 4), 16) * ratio + parseInt(colorA.substring(2, 4), 16) * (1 - ratio))
				let b = Math.ceil(parseInt(colorB.substring(4, 6), 16) * ratio + parseInt(colorA.substring(4, 6), 16) * (1 - ratio))
    
				return hex(r) + hex(g) + hex(b)
			}
    
			return (ratio) => {
				let neutral = '33bae7',
					red = 'ff2b2b',
					yellow = 'f9e26e',
					green = '43e643'
    
				if (ratio === null)
					return neutral
				return ratio < 0.5 ? colorOnGradient(red, yellow, ratio * 2) : colorOnGradient(yellow, green, (ratio - 0.5) * 2)
			}
		}
	},
	mutations: {
		setItems (state, payload) {
			state.messages = payload
		},
		clearItems (state) {
			state.messages = []
		},
		setRandomWords (state, payload) {
			state.randomWords = payload
		},
		ADD_MESSAGE_TO_SIGN (state, message) {
			state.messagesToSign.push(message)
		},
		CLEAR_MESSAGES_TO_SIGN (state) {
			state.messagesToSign = []
		},
	},
	actions: {
		initialize ({ state }) {
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
				updateWhitelist(state)
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
					if (!v)
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
            
			let now = new Date() // This can be easily faked

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

			axios.all(promises).then(() => {
				commit('clearItems')

				crossExtensionResponse({
					request_name: 'sign'
				})

				chrome.runtime.sendMessage({ name: 'hide' })
				window.close()
			}).catch(error => {
				throw error
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
			let index = getters.keys.map(k => k.username).indexOf(username)
			if (index >= 0) {
				storage.removeSeed(state.seeds[index])
				state.seeds.splice(index, 1)

				state.username = index > 0 ? state.seeds[index - 1] : null
				storage.setUsername(state.username)
				updateWhitelist(state)
			}
		},
		switchToUsername ({ state }, username) {
			state.username = username
			storage.setUsername(username)
			updateWhitelist(state)
		},
		downloadIdentity ({ state, getters }) {
			var filename = `${getters.newKey.username}-login.txt`
			var text = state.randomWords

			var url = URL.createObjectURL(new Blob([text], { type: 'text/plain' }))
			chrome.downloads.download({
				url: url,
				filename: filename
			})
		},
		login ({ state, getters }, words) {
			let seed = wordsToSeed(words)
			if (seed) {
				storage.addSeed(seed)
				state.seeds.push(seed)

				state.username = getters.keys[getters.keys.length - 1].username
				storage.setUsername(state.username)
				updateWhitelist(state)
			}
		},
		createUser ({ commit }) {
			var randomBytes = nacl.randomBytes(32)
			var mnemonic = bip39.entropyToMnemonic(randomBytes) // Long running operation
			let words = mnemonic.split(' ').slice(0, 13).join(' ')
			commit('setRandomWords', words)
		},
		chooseUser ({ state }) {
			state.randomWords = null
		},
		setTrust ({ commit }, { username, ratio }) {
			commit('clearItems')
			commit('setItems', this.messages.concat([{
				name: 'trust',
				key: ['username'],
				username: username,
				ratio: ratio,
				keys: ['username', 'ratio']
			}]))
		}
	}
}