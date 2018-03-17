import { parseVotes } from 'shared/votes'
import { keypairFromSeed } from 'shared/identity'
import { allUnits } from 'shared/data'

let getTitle = (path) => {
    return path.join('/')
}

export default {
    parseVotes: () => (data) => {
        return parseVotes(data)
    },
    currentOpts: (state, getters) => {
        let availableSeeds = state.storageSeeds.split(';')

        let availableKeyPairs = availableSeeds.map((seed) => {
            return keypairFromSeed(seed)
        }).filter((k) => k)

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
        let identity = state.identities.find((identity) => {
            return identity.username.toLowerCase() == username.toLowerCase()
        })
        return identity ? JSON.parse(JSON.stringify(identity)) : null
    },
    getNodeByKey: (state, getters) => (key, depth = 1) => {
        let node = state.nodes.find((node) => {
            return node.key.toLowerCase() == key.toLowerCase()
        })
        node = node ? JSON.parse(JSON.stringify(node)) : null

        if (!node)
            return null
        
        if (depth > 0) {
            node.references = node.references.map((n) => {
                let referenceNode = getters.getNodeByKey(n.path.join('/'), depth - 1)

                var unit = allUnits[0]
                let units = referenceNode.results ? Object.values(referenceNode.results.by_units) : []
                let turnoutRatios = units.map(u => u.turnout_ratio)
                let bestUnit = units[turnoutRatios.indexOf(Math.max(turnoutRatios))]
                if (bestUnit)
                    unit = bestUnit

                referenceNode.default_unit = referenceNode.results && referenceNode.results.by_units[unit.key] || unit
                if (referenceNode) {
                    referenceNode.reference_result = n.reference_result
                }

                return referenceNode
            }).filter((x) => x)

            node.inverse_references = node.inverse_references.map((n) => {
                let referenceNode = getters.getNodeByKey(n.path.join('/'), depth - 1)

                var unit = allUnits[0]
                let units = referenceNode.results ? Object.values(referenceNode.results.by_units) : []
                let turnoutRatios = units.map(u => u.turnout_ratio)
                let bestUnit = units[turnoutRatios.indexOf(Math.max(turnoutRatios))]
                if (bestUnit)
                    unit = bestUnit

                referenceNode.default_unit = referenceNode.results && referenceNode.results.by_units[unit.key] || unit
                if (referenceNode) {
                    referenceNode.reference_result = n.reference_result
                }
                return referenceNode
            }).filter((x) => x)
        }

        var unit = allUnits[0]

        let units = node.results ? Object.values(node.results.by_units) : []
        let turnoutRatios = units.map(u => u.turnout_ratio)
        let bestUnit = units[turnoutRatios.indexOf(Math.max(turnoutRatios))]
        if (bestUnit) {
            unit = bestUnit
        }

        let currentNode = getters.currentNode
        if (node.key == currentNode.key && currentNode.unit) {
            let activeUnit = allUnits.find((u) => u.text == currentNode.unit)
            if (activeUnit) {
                unit = node.results && node.results.by_units[activeUnit.key] || activeUnit
            }
        }

        node.default_unit = unit

        return node
    },
    getNodesByKeys: (state, getters) => (paths) => paths.map((path) => getters.getNodeByKey(path)).filter((n) => n),
    getReference: (state, getters) => (key, reference_key) => {
        let reference = state.references.find((reference) => {
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
}