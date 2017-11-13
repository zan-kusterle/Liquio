import Vuex from 'vuex'
import { keypairFromSeed } from 'identity'

let Api = require('api.js')

let getTitle = (path) => {
    let title = path.join('/')
    if (!(title.startsWith('http:') || title.startsWith('https:')))
        title = title.replace(/-/g, ' ')
    return title
}

let parseVotes = (text) => {
    let lines = text.split('\n')
    var current_path = []
    var votes = []
    var referenceVotes = []
    _.each(lines, (line) => {
        line = line.replace(/\s\s\s\s/g, '\t')
        let num_indents = 0
        while (line[num_indents] == '\t') {
            num_indents++
        }
        let rest = line.substring(num_indents).trim()

        if (rest.length > 0) {
            if (line[0] !== '#') {
                let diff_indents = current_path.length - num_indents - 1
                if (diff_indents >= 0)
                    current_path = current_path.slice(0, current_path.length - diff_indents - 1)

                let words = rest.split(' ')
                let number = parseFloat(words[0])
                if (number) {
                    if (words[1] == '->') {
                        referenceVotes.push({
                            relevance: number,
                            path: current_path,
                            reference_path: words.slice(2).join(' ').split('/')
                        })
                    } else if (words[1] == '<-') {
                        referenceVotes.push({
                            relevance: number,
                            path: words.slice(2).join('-').split('/'),
                            reference_path: current_path
                        })
                    } else {
                        current_path.push(words.slice(2).join('-'))
                        votes.push({
                            choice: number,
                            unit: words[1].replace(':', ''),
                            path: current_path
                        })
                    }
                } else {
                    if (diff_indents === 0)
                        current_path = []
                    current_path.push(words.join('-'))
                }
            }
        }
    })

    return { votes, referenceVotes }
}

let formatVotes = (votes, referenceVotes) => {
    var lines = []

    let recursive = (votes, currentPath) => {
        let depth = currentPath.length

        let currentReferenceVotes = _.filter(referenceVotes, (rv) => rv.path.join('/').toLowerCase() === currentPath.join('/').toLowerCase())
        _.each(currentReferenceVotes, (referenceVote) => {
            let referenceVoteText = '<b>' + referenceVote.relevance.toFixed(2) + ' -> </b>' + referenceVote.reference_path.join('/').replace(/-/g, ' ')
            for (var i = 0; i < depth; i++)
                referenceVoteText = '\t' + referenceVoteText
            lines.push(referenceVoteText)
        })

        let availableVotes = _.filter(votes, (v) => v.path.length > depth)
        let byPrefix = _.groupBy(availableVotes, (v) => v.path[depth])
        _.each(_.sortBy(Object.keys(byPrefix), (k) => -byPrefix[k].length), (prefix) => {
            let prefixVotes = byPrefix[prefix]
            let vote = _.find(prefixVotes, (v) => v.path.length - 1 === depth && v.path[depth] === prefix)
            let segment = prefix.replace(/-/g, ' ')
            if (vote)
                segment = '<b>' + vote.choice + ' ' + vote.unit + ': </b>' + segment
            for (var i = 0; i < depth; i++)
                segment = '\t' + segment

            lines.push(segment)
            recursive(prefixVotes, currentPath.slice().concat([prefix]))
        })
    }
    recursive(votes, [])

    return lines.join('\n')
}

window.parseVotes = parseVotes

