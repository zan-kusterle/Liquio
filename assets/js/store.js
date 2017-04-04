import Vuex from 'vuex'

let Api = require('api.js')
let utils = require('utils.js')

let getTitle = (path) => {
	let choice_type = path[path.length - 1]
	let trim_count = choice_type == 'meta' ? 1 : 2
	let title = path.slice(0, path.length - trim_count).join('/').replace(/\_(.*)/g, '')
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
		units: [
			{text: 'True - False', value: 'True', choice_type: 'probability'},
			{text: 'Count', value: 'Count', choice_type: 'quantity'},
			{text: 'Fact - Lie', value: 'Fact', choice_type: 'probability'},
			{text: 'Reliable - Unreliable', value: 'Reliable', choice_type: 'probability'},
			{text: 'Temperature (°C)', value: 'Temperature', choice_type: 'quantity'},
			{text: 'US Dollars (USD)', value: 'USD', choice_type: 'quantity'},
			{text: 'Length (m)', value: 'Length', choice_type: 'quantity'},
			{text: 'Approve - Disapprove', value: 'Approve', choice_type: 'probability'},
			{text: 'Agree - Disagree', value: 'Agree', choice_type: 'probability'}
		]
	},
	getters: {
		keys: (state) => state.route.params.key ? state.route.params.key.split('___') : [],
		referencingKeys: (state) => state.route.params.referenceKey ? state.route.params.referenceKey.split('___') : [],
		referenceKeyPairs: (state, getters) => _.flatMap(getters.keys, (key) =>
			getters.referencingKeys.length == 0 ? [key] : _.map(getters.referencingKeys, (referenceKey) => {
				return {key, referenceKey}
		})),
		nodePath: (state) => {
			let path = (state.route.params.key || '').split('_')
			let unit_value = path[path.length - 1]
			let unit = _.find(state.units, (x) => x.value == unit_value)
			let choice_type = unit ? unit.choice_type : 'meta'
			path.push(choice_type)
			return path
		},
		nodeKey: (state, getters) => getters.nodePath.join('_'),
		nodeTitle: (state, getters) => getTitle(getters.nodePath),
		searchQuery: (state) => state.route.params.query,
		searchResults: (state, getters) => (query) => {
			let node = getters.getNodeByKey(['Search', query])
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
			node.key = node.path.join('_')
			node.reference_key = node.reference_path ? node.reference_path.join('_') : null
			node.title = getTitle(node.path)
			let choice_type = node.path[node.path.length - 1]
			node.unit = choice_type == 'meta' ? null : node.path[node.path.length - 2]
			let key = utils.normalizeKey(utils.getCompositeKey(node.key, node.reference_key))
			let existingIndex = _.findIndex(state.nodes, (n) => n.group_key == key)
			let existing = existingIndex >= 0 ? state.nodes[existingIndex] : null
			
			node.group_key = key
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
				Api.getReference(key, referenceKey, (node) => {
					commit('setNode', node)
					resolve(node)
				})
			})
		},
		setVote({commit}, {node, choice}) {
			return new Promise((resolve, reject) => {
				Api.setVote(node.key, node.reference_key, choice, function(node) {
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