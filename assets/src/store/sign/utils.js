import nacl from 'tweetnacl'
import bip39 from 'bip39'

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

export function wordsToSeed (words) {
	let filtered = words.split(' ').map(w => w.replace(/\s/g, '')).filter(w => w.length > 0)

	if (filtered.length !== 13) { return null }

	let seed = bip39.mnemonicToSeed(filtered.join(' '))
	return encodeBase64(seed)
}

export function generateRandomWords () {
	let randomBytes = nacl.randomBytes(32)
	let mnemonic = bip39.entropyToMnemonic(randomBytes) // Long running operation
	return mnemonic.split(' ').slice(0, 13).join(' ')
}
