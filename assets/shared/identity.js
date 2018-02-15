import nacl from 'tweetnacl'
import { encodeBase64 } from 'shared/utils'
import _ from 'lodash'

export function wordsToSeed (words) {
    let bip39 = require('bip39')

    let filtered = _.filter(_.map(words.split(' '), (w) => w.replace(/\s/g, '')), (w) => w.length > 0)
    
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
    return _.map(hash.slice(0, 16), (byte) => {
        return String.fromCharCode(97 + byte % 26)
    }).join('')
}