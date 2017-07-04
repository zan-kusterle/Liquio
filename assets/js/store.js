import Vuex from 'vuex'

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
                            path: words.slice(2).join(' ').split('/'),
                            reference_path: current_path
                        })
                    } else {
                        current_path.push(words.slice(2).join(' '))
                        votes.push({
                            choice: number,
                            unit: words[1].replace(':', ''),
                            path: current_path
                        })
                    }
                } else {
                    if (diff_indents === 0)
                        current_path = []
                    current_path.push(words.join(' '))
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

        let currentReferenceVotes = _.filter(referenceVotes, (rv) => rv.path.join('/') === currentPath.join('/'))
        _.each(currentReferenceVotes, (referenceVote) => {
            let referenceVoteText = '<b>' + referenceVote.relevance.toFixed(2) + ' @</b>' + referenceVote.reference_path.join('/')
            for (var i = 0; i < depth; i++)
                referenceVoteText = '\t' + referenceVoteText
            lines.push(referenceVoteText)
        })

        let availableVotes = _.filter(votes, (v) => v.path.length > depth)
        let byPrefix = _.groupBy(availableVotes, (v) => v.path[depth])
        _.each(_.sortBy(Object.keys(byPrefix), (k) => -byPrefix[k].length), (prefix) => {
            let prefixVotes = byPrefix[prefix]
            let vote = _.find(prefixVotes, (v) => v.path.length - 1 === depth && v.path[depth] === prefix)
            let segment = prefix
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
                let seedBytes = new Uint8Array(atob(seed).split("").map((c) => c.charCodeAt(0)))
                if (seedBytes.length >= 32) {
                    let keypair = nacl.sign.keyPair.fromSeed(seedBytes.slice(0, 32))

                    let hash = nacl.hash(keypair.publicKey)
                    keypair.username = _.map(hash.slice(0, 16), (byte) => {
                        return String.fromCharCode(97 + byte % 26)
                    }).join('')

                    return keypair
                }

                return null
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
        getPureNodeByKey: (state, getters) => (key) => {
            let node = _.find(state.nodes, (node) => {
                return node.key.toLowerCase() == key.toLowerCase()
            })
            return node ? JSON.parse(JSON.stringify(node)) : null
        },
        getNodeByKey: (state, getters) => (key) => {
            let node = getters.getPureNodeByKey(key)
            if (node) {
                node.references = _.filter(_.map(node.references, (n) => {
                    let referenceNode = getters.getPureNodeByKey(n.path.join('/'))

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
                    let referenceNode = getters.getPureNodeByKey(n.path.join('/'))

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

            let { _votes, referenceVotes } = parseVotes(`# Example Liquio import file

0.85 Lie-Fact: Most modern nations have universal healthcare paid by taxes

Earth
	0.2 Length(m): Sea level relative to 1900 A.D.
	0.8 False-True: Glaciers are retreating almost everywhere
	1.2 Temperature(C): Temperature rise relative to 1950 A.D.

Denmark
	0.32 Ratio: Median tax rate

The United States
	0.2 Ratio: Median tax rate

Global warming
	0.15 False-True: Not enough historical data is available to know the cause
	0.9 False-True: Is caused by human activity
		1.0 -> Earth/Sea level relative to 1900 A.D.
		1.0 -> Global warming/Not enough historical data is available to know the cause
		1.0 -> Earth/Temperature rise relative to 1950 A.D.

Bernie Sanders
	1.0 <- https://www.youtube.com/watch?v=kVnO3Ru2N7s
	Intro
		0.91 False-True: Bernie Sanders is an american politician on libertarian left of political spectrum.
	Policies
		0.98 False-True: Is consistently for single payer healthcare
		0.99 Lie-Fact: Takes no corporate money
			1.0 -> URL
	36 Duration(Year): Political experience
		1.0 <- https://www.youtube.com/watch?v=kVnO3Ru2N7s/0:10

Donald Trump
	1.0 False-True: Said the United States is the highest taxed nation in the world
		1.0 -> The United States/Median tax rate
		1.0 -> Denmark/Median tax rate
	1.0 False-True: Said that global warming is a Chinese hoax
		1.0 -> Global warming/Is caused by human activity
	1.0 False-True: Said he supports the Iraq War
		1.0 False-True: In interview with Howard Stern
			1.0 -> URL
	0.05 False-True: Consistently opposed the Iraq War
		1.0 -> Donald Trump/Said he supports the Iraq War

Artificial intelligence
	2045 Time(Year): General intelligence invention`)

            let votes = _.flatMap(identity.votes, (vote) => {
                return _.map(vote.results.by_units, (results_by_unit, unit) => {
                    return {
                        choice: results_by_unit.average,
                        unit: results_by_unit.value,
                        path: vote.path
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
                    _.each(identity.votes, (node) => commit('setNode', node))
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
        unsetDelegation({ commit, state, getters }, username) {
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