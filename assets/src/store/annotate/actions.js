/* global LIQUIO_URL */

import axios from 'axios'

let fetchNode = (key, whitelist, depth) => {
	return new Promise((resolve, reject) => {
		let params = {}
		if (depth) {
			params.depth = depth
		}
		if (whitelist.url) {
			params.whitelist_url = whitelist.url
		}
		if (whitelist.username) {
			params.whitelist_usernames = whitelist.username
		}

		axios.get(LIQUIO_URL + '/api/nodes/' + encodeURIComponent(key), { params: params }).then((response) => {
			resolve(response.data.data)
		}).catch(e => reject(e))
	})
}

let fetchSearch = (query, whitelist) => {
	return new Promise((resolve, reject) => {
		let params = {}
		if (whitelist.url) {
			params.whitelist_url = whitelist.url
		}
		if (whitelist.username) {
			params.whitelist_usernames = whitelist.username
		}

		axios.get(LIQUIO_URL + '/api/search/' + encodeURIComponent(query), { params: params }).then((response) => {
			resolve(response.data.data)
		}).catch(e => reject(e))
	})
}

export default {
	initialize ({ commit, dispatch, state }) {
		window.addEventListener('sign-anything-response', (e) => {
			let data = e.detail
			if (data.request_name === 'whitelist') {
				this.username = data.username
				this.whitelistUrl = data.url
				commit('SET_WHITELIST', {
					username: data.username,
					url: data.url
				})
				dispatch('updateNodes')
			} else if (data.request_name === 'sign') {
				// TODO get refresh titles from store
				let currentTitle = state.currentTitle
				let currentReferenceTitle = state.currentReferenceTitle
				setTimeout(() => {
					dispatch('loadNode', { key: state.currentPage })
					if (currentTitle)
						dispatch('loadNode', { key: currentTitle })
					if (currentReferenceTitle)
						dispatch('loadNode', { key: currentReferenceTitle })
				}, 500)
			}
		})
	},
	setCurrentPage ({ commit, dispatch }, payload) {
		commit('SET_CURRENT_PAGE', payload)
		dispatch('loadNode', { key: payload, refresh: true })
	},
	setCurrentTitle ({ commit, dispatch }, payload) {
		commit('SET_IS_VOTING_DISABLED', false)
		commit('SET_CURRENT_TITLE', payload)
		commit('ADD_TO_HISTORY')
		dispatch('loadNode', { key: payload, refresh: true })
	},
	setCurrentReferenceTitle ({ commit, dispatch }, payload) {
		commit('SET_CURRENT_REFERENCE_TITLE', payload)
		if (payload) {
			commit('ADD_TO_HISTORY')
			dispatch('loadNode', { key: payload, refresh: true })
		}
	},
	disableVoting ({ commit }) {
		commit('SET_IS_VOTING_DISABLED', true)
	},
	navigateBack ({ state, commit }) {
		if (state.historyIndex > 0) {
			commit('GO_TO_HISTORY_INDEX', state.historyIndex - 1)
		}
	},
	updateNodes ({ state, dispatch }) {
		for (let key of state.refreshKeys) {
			dispatch('loadNode', { key: key })
		}
	},
	search ({ state }, query) {
		return fetchSearch(query, state.whitelist)
	},
	vote (_, { messages, messageKeys }) {
		let data = messages.map(x => {
			return { ...x, keys: messageKeys }
		})
		let event = new CustomEvent('sign-anything', { detail: data })
		window.dispatchEvent(event)
	},
	loadNode ({ state, commit }, { key, refresh }) {
		let transformReference = (reference) => {
			return {
				title: reference.title,
				referenceResults: reference.reference_results,
				byTitle: reference.referencing_title
			}
		}

		let flattenNode = (node) => {
			let nodes = []
			let existingNode = state.nodesByKey[node.title] || {}
			nodes.push({
				title: node.title,
				results: node.results,
				references: node.references === null ? existingNode.references : node.references.map(transformReference),
				inverseReferences: node.inverse_references === null ? existingNode.inverseReferences : node.inverse_references.map(transformReference)
			})

			if (node.references)
				for (let reference of node.references) {
					for (let flatReferenceNode of flattenNode(reference)) {
						if (!nodes.find(n => n.title === flatReferenceNode.title)) {
							nodes.push(flatReferenceNode)
						}
					}
				}

			if (node.inverse_references)
				for (let inverseReference of node.inverse_references) {
					for (let flatInverseReferenceNode of flattenNode(inverseReference)) {
						if (!nodes.find(n => n.title === flatInverseReferenceNode.title)) {
							nodes.push(flatInverseReferenceNode)
						}
					}
				}

			return nodes
		}

		return new Promise((resolve) => {
			if (refresh) {
				commit('ADD_REFRESH_KEY', key)
			}
			fetchNode(key, state.whitelist, 2).then(node => {
				for (let flatNode of flattenNode(node))
					commit('SET_NODE', flatNode)
				resolve(node)
			}).catch(() => {})
		})
	}
}
