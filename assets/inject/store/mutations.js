import Vue from 'vue'

export default {
    SET_WHITELIST (state, payload) {
        state.whitelist = payload
    },
    SET_NODE (state, payload) {
        Vue.set(state.nodesByKey, payload.title, payload)
    },
    REMOVE_NODE (state, payload) {
        Vue.remove(state.nodesByKey, payload)
    },
    ADD_REFRESH_KEY (state, key) {
        state.refreshKeys.push(key)
    }
}
