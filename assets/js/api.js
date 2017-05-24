var axios = require('axios')
var _ = require('lodash')
var nacl = require('tweetnacl')
let utils = require('utils.js')

axios.defaults.headers.post['Content-Type'] = 'application/json';

export function getNode(key, opts, cb) {
    let url = '/api/nodes/' + encodeURIComponent(key)
    let params = {
        trust_metric_url: opts.trust_metric_url,
        trust_usernames: _.map(opts.keypairs, (k) => k.username).join(',')
    }
    axios.get(url, { params: params }).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function getReference(key, reference_key, cb) {
    let url = '/api/nodes/' + encodeURIComponent(key) + '/references/' + encodeURIComponent(reference_key)
    axios.get(url).then(function(response) {
        cb(response.data)
    }).catch(function(error) {})
}

export function getNodes(keys, referenceKeys, cb) {
    if (keys.length > 0 && (referenceKeys == null || referenceKeys.length > 0)) {
        var reqs = _.flatMap(keys, (key) => {
            if (referenceKeys == null) {
                return [axios.get('/api/nodes/' + encodeURIComponent(key))]
            } else {
                return _.map(referenceKeys, (referenceKey) => {
                    return axios.get('/api/nodes/' + encodeURIComponent(key) + '/references/' + encodeURIComponent(referenceKey))
                })
            }
        })
        axios.all(reqs).then(function(responses) {
            cb(_.map(responses, (r) => r.data.data))
        }).catch(function(error) {})
    }
}

export function search(query, cb) {
    let url = '/api/search/' + encodeURIComponent(query)
    axios.get(url).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function getIdentity(id, cb) {
    axios.get('/api/identities/' + id).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function setDelegation(to_identity_username, is_trusted, weight, topics, cb) {
    let url = '/api/identities/' + encodeURIComponent(to_identity_username)
    axios.put(url, { weight: weight, topics: topics, is_trusting: is_trusted }).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function unsetDelegation(to_identity_username, cb) {
    let url = '/api/identities/' + encodeURIComponent(to_identity_username) + '/delegations'
    axios.delete(url).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function setVote(keypair, key, unit, at_date, choice, cb) {
    let username = _.map(nacl.hash(keypair.publicKey), (byte) => {
        return String.fromCharCode(97 + byte % 26)
    }).join('')
    let message = Uint8Array.from([username, key, unit, choice].join(' '))
    let message_hash = nacl.hash(message)

    let url = '/api/nodes/' + encodeURIComponent(key)
    axios.put(url, {
        public_key: utils.encodeBase64(keypair.publicKey),
        signature: utils.encodeBase64(nacl.sign(message_hash, keypair.secretKey)),
        unit: unit,
        choice: choice,
        at_date: at_date.getFullYear() + '-' + (at_date.getMonth() + 1) + '-' + at_date.getDate()
    }).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function unsetVote(keypair, key, unit, at_date, cb) {
    let username = _.map(nacl.hash(keypair.publicKey), (byte) => {
        return String.fromCharCode(97 + byte % 26)
    }).join('')
    let message = Uint8Array.from([username, key, unit].join(' '))
    let message_hash = nacl.hash(message)
    let params = {
        public_key: utils.encodeBase64(keypair.publicKey),
        signature: utils.encodeBase64(nacl.sign(message_hash, keypair.secretKey)),
        unit: unit,
        at_date: at_date.getFullYear() + '-' + (at_date.getMonth() + 1) + '-' + at_date.getDate()
    }
    let url = '/api/nodes/' + encodeURIComponent(key)
    axios.delete(url, { params: params }).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function setReferenceVote(key, reference_key, relevance, cb) {
    let url = '/api/nodes/' + encodeURIComponent(key) + '/references/' + encodeURIComponent(reference_key)
    axios.put(url, { relevance: relevance }).then(function(response) {
        cb(response.data)
    }).catch(function(error) {})
}

export function unsetReferenceVote(key, reference_key, cb) {
    let url = '/api/nodes/' + encodeURIComponent(key) + '/references/' + encodeURIComponent(reference_key)
    axios.delete(url).then(function(response) {
        cb(response.data)
    }).catch(function(error) {})
}