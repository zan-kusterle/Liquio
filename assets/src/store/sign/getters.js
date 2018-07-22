import nacl from 'tweetnacl'
import { wordsToSeed } from './utils'

let keypairFromSeed = (seed) => {
	let seedBytes = new Uint8Array(atob(seed).split('').map((c) => c.charCodeAt(0)))
	if (seedBytes.length < 32) { return null }

	let keypair = nacl.sign.keyPair.fromSeed(seedBytes.slice(0, 32))

	let hash = nacl.hash(keypair.publicKey)
	keypair.username = Array.from(hash.slice(0, 16)).map(byte => {
		return String.fromCharCode(97 + byte % 26)
	}).join('')

	return keypair
}

export default {
	keys (state) {
		return state.seeds.map(keypairFromSeed).filter(k => k)
	},
	usernames (_, getters) {
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
}
