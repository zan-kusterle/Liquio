var axios = require('axios')
var _ = require('lodash')

axios.defaults.headers.post['Content-Type'] = 'application/json';

export function getNode(key, cb) {
    let url = '/api/nodes/' + encodeURIComponent(key)
    axios.get(url).then(function(response) {
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

export function login(email, cb) {
    axios.post('/api/login', { email: email }).then(function(response) {
        cb()
    }).catch(function(error) {})
}

export function logout(email, cb) {
    axios.delete('/api/login').then(function(response) {
        cb()
    }).catch(function(error) {})
}

export function register(token, username, name, cb) {
    axios.post('/api/identities', { token: token, identity: { username: username, name: name } }).then(function(response) {
        cb()
    }).catch(function(error) {})
}

export function setTrust(to_identity_username, is_trusted, cb) {
    let url = '/api/identities/' + encodeURIComponent(to_identity_username) + '/trusts'
    axios.post(url, { is_trusted: is_trusted }).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function unsetTrust(to_identity_username, cb) {
    let url = '/api/identities/' + encodeURIComponent(to_identity_username) + '/trusts'
    axios.delete(url).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function setDelegation(to_identity_username, weight, topics, cb) {
    let url = '/api/identities/' + encodeURIComponent(to_identity_username) + '/delegations'
    axios.post(url, { delegation: { weight: weight, topics: topics } }).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function unsetDelegation(to_identity_username, cb) {
    let url = '/api/identities/' + encodeURIComponent(to_identity_username) + '/delegations'
    axios.delete(url).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function setVote(key, unit, at_date, choice, cb) {
    let url = '/api/nodes/' + encodeURIComponent(key) + '/votes'
    axios.post(url, {
        unit: unit,
        choice: choice,
        at_date: at_date.getFullYear() + '-' + (at_date.getMonth() + 1) + '-' + at_date.getDate()
    }).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}
export function unsetVote(key, unit, at_date, cb) {
    let url = '/api/nodes/' + encodeURIComponent(key) + '/votes'
    axios.delete(url, { params: { unit: unit, at_date: at_date.toISOString().substring(0, 10) } }).then(function(response) {
        cb(response.data.data)
    }).catch(function(error) {})
}

export function setReferenceVote(key, reference_key, relevance, cb) {
    let url = '/api/nodes/' + encodeURIComponent(key) + '/references/' + encodeURIComponent(reference_key) + '/votes'
    axios.post(url, { relevance: relevance }).then(function(response) {
        cb(response.data)
    }).catch(function(error) {})
}
export function unsetReferenceVote(key, reference_key, cb) {
    let url = '/api/nodes/' + encodeURIComponent(key) + '/references/' + encodeURIComponent(reference_key) + '/votes'
    axios.delete(url).then(function(response) {
        cb(response.data)
    }).catch(function(error) {})
}