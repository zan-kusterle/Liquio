var axios = require('axios')
var _ = require('lodash')
var nacl = require('tweetnacl')
let utils = require('utils.js')

axios.defaults.headers.post['Content-Type'] = 'application/json'

function getCommonParams(opts) {
    return {
        trust_metric_url: opts.trust_metric_url,
        trust_usernames: _.map(opts.keypairs, (k) => k.username).join(',')
    }
}

export function getNode(key, opts, cb) {
    let params = getCommonParams(opts)
    axios.get('/api/nodes/' + encodeURIComponent(key), { params: params }).then(function(response) {
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
    topics = _.map(topics, (t) => t.toLowerCase())
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

export function setVote(opts, key, unit, at_date, choice, cb) {
    let message = ['setVote', key, unit, choice.toFixed(5)].join(' ')
    let message_hash = nacl.hash(utils.stringToBytes(message))
    let signature = nacl.sign.detached(message_hash, opts.keypair.secretKey)

    let params = Object.assign(getCommonParams(opts), {
        public_key: utils.encodeBase64(opts.keypair.publicKey),
        signature: utils.encodeBase64(signature),
        unit: unit,
        choice: choice,
        at_date: at_date.getFullYear() + '-' + (at_date.getMonth() + 1) + '-' + at_date.getDate()
    })
    axios.put('/api/nodes/' + encodeURIComponent(key), params).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
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

export function setReferenceVote(opts, key, reference_key, relevance, cb) {
    let message = ['setReferenceVote', key, reference_key, relevance.toFixed(5)].join(' ')
    let message_hash = nacl.hash(utils.stringToBytes(message))
    let signature = nacl.sign.detached(message_hash, opts.keypair.secretKey)

    let params = Object.assign(getCommonParams(opts), {
        public_key: utils.encodeBase64(opts.keypair.publicKey),
        signature: utils.encodeBase64(signature),
        relevance: relevance
    })
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