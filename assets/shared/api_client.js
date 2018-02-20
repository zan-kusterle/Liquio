import nacl from 'tweetnacl'
import axios from 'axios'
import * as utils from 'shared/utils'

axios.defaults.headers.post['Content-Type'] = 'application/json'

let getCommonParams = (opts) => {
    return {
        depth: opts && opts.depth ? opts.depth : 1,
        trust_usernames: opts && opts.trust_usernames ? opts.trust_usernames : []
    }
}

export function sign(secretKey, message) {
    let hash = nacl.hash(utils.stringToBytes(message))
    let signature = nacl.sign.detached(hash, secretKey)
    return signature
}

export function getNode(key, opts, cb) {
    let params = getCommonParams(opts)
    axios.get(LIQUIO_URL + '/api/nodes/' + encodeURIComponent(key), { params: params }).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function getReference(key, reference_key, opts, cb) {
    let params = getCommonParams(opts)
    axios.get('/api/nodes/' + encodeURIComponent(key) + '/references/' + encodeURIComponent(reference_key), { params: params }).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function search(query, cb) {
    let url = '/api/search/' + encodeURIComponent(query)
    axios.get(url).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function getIdentity(username, cb) {
    axios.get('/api/identities/' + username).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function setIdentification(opts, key, value, cb) {
    let message = ['setIdentification', key, value].join(' ').trim()
    let message_hash = nacl.hash(utils.stringToBytes(message))
    let signature = nacl.sign.detached(message_hash, opts.keypair.secretKey)

    let params = {
        public_key: utils.encodeBase64(opts.keypair.publicKey),
        signature: utils.encodeBase64(signature),
        key: key
    }
    if (value)
        params['value'] = value

    axios.post('/api/identities/identifications', params).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function setDelegation(opts, to_identity_username, is_trusted, weight, topics, cb) {
    topics = topics.map((t) => t.toLowerCase())
    let message = ['setDelegation', to_identity_username, is_trusted || false, weight.toFixed(5), topics ? topics.join(',') : ''].join(' ').trim()
    let message_hash = nacl.hash(utils.stringToBytes(message))
    let signature = nacl.sign.detached(message_hash, opts.keypair.secretKey)

    let params = {
        public_key: utils.encodeBase64(opts.keypair.publicKey),
        signature: utils.encodeBase64(signature),
        weight: weight,
        topics: topics,
        is_trusting: is_trusted
    }
    axios.put('/api/identities/' + encodeURIComponent(to_identity_username), params).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function unsetDelegation(opts, to_identity_username, cb) {
    let message = ['unsetDelegation', to_identity_username].join(' ')
    let message_hash = nacl.hash(utils.stringToBytes(message))
    let signature = nacl.sign.detached(message_hash, opts.keypair.secretKey)

    let params = {
        public_key: utils.encodeBase64(opts.keypair.publicKey),
        signature: utils.encodeBase64(signature)
    }
    axios.delete('/api/identities/' + encodeURIComponent(to_identity_username), { params: params }).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function setVote(publicKey, signature, key, unit, at_date, choice, cb) {
    let params = {
        public_key: utils.encodeBase64(publicKey),
        signature: utils.encodeBase64(signature),
        unit: unit,
        choice: choice,
        at_date: at_date.toISOString().split('T')[0]
    }
    axios.put('/api/nodes/' + encodeURIComponent(key), params).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function getVoteMessage(key, unit, at_date, choice) {
    return ['setVote', key, unit, choice.toFixed(5)].join(' ')
}

export function unsetVote(opts, key, unit, at_date, cb) {
    let message = ['unsetVote', key, unit].join(' ')
    let message_hash = nacl.hash(utils.stringToBytes(message))
    let signature = nacl.sign.detached(message_hash, opts.keypair.secretKey)

    let params = Object.assign(getCommonParams(opts), {
        public_key: utils.encodeBase64(opts.keypair.publicKey),
        signature: utils.encodeBase64(signature),
        unit: unit,
        at_date: at_date.getFullYear() + '-' + (at_date.getMonth() + 1) + '-' + at_date.getDate(),
    })
    axios.delete('/api/nodes/' + encodeURIComponent(key), { params: params }).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function getReferenceVoteMessage(key, reference_key, relevance) {
    return ['setReferenceVote', key, reference_key, relevance.toFixed(5)].join(' ')
}

export function setReferenceVote(publicKey, signature, key, reference_key, relevance, cb) {
    let params = {
        public_key: utils.encodeBase64(publicKey),
        signature: utils.encodeBase64(signature),
        relevance: relevance
    }
    axios.put('/api/nodes/' + encodeURIComponent(key) + '/references/' + encodeURIComponent(reference_key), params).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function unsetReferenceVote(opts, key, reference_key, cb) {
    let message = ['unsetReferenceVote', key, reference_key].join(' ')
    let message_hash = nacl.hash(utils.stringToBytes(message))
    let signature = nacl.sign.detached(message_hash, opts.keypair.secretKey)

    let params = Object.assign(getCommonParams(opts), {
        public_key: utils.encodeBase64(opts.keypair.publicKey),
        signature: utils.encodeBase64(signature)
    })
    axios.delete('/api/nodes/' + encodeURIComponent(key) + '/references/' + encodeURIComponent(reference_key), { params: params }).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}


let transforms = {
    node (data) {
        let red = 'ff2b2b',
            yellow = 'f9e26e',
            green = '43e643'
        let color = this.rating < 0.5 ? colorOnGradient(yellow, red, this.rating * 2) : colorOnGradient(green, yellow, (this.rating - 0.5) * 2)
        
        return {
            path: data.path,
            isLink: data.is_link,
            title: data.title,
            results: data.results,
            references: data.references,
            inverseReferences: data.inverse_references,
            calculationOpts: data.calculation_opts,
            color: color
        }
    }
}
export default {
    node: {
        get (key) {
            let params = getCommonParams(opts)
            return new Promise({ resolve, reject }, function () {
                axios.get(LIQUIO_URL + '/api/nodes/' + encodeURIComponent(key), { params: params }).then(function(response) {
                    resolve(transforms.node(response.data.data))
                }).catch(reject)
            })
        },
        set (publicKey, signature, data) {
            let params = {
                public_key: utils.encodeBase64(publicKey),
                signature: utils.encodeBase64(signature),
                unit: unit,
                choice: choice,
                at_date: at_date.getFullYear() + '-' + (at_date.getMonth() + 1) + '-' + at_date.getDate()
            }

            return new Promise({ resolve, reject }, function () {
                axios.put('/api/nodes/' + encodeURIComponent(key), params).then(function(response) {
                    cb(transforms.node(response.data.data))
                }).catch(function(error) {})
            })
        },
        message({ key, unit, choice}) {
            return ['setVote', key, unit, choice.toFixed(5)].join(' ')
        }
    }
}