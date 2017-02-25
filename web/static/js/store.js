import Vuex from 'vuex'

let Api = require('api.js')

export default new Vuex.Store({
	state: {
		user: null,
		nodes: {},
		identities: {}
	},
	mutations: {
		increment (state) {
			state.count++
		},
		login (state, user) {
			state.user = user
		},
		logout (state) {
			state.user = null
		}
	},
	actions: {
		fetchCurrentUser({commit}) {
			Api.getIdentity('me', (identity) => {
				commit('login', identity)
			}, 1000)
		}
	}
})