import Vuex from 'vuex'

let Api = require('api.js')
let utils = require('utils.js')

let getTitle = (path) => {
	let title = path.join('/')
	if(!(title.startsWith('http://') || title.startsWith('https://')))
		title = title.replace(/-/g, ' ')
	return title
}

export default new Vuex.Store({
	plugins: [],
	state: {
		user: null,
		nodes: [],
		references: [],
		identities: [],
		calculation_opts: {},
		units: _.map([
			{key: 'true', text: 'True-False', value: 'true', type: 'spectrum'},
			{key: 'count', text: 'Count', value: 'count', type: 'quantity'},
			{key: 'year', text: 'Year', value: 'year', type: 'quantity'},
			{key: 'fact', text: 'Fact-Lie', value: 'fact', type: 'spectrum'},
			{key: 'reliable', text: 'Reliable-Unreliable', value: 'reliable', type: 'spectrum'},
			{key: 'temperature', text: 'Temperature (°C)', value: 'temperature', type: 'quantity'},
			{key: 'usdollars', text: 'US Dollars (USD)', value: 'usd', type: 'quantity'},
			{key: 'euro', text: 'Euro (EUR)', value: 'eur', type: 'quantity'},
			{key: 'length', text: 'Length (m)', value: 'length', type: 'quantity'},
			{key: 'approve', text: 'Approve-Disapprove', value: 'approve', type: 'spectrum'},
			{key: 'agree', text: 'Agree-Disagree', value: 'agree', type: 'spectrum'}
		], (u) => {
			u.value = u.text.replace(' (', '(')
			return u
		})
	},
	getters: {
		hasNode: (state) => (key) => {
			return _.find(state.nodes, (node) => {
				return node.group_key == utils.normalizeKey(key)
			}) != null
		},
		currentNode: (state) => {
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
			let node = getters.getNodeByKey(['Search', query])
			node.title = 'Results for ' + query
			return node
		},
		getPureNodeByKey: (state, getters) => (key) => {
			let node = _.find(state.nodes, (node) => {
				return node.group_key == utils.normalizeKey(key)
			})
			return node ? JSON.parse(JSON.stringify(node)) : null
		},
		getNodeByKey: (state, getters) => (path) => {
			let node = getters.getPureNodeByKey(path)
			if(node) {
				node.references = _.filter(_.map(node.references, (n) => {
					let referenceNode = getters.getPureNodeByKey(n.path)
					referenceNode.default_unit = referenceNode.units && referenceNode.units['true']
					if(referenceNode) {
						referenceNode.reference_result = n.reference_result
					}
					return referenceNode
				}), (x) => x)

				node.inverse_references = _.filter(_.map(node.inverse_references, (n) => {
					let referenceNode = getters.getPureNodeByKey(n.path)
					referenceNode.default_unit = referenceNode.units && referenceNode.units['true']
					if(referenceNode) {
						referenceNode.reference_result = n.reference_result
					}
					return referenceNode
				}), (x) => x)

				let unit = state.units[0]
				let bestResults = _.maxBy(node.units, (u) => u.turnout_ratio)
				let currentNode = getters.currentNode
				if(node.key == currentNode.key && currentNode.unit) {
					let activeUnit = _.find(state.units, (u) => u.text == currentNode.unit)
					if(activeUnit)
						unit = activeUnit
				} else if(bestResults) {
					console.log(bestResults)
				}
				
				node.default_unit = node.units[unit.key] || unit
				node.own_default_unit = node.own_results && node.own_results[unit.key]
			}
			return node
		},
		getNodesByKeys: (state, getters) => (paths) => _.filter(_.map(paths, (path) => getters.getNodeByKey(path)), (n) => n),
		getReference: (state, getters) => (key, reference_key) => {
			let reference = _.find(state.references, (reference) => {
				return reference.node.group_key == utils.normalizeKey(key) && reference.referencing_node.group_key == utils.normalizeKey(reference_key)
			})
			return reference ? JSON.parse(JSON.stringify(reference)) : null
		}
	},
	mutations: {
		login (state, user) {
			state.user = user
		},
		logout (state) {
			state.user = null
		},
		setIdentity (state, identity) {
			let existingIndex = _.findIndex(state.identities, (i) => i.username == identity.username)

			if(existingIndex >= 0)
				state.identities.splice(existingIndex, 1)
			state.identities.push(identity)
			
			if(state.user && state.user.username == identity.username)
				state.user = identity
		},
		setNode (state, node) {
			node.key = node.path.join('/')
			node.reference_key = node.reference_path ? node.reference_path.join('_') : null
			node.title = getTitle(node.path)
			node.group_key = utils.normalizeKey(utils.getCompositeKey(node.key, node.reference_key))

			let existingIndex = _.findIndex(state.nodes, (n) => n.group_key == node.group_key)
			let existing = existingIndex >= 0 ? state.nodes[existingIndex] : null

			if(node.references == null) {
				node.references = existing ? existing.references : []
			} else {
				node.references = _.map(node.references, (n) => { return {
					path: n.path,
					reference_result: n.reference_result
				}})
			}

			if(node.inverse_references == null) {
				node.inverse_references = existing ? existing.inverse_references : []
			} else {
				node.inverse_references = _.map(node.inverse_references, (n) => { return {
					path: n.path,
					reference_result: n.reference_result
				}})
			}

			if(existingIndex >= 0)
				state.nodes.splice(existingIndex, 1)
			state.nodes.push(node)

			if(node.calculation_opts)
				state.calculation_opts = node.calculation_opts
		},
		setReference (state, reference) {
			state.references.push(reference)
		}
	},
	actions: {
		fetchIdentity({commit}, username) {
			return new Promise((resolve, reject) => {
				Api.getIdentity(username, (identity) => {
					commit('setIdentity', identity)
					if(username == 'me')
						commit('login', identity)
					resolve(identity)
				})
			})
		},
		fetchNode({commit, state}, key) {
			return new Promise((resolve, reject) => {
				Api.getNode(key, (node) => {
					_.each(node.references, (reference) => commit('setNode', reference))
					_.each(node.inverse_references, (reference) => commit('setNode', reference))
					commit('setNode', node)
					resolve(node)
				})
			})
		},
		search({commit, state}, query) {
			return new Promise((resolve, reject) => {
				Api.search(query, (node) => {
					node.path = ['Search', query]
					_.each(node.references, (reference) => commit('setNode', reference))
					commit('setNode', node)
					resolve(node)
				})
			})
		},
		fetchReference({commit, state}, {key, referenceKey}) {
			return new Promise((resolve, reject) => {
				Api.getReference(key, referenceKey, (reference) => {
					commit('setNode', reference.node)
					commit('setNode', reference.referencing_node)
					commit('setReference', reference)
					resolve(reference)
				})
			})
		},
		setVote({commit, state}, {node, unit, at_date, choice}) {
			return new Promise((resolve, reject) => {
				Api.setVote(node.key, unit, at_date, choice, function(node) {
					commit('setNode', node)
					resolve(node)
				})
			})
		},
		unsetVote({commit}, {node, unit, at_date}) {
			return new Promise((resolve, reject) => {
				Api.unsetVote(node.key, unit, at_date, function(node) {
					commit('setNode', node)
					resolve(node)
				})
			})
		},
		setReferenceVote({commit, state}, {reference, relevance}) {
			return new Promise((resolve, reject) => {
				Api.setReferenceVote(reference.node.key, reference.referencing_node.key, relevance, function(reference) {
					commit('setReference', reference)
					resolve(node)
				})
			})
		},
		unsetReferenceVote({commit}, reference) {
			return new Promise((resolve, reject) => {
				Api.unsetReferenceVote(reference.node.key, reference.referencing_node.key, function(reference) {
					commit('setReference', reference)
					resolve(node)
				})
			})
		},
		setDelegation({commit}, {username, weight, topics}) {
			return new Promise((resolve, reject) => {
				Api.setDelegation(username, weight, topics, function(identity) {
					commit('setIdentity', identity)
					resolve(identity)
				})
			})
		},
		unsetDelegation({commit}, username) {
			return new Promise((resolve, reject) => {
				Api.unsetDelegation(username, function(identity) {
					commit('setIdentity', identity)
					resolve(identity)
				})
			})
		},
		setTrust({commit}, {username, is_trusted}) {
			return new Promise((resolve, reject) => {
				Api.setTrust(username, is_trusted, function(identity) {
					commit('setIdentity', identity)
					resolve(identity)
				})
			})
		},
		unsetTrust({commit}, username) {
			return new Promise((resolve, reject) => {
				Api.unsetTrust(username, function(identity) {
					commit('setIdentity', identity)
					resolve(identity)
				})
			})
		}
	}
})