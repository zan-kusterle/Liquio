import Vuex from 'vuex'
import createPersist, { createStorage } from 'vuex-localstorage'

let Api = require('api.js')
let utils = require('utils.js')

var plugins = []
if(false && process.env.NODE_ENV == 'production') {
	plugins.push(createPersist({
		namespace: 'liquio',
		initialState: {},
		expires: 7 * 24 * 60 * 60 * 1e3
	}))
}

export default new Vuex.Store({
	plugins: plugins,
	state: {
		user: null,
		nodes: [],
		identities: []
	},
	getters: {
		keys: (state) => state.route.params.key ? state.route.params.key.split('_') : [],
		referencingKeys: (state) => state.route.params.referenceKey ? state.route.params.referenceKey.split('_') : [],
		referenceKeyPairs: (state, getters) => _.flatMap(getters.keys, (key) =>
			getters.referencingKeys.length == 0 ? [key] : _.map(getters.referencingKeys, (referenceKey) => {
				return {key, referenceKey}
		})),
		getPureNodeByKey: (state, getters) => (key) => {
			let node = _.find(state.nodes, (node) => {
				return node.full_key == utils.normalizeKey(key)
			})
			return node ? JSON.parse(JSON.stringify(node)) : null
		},
		getNodeByKey: (state, getters) => (key) => {
			let node = getters.getPureNodeByKey(key)
			if(node) {
				node.references = _.filter(_.map(node.references, (n) => {
					let referenceNode = getters.getPureNodeByKey(n.key)
					if(referenceNode) {
						referenceNode.reference_result = n.reference_result
					}
					return referenceNode
				}), (x) => x)

				node.inverse_references = _.filter(_.map(node.inverse_references, (n) => {
					let referenceNode = getters.getPureNodeByKey(n.key)
					if(referenceNode) {
						referenceNode.reference_result = n.reference_result
					}
					return referenceNode
				}), (x) => x)
			}
			return node
		},
		getNodesByKeys: (state, getters) => (keys) => _.filter(_.map(keys, (key) => getters.getNodeByKey(key)), (n) => n)
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
			let key = utils.normalizeKey(utils.getCompositeKey(node.key, node.reference_key))
			let existingIndex = _.findIndex(state.nodes, (n) => n.full_key == key)
			let existing = existingIndex >= 0 ? state.nodes[existingIndex] : null
			
			node.full_key = key
			if(node.references == null) {
				node.references = existing ? existing.references : []
			} else {
				node.references = _.map(node.references, (n) => { return {
					key: n.key,
					reference_result: n.reference_result
				}})
			}

			if(node.inverse_references == null) {
				node.inverse_references = existing ? existing.inverse_references : []
			} else {
				node.inverse_references = _.map(node.inverse_references, (n) => { return {
					key: n.key,
					reference_result: n.reference_result
				}})
			}

			if(existingIndex >= 0)
				state.nodes.splice(existingIndex, 1)
			state.nodes.push(node)
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
				Api.setVote(node.url_key, node.reference_key && node.reference_key.replace(/\_/g, '-'), choice, function(node) {
					commit('setNode', node)
					resolve(node)
				})
			})
		},
		unsetVote({commit}, node) {
			return new Promise((resolve, reject) => {
				Api.unsetVote(node.url_key, node.reference_key && node.reference_key.replace(/\_/g, '-'), function(node) {
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