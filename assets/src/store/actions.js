import axios from 'axios'

let fetchNode = (key, whitelist, depth) => {
    return new Promise((resolve, reject) => {
        if (whitelist && (whitelist.url || whitelist.username)) {
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
        } else {
            reject('No whitelist set')
        }
    })
}

export default {
    initialize ({ commit, dispatch }) {
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
            }
        })

        if (false && process.env.NODE_ENV === 'development') {
            setTimeout(() => {
                dispatch('vote', {
                    messages: [
                        {
                            name: 'vote',
                            key: ['title', 'unit'],
                            title: 'asd',
                            unit: 'Reliable-Unreliable',
                            choice: 0.9
                        }
                    ],
                    messageKeys: ['title', 'reference_title', 'relevance', 'unit', 'choice']
                })
            }, 2000)
        }
    },
    setCurrentPage ({state, commit, dispatch }, payload) {
        commit('SET_CURRENT_PAGE', payload)
        dispatch('loadNode', { key: payload, refresh: true })
    },
    setCurrentTitle ({state, commit, dispatch }, payload) {
        commit('SET_CURRENT_TITLE', payload)
        dispatch('loadNode', { key: payload, refresh: true })
    },
    updateNodes ({ state, commit }) {
        let promises = state.refreshKeys.map(key => fetchNode(key, state.whitelist, 2))
        axios.all(promises).then(response => {
            for (let node of response) {
                commit('SET_NODE', node)
            }
        }).catch(() => {})
    },
    vote ({ commit }, { messages, messageKeys }) {
        commit('SET_IS_SIGN_WINDOW_OPEN', true)

        let data = {
            name: 'sign',
            messages: messages,
            messageKeys: messageKeys
        }
        let event = new CustomEvent('sign-anything', { detail: data })
        window.dispatchEvent(event)

        return new Promise((resolve, reject) => {
            let onSignResponse = (e) => {
                let data = e.detail
                if (data.request_name === 'sign') {
                    window.removeEventListener('sign-anything-response', onSignResponse)
                    resolve()
                }
            }
            window.addEventListener('sign-anything-response', onSignResponse)
        })
    },
    loadNode ({ state, commit }, { key, refresh }) {
        return new Promise((resolve, reject) => {
            if (refresh) {
                commit('ADD_REFRESH_KEY', key)
            }
            fetchNode(key, state.whitelist, 2).then(node => {
                commit('SET_NODE', node)
                resolve(node)
            }).catch(() => {})
        })
    }
}
