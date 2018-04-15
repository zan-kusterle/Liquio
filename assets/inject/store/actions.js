import axios from 'axios'

let fetchNode = (state, key) => {
    return new Promise((resolve, reject) => {
        if (state.whitelist && (state.whitelist.url || state.whitelist.username)) {
            let params = { depth: 2 }
            if (state.whitelist.url) {
                params.whitelist_url = state.whitelist.url
            }
            if (state.whitelist.username) {
                params.whitelist_usernames = state.whitelist.username
            }

            console.log(LIQUIO_URL + '/api/nodes/' + encodeURIComponent(key))
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
    updateNodes ({ state, commit }) {
        let promises = state.refreshKeys.map(key => fetchNode(state, key))
        axios.all(promises).then(response => {
            for (let node of response) {
                commit('SET_NODE', node)
            }
        }).catch(() => {})

        let clearKeys = Object.keys(state.nodesByKey).filter(k => !state.refreshKeys.includes(k))
        clearKeys.forEach(key => commit('REMOVE_NODE', key))
    },
    vote ({}, { messages, messageKeys }) {
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
            fetchNode(state, key).then(node => {
                commit('SET_NODE', node)
                resolve(node)
            }).catch(() => {})
        })
    }
}
