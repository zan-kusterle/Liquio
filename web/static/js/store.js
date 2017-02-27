import Vuex from 'vuex'

let Api = require('api.js')
let utils = require('utils.js')

export default new Vuex.Store({
	state: {
		user: null,
		nodes: [],
		identities: {}
	},
	getters: {
		keys: (state) => state.route.params.key.split('_'),
		referencingKeys: (state) => state.route.params.referenceKey ? state.route.params.referenceKey.split('_') : [],
		referenceKeys: (state, getters) => _.flatMap(getters.keys, (key) =>
			getters.referencingKeys.length == 0 ? [key] : _.map(getters.referencingKeys, (referenceKey) => utils.getCompositeKey(key, referenceKey))),
		getNodesByKeys: (state, getters) => (keys) => _.filter(state.nodes, (node) => _.some(keys, (key) =>
			utils.normalizeKey(utils.getCompositeKey(node.key, node.reference_key)) == utils.normalizeKey(key)))
	},
	mutations: {
		login (state, user) {
			state.user = user
		},
		logout (state) {
			state.user = null
		},
		setIdentity (state, identity) {
			state.identities[identity.username] = identity
			if(state.user && state.user.username == identity.username)
				state.user = identity
		},
		setNode (state, node) {
			state.nodes = _.reject(state.nodes, (n) => n.key == node.key && n.reference_key == node.reference_key)
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