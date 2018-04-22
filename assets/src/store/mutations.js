import Vue from 'vue'

export default {
    SET_WHITELIST (state, payload) {
        state.whitelist = payload
    },
    SET_NODE (state, payload) {
        Vue.set(state.nodesByKey, payload.title, payload)
    },
    REMOVE_NODE (state, payload) {
        Vue.set(state.nodesByKey, payload, null)
    },
    ADD_REFRESH_KEY (state, key) {
        state.refreshKeys.push(key)
    },
    SET_CURRENT_PAGE (state, url) {
        state.currentPage = url
    },
    SET_CURRENT_TITLE (state, title) {
        state.currentTitle = title
    },
    SET_CURRENT_REFERENCE_TITLE (state, title) {
        state.currentReferenceTitle = title
    },
    ADD_TO_HISTORY (state) {
        state.history.splice(state.historyIndex + 1, state.history.length - state.historyIndex)
        state.history.push({
            title: state.currentTitle,
            referenceTitle: state.currentReferenceTitle
        })
        state.historyIndex = state.history.length - 1
    },
    GO_TO_HISTORY_INDEX (state, index) {
        let item = state.history[index]
        state.currentTitle = item.title
        state.currentReferenceTitle = item.referenceTitle
        state.historyIndex = index
    },
    SET_IS_SIGN_WINDOW_OPEN (state, isOpen) {
        state.isSignWindowOpen = isOpen
    }
}
