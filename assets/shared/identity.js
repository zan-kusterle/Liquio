import nacl from 'tweetnacl'
import { encodeBase64 } from 'shared/utils'

export function wordsToSeed (words) {
    let bip39 = require('bip39')

    let filtered = words.split(' ').map(w => w.replace(/\s/g, '')).filter(w => w.length > 0)
    
    if(filtered.length !== 13)
        return null

    let seed = bip39.mnemonicToSeed(filtered.join(' '))
    return encodeBase64(seed)
}

export function keypairFromSeed (seed) {
    let seedBytes = new Uint8Array(atob(seed).split("").map((c) => c.charCodeAt(0)))
    if (seedBytes.length < 32)
        return null

    let keypair = nacl.sign.keyPair.fromSeed(seedBytes.slice(0, 32))
    keypair.username = usernameFromPublicKey(keypair.publicKey)
    return keypair
}

export function usernameFromPublicKey (key) {
    let hash = nacl.hash(key)
    return Array.from(hash.slice(0, 16)).map(byte => {
        return String.fromCharCode(97 + byte % 26)
    }).join('')
}