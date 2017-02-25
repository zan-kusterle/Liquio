import Vuex from 'vuex'

let Api = require('api.js')

export default new Vuex.Store({
	state: {
		user: null,
		nodes: {},
		identities: {}
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
			state.nodes[node.key] = node
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
		fetchNode({commit}, key) {
			return new Promise((resolve, reject) => {
				Api.getNode(key, null, (node) => {
					commit('setNode', node)
					resolve(node)
				})
			})
		},
		setVote({commit}, node, choice) {
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