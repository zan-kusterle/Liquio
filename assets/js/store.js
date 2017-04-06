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
		identities: [],
		calculation_opts: {},
		units: _.map([
			{key: 'true', text: 'True-False', value: 'true', is_probability: true},
			{key: 'count', text: 'Count', value: 'count', is_probability: false},
			{key: 'fact', text: 'Fact-Lie', value: 'fact', is_probability: true},
			{key: 'reliable', text: 'Reliable-Unreliable', value: 'reliable', is_probability: true},
			{key: 'temperature', text: 'Temperature (°C)', value: 'temperature', is_probability: false},
			{key: 'usdollars', text: 'US Dollars (USD)', value: 'usd', is_probability: false},
			{key: 'euro', text: 'Euro (EUR)', value: 'eur', is_probability: false},
			{key: 'length', text: 'Length (m)', value: 'length', is_probability: false},
			{key: 'approve', text: 'Approve-Disapprove', value: 'approve', is_probability: true},
			{key: 'agree', text: 'Agree-Disagree', value: 'agree', is_probability: true}
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
		reference: (state) => {
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
					if(referenceNode) {
						referenceNode.reference_result = n.reference_result
					}
					return referenceNode
				}), (x) => x)

				node.inverse_references = _.filter(_.map(node.inverse_references, (n) => {
					let referenceNode = getters.getPureNodeByKey(n.path)
					if(referenceNode) {
						referenceNode.reference_result = n.reference_result
					}
					return referenceNode
				}), (x) => x)

				let unit = _.find(state.units, (u) => u.value == state.route.params.unit)
				let default_unit = unit && node.units && node.units[unit.key]
				node.default_unit = default_unit
			}
			return node
		},
		getNodesByKeys: (state, getters) => (paths) => _.filter(_.map(paths, (path) => getters.getNodeByKey(path)), (n) => n)
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
					commit('setNode', reference.reference_node)
					commit('setReference', reference)
					resolve(reference)
				})
			})
		},
		setVote({commit, state}, {node, choice}) {
			return new Promise((resolve, reject) => {
				Api.setVote(node.key, state.route.params.unit, choice, function(node) {
					commit('setNode', node)
					resolve(node)
				})
			})
		},
		unsetVote({commit}, node) {
			return new Promise((resolve, reject) => {
				Api.unsetVote(node.path, node.reference_path, function(node) {
					commit('setNode', node)
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