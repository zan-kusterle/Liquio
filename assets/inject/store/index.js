import getters from './getters'
import actions from './actions'
import mutations from './mutations'

export default {
    state: {
        whitelist: {
            url: null,
            username: null
        },
        nodesByKey: {},
        refreshKeys: []
    },
    getters: getters,
    actions: actions,
    mutations: mutations
}