export default new Vuex.Store({
    plugins: [],
    state: {
        nodes: [],
        references: [],
        identities: [],
        storageSeeds: localStorage.seeds || '',
        currentKeyPairIndex: localStorage.currentIndex ? parseInt(localStorage.currentIndex) : 0,
        trustMetricURL: localStorage.trustMetricURL || (process.env.NODE_ENV === 'production' ? 'https://trust-metric.liqu.io' : 'http://127.0.0.1:8080/dev_trust_metric.html'),
        units: _.map([
            { key: 'true', text: 'True-False', value: 'true', type: 'spectrum' },
            { key: 'count', text: 'Count', value: 'count', type: 'quantity' },
            { key: 'year', text: 'Year(AD)', value: 'year', type: 'quantity' },
            { key: 'fact', text: 'Fact-Lie', value: 'fact', type: 'spectrum' },
            { key: 'reliable', text: 'Reliable-Unreliable', value: 'reliable', type: 'spectrum' },
            { key: 'temperature', text: 'Temperature(°C)', value: 'temperature', type: 'quantity' },
            { key: 'usd', text: 'Money(USD)', value: 'usd', type: 'quantity' },
            { key: 'euro', text: 'Money(EUR)', value: 'eur', type: 'quantity' },
            { key: 'length', text: 'Length(m)', value: 'length', type: 'quantity' },
            { key: 'approve', text: 'Approve-Disapprove', value: 'approve', type: 'spectrum' },
            { key: 'agree', text: 'Agree-Disagree', value: 'agree', type: 'spectrum' }
        ], (u) => {
            u.value = u.text.replace(' (', '(')
            return u
        })
    },
    getters: {
        parseVotes: () => (data) => {
            return parseVotes(data)
        },
        currentOpts: (state, getters) => {
            var nacl = require('tweetnacl')

            let availableSeeds = state.storageSeeds.split(';')

            let availableKeyPairs = _.filter(_.map(availableSeeds, (seed) => {
                return keypairFromSeed(seed)
            }), (k) => k)

            return {
                keypairs: availableKeyPairs,
                keypair: state.currentKeyPairIndex < availableKeyPairs.length ? availableKeyPairs[state.currentKeyPairIndex] : null,
                trustMetricURL: state.trustMetricURL
            }
        },
        currentNode: (state) => {
            if (state.route.params.query) {
                let path = ['search', state.route.params.query]
                return {
                    path: path,
                    unit: null,
                    key: path.join('/'),
                    title: 'Results for ' + path[1]
                }
            }

            let path = (state.route.params.key || '').split('/')
            return {
                path: path,
                unit: state.route.params.unit || null,
                key: path.join('/'),
                title: getTitle(path)
            }
        },
        currentReference: (state) => {
            let path = (state.route.params.referenceKey || '').split('/')

            return {
                path: path,
                key: path.join('/'),
                title: getTitle(path)
            }
        },
        searchQuery: (state) => state.route.params.query,
        searchResults: (state, getters) => (query) => {
            let node = getters.getNodeByKey('search/' + query)
            if (node)
                node.title = 'Results for ' + query
            return node
        },
        getIdentityByUsername: (state, getters) => (username) => {
            let identity = _.find(state.identities, (identity) => {
                return identity.username.toLowerCase() == username.toLowerCase()
            })
            return identity ? JSON.parse(JSON.stringify(identity)) : null
        },
        getNodeByKey: (state, getters) => (key, depth = 1) => {
            let node = _.find(state.nodes, (node) => {
                return node.key.toLowerCase() == key.toLowerCase()
            })
            node = node ? JSON.parse(JSON.stringify(node)) : null

            if (!node)
                return null
            
            if (depth > 0) {
                node.references = _.filter(_.map(node.references, (n) => {
                    let referenceNode = getters.getNodeByKey(n.path.join('/'), depth - 1)

                    var unit = state.units[0]
                    let units = referenceNode.results ? Object.values(referenceNode.results.by_units) : []
                    let bestUnit = _.maxBy(units, (u) => u.turnout_ratio)
                    if (bestUnit)
                        unit = bestUnit

                    referenceNode.default_unit = referenceNode.results && referenceNode.results.by_units[unit.key] || unit
                    if (referenceNode) {
                        referenceNode.reference_result = n.reference_result
                    }

                    return referenceNode
                }), (x) => x)

                node.inverse_references = _.filter(_.map(node.inverse_references, (n) => {
                    let referenceNode = getters.getNodeByKey(n.path.join('/'), depth - 1)

                    var unit = state.units[0]
                    let units = referenceNode.results ? Object.values(referenceNode.results.by_units) : []
                    let bestUnit = _.maxBy(units, (u) => u.turnout_ratio)
                    if (bestUnit)
                        unit = bestUnit

                    referenceNode.default_unit = referenceNode.results && referenceNode.results.by_units[unit.key] || unit
                    if (referenceNode) {
                        referenceNode.reference_result = n.reference_result
                    }
                    return referenceNode
                }), (x) => x)
            }

            var unit = state.units[0]

            let units = node.results ? Object.values(node.results.by_units) : []
            let bestUnit = _.maxBy(units, (u) => u.turnout_ratio)
            if (bestUnit) {
                unit = bestUnit
            }

            let currentNode = getters.currentNode
            if (node.key == currentNode.key && currentNode.unit) {
                let activeUnit = _.find(state.units, (u) => u.text == currentNode.unit)
                if (activeUnit) {
                    unit = node.results && node.results.by_units[activeUnit.key] || activeUnit
                }
            }

            node.default_unit = unit

            if (node.path.length > 0 && (node.path[0].startsWith('http:') || node.path[0].startsWith('https:'))) {
                node.path[0] = node.path[0].replace(':', '://')
            }

            return node
        },
        getNodesByKeys: (state, getters) => (paths) => _.filter(_.map(paths, (path) => getters.getNodeByKey(path)), (n) => n),
        getReference: (state, getters) => (key, reference_key) => {
            let reference = _.find(state.references, (reference) => {
                return reference.key.toLowerCase() == key.toLowerCase() && reference.reference_key.toLowerCase() == reference_key.toLowerCase()
            })
            if (!reference)
                return null

            let results = JSON.parse(JSON.stringify(reference.results)) || {}
            results.type = 'spectrum'
            results.positive = 'Relevant'
            results.negative = 'Irrelevant'

            return {
                results: results,
                node: getters.getNodeByKey(key),
                referencing_node: getters.getNodeByKey(reference_key)
            }
        }
    },
    mutations: {
        setIdentity(state, identity) {
            let existingIndex = _.findIndex(state.identities, (i) => i.username == identity.username)

            let votes = _.flatMap(identity.votes, (vote) => {
                return _.map(vote.results.by_units, (results_by_unit, unit) => {
                    return {
                        choice: results_by_unit.average,
                        unit: results_by_unit.value,
                        path: vote.path
                    }
                })
            })
            let referenceVotes = _.flatMap(identity.votes, (voteNode) => {
                return _.map(voteNode.references, (referenceVote) => {
                    return {
                        relevance: referenceVote.reference_results && referenceVote.reference_results.average,
                        path: voteNode.path,
                        reference_path: referenceVote.path
                    }
                })
            })
            identity.votes_text = formatVotes(votes, referenceVotes)

            identity.websites = Object.keys(_.pickBy(identity.identifications, (v, k) =>
                (v === 'true' && (k.startsWith('http://') || k.startsWith('https://')))))

            if (existingIndex >= 0)
                state.identities.splice(existingIndex, 1)
            state.identities.push(identity)
        },
        setNode(state, node) {
            node.key = node.path.join('/')
            node.title = getTitle(node.path)

            let existingIndex = _.findIndex(state.nodes, (n) => n.key == node.key)
            let existing = existingIndex >= 0 ? state.nodes[existingIndex] : null

            if (node.references == null) {
                node.references = existing ? existing.references : []
            } else {
                node.references = _.map(node.references, (n) => {
                    return {
                        path: n.path,
                        reference_result: n.reference_result
                    }
                })
            }

            if (node.inverse_references == null) {
                node.inverse_references = existing ? existing.inverse_references : []
            } else {
                node.inverse_references = _.map(node.inverse_references, (n) => {
                    return {
                        path: n.path,
                        reference_result: n.reference_result
                    }
                })
            }

            if (existingIndex >= 0)
                state.nodes.splice(existingIndex, 1)
            state.nodes.push(node)
        },
        setReference(state, reference) {
            reference.key = reference.node.path.join('/')
            reference.reference_key = reference.referencing_node.path.join('/')

            let existingIndex = _.findIndex(state.references, (r) => r.key == reference.key && r.reference_key == reference.reference_key)

            if (existingIndex >= 0)
                state.references.splice(existingIndex, 1)
            state.references.push(reference)
        }
    },
    actions: {
        finishRegistration({ commit, state }, { token, username, name }) {
            return new Promise((resolve, reject) => {
                Api.register(token, username, name, function(identity) {
                    commit('setIdentity', identity)
                    resolve(identity)
                })
            })
        },
        fetchIdentity({ commit, state }, username) {
            return new Promise((resolve, reject) => {
                Api.getIdentity(username, (identity) => {
                    commit('setIdentity', identity)
                    resolve(identity)
                })
            })
        },
        fetchNode({ commit, state, getters }, key) {
            return new Promise((resolve, reject) => {
                Api.getNode(key, getters.currentOpts, (node) => {
                    _.each(node.references, (reference) => commit('setNode', reference))
                    _.each(node.inverse_references, (reference) => commit('setNode', reference))
                    commit('setNode', node)
                    resolve(node)
                })
            })
        },
        search({ commit, state }, query) {
            return new Promise((resolve, reject) => {
                Api.search(query, (node) => {
                    node.path = ['Search', query]
                    _.each(node.references, (reference) => commit('setNode', reference))
                    commit('setNode', node)
                    resolve(node)
                })
            })
        },
        fetchReference({ commit, state, getters }, { key, referenceKey }) {
            return new Promise((resolve, reject) => {
                Api.getReference(key, referenceKey, getters.currentOpts, (reference) => {
                    commit('setNode', reference.node)
                    commit('setNode', reference.referencing_node)
                    commit('setReference', reference)
                    resolve(reference)
                })
            })
        },
        setVote({ commit, state, getters }, { key, unit, at_date, choice }) {
            return new Promise((resolve, reject) => {
                Api.setVote(getters.currentOpts, key, unit, at_date, choice, function(node) {
                    commit('setNode', node)
                    resolve(node)
                })
            })
        },
        unsetVote({ commit, state, getters }, { key, unit, at_date }) {
            return new Promise((resolve, reject) => {
                Api.unsetVote(getters.currentOpts, key, unit, at_date, function(node) {
                    commit('setNode', node)
                    resolve(node)
                })
            })
        },
        setReferenceVote({ commit, state, getters }, { reference, relevance }) {
            return new Promise((resolve, reject) => {
                Api.setReferenceVote(getters.currentOpts, reference.node.key, reference.referencing_node.key, relevance, function(reference) {
                    commit('setReference', reference)
                    resolve(reference)
                })
            })
        },
        unsetReferenceVote({ commit, state, getters }, reference) {
            return new Promise((resolve, reject) => {
                Api.unsetReferenceVote(getters.currentOpts, reference.node.key, reference.referencing_node.key, function(reference) {
                    commit('setReference', reference)
                    resolve(reference)
                })
            })
        },
        setDelegation({ commit, state, getters }, { username, is_trusted, weight, topics }) {
            return new Promise((resolve, reject) => {
                Api.setDelegation(getters.currentOpts, username, is_trusted, weight, topics, function(identity) {
                    commit('setIdentity', identity)
                    resolve(identity)
                })
            })
        },
        unsetDelegation({ commit, state, getters }, { username }) {
            return new Promise((resolve, reject) => {
                Api.unsetDelegation(getters.currentOpts, username, function(identity) {
                    commit('setIdentity', identity)
                    resolve(identity)
                })
            })
        },
        setIdentification({ commit, state, getters }, { key, name }) {
            return new Promise((resolve, reject) => {
                Api.setIdentification(getters.currentOpts, key, name, function(identity) {
                    commit('setIdentity', identity)
                    resolve(identity)
                })
            })
        }
    }
})