import * as Api from 'shared/api_client'


let prepareOpts = (opts) => {
    return {
        ...opts,
        trust_usernames: opts.keypairs ? opts.keypairs.map((k) => k.username).join(',') : opts.trust_usernames
    }
}

export default {
    finishRegistration({ commit, state }, { token, username, name }) {
        return new Promise((resolve, reject) => {
            Api.register(token, username, name, function(identity) {
                commit('setIdentity', identity)
                resolve(identity)
            })
        })
    },
    fetchIdentity({ commit, state }, username) {
        return new Promise((resolve, reject) => {
            Api.getIdentity(username, (identity) => {
                commit('setIdentity', identity)
                resolve(identity)
            })
        })
    },
    fetchNode({ commit, state, getters }, key) {
        return new Promise((resolve, reject) => {
            Api.getNode(key, prepareOpts(getters.currentOpts), (node) => {
                _.each(node.references, (reference) => commit('setNode', reference))
                _.each(node.inverse_references, (reference) => commit('setNode', reference))
                commit('setNode', node)
                resolve(node)
            })
        })
    },
    search({ commit, state }, query) {
        return new Promise((resolve, reject) => {
            Api.search(query, (node) => {
                node.path = ['Search', query]
                _.each(node.references, (reference) => commit('setNode', reference))
                commit('setNode', node)
                resolve(node)
            })
        })
    },
    fetchReference({ commit, state, getters }, { key, referenceKey }) {
        return new Promise((resolve, reject) => {
            Api.getReference(key, referenceKey, prepareOpts(getters.currentOpts), (reference) => {
                commit('setNode', reference.node)
                commit('setNode', reference.referencing_node)
                commit('setReference', reference)
                resolve(reference)
            })
        })
    },
    setVote({ commit, state, getters }, { key, unit, at_date, choice }) {
        return new Promise((resolve, reject) => {
            let keypair = getters.currentOpts.keypair
            let signature = Api.sign(keypair.secretKey, Api.getVoteMessage(key, unit, at_date, choice))
            Api.setVote(keypair.publicKey, signature, key, unit, at_date, choice, function(node) {
                commit('setNode', node)
                resolve(node)
            })
        })
    },
    unsetVote({ commit, state, getters }, { key, unit, at_date }) {
        return new Promise((resolve, reject) => {
            Api.unsetVote(getters.currentOpts, key, unit, at_date, function(node) {
                commit('setNode', node)
                resolve(node)
            })
        })
    },
    setReferenceVote({ commit, state, getters }, { key, referencingKey, relevance }) {
        return new Promise((resolve, reject) => {
            let keypair = getters.currentOpts.keypair
            let signature = Api.sign(keypair.secretKey, Api.getReferenceVoteMessage(key, referencingKey, relevance))
            Api.setReferenceVote(keypair.publicKey, signature, key, referencingKey, relevance, function(reference) {
                commit('setReference', reference)
                resolve(reference)
            })
        })
    },
    unsetReferenceVote({ commit, state, getters }, { key, referencingKey }) {
        return new Promise((resolve, reject) => {
            Api.unsetReferenceVote(getters.currentOpts, key, referencingKey, function(reference) {
                commit('setReference', reference)
                resolve(reference)
            })
        })
    },
    setDelegation({ commit, state, getters }, { username, is_trusted, weight, topics }) {
        return new Promise((resolve, reject) => {
            Api.setDelegation(getters.currentOpts, username, is_trusted, weight, topics, function(identity) {
                commit('setIdentity', identity)
                resolve(identity)
            })
        })
    },
    unsetDelegation({ commit, state, getters }, { username }) {
        return new Promise((resolve, reject) => {
            Api.unsetDelegation(getters.currentOpts, username, function(identity) {
                commit('setIdentity', identity)
                resolve(identity)
            })
        })
    },
    setIdentification({ commit, state, getters }, { key, name }) {
        return new Promise((resolve, reject) => {
            Api.setIdentification(getters.currentOpts, key, name, function(identity) {
                commit('setIdentity', identity)
                resolve(identity)
            })
        })
    }
}