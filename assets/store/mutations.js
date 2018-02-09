import { formatVotes } from 'shared/votes'

export default {
    setIdentity(state, identity) {
        let existingIndex = _.findIndex(state.identities, (i) => i.username == identity.username)

        let votes = _.flatMap(identity.votes, (vote) => {
            return _.map(vote.results.by_units, (results_by_unit, unit) => {
                return {
                    choice: results_by_unit.average,
                    unit: results_by_unit.value,
                    path: vote.path
                }
            })
        })
        let referenceVotes = _.flatMap(identity.votes, (voteNode) => {
            return _.map(voteNode.references, (referenceVote) => {
                return {
                    relevance: referenceVote.reference_results && referenceVote.reference_results.average,
                    path: voteNode.path,
                    reference_path: referenceVote.path
                }
            })
        })
        identity.votes_text = formatVotes(votes, referenceVotes)

        if (existingIndex >= 0)
            state.identities.splice(existingIndex, 1)
        state.identities.push(identity)
    },
    setNode(state, node) {
        node.key = node.path.join('/')

        let existingIndex = _.findIndex(state.nodes, (n) => n.key == node.key)
        let existing = existingIndex >= 0 ? state.nodes[existingIndex] : null

        if (node.references == null) {
            node.references = existing ? existing.references : []
        } else {
            node.references = _.map(node.references, (n) => {
                return {
                    path: n.path,
                    reference_result: n.reference_result
                }
            })
        }

        if (node.inverse_references == null) {
            node.inverse_references = existing ? existing.inverse_references : []
        } else {
            node.inverse_references = _.map(node.inverse_references, (n) => {
                return {
                    path: n.path,
                    reference_result: n.reference_result
                }
            })
        }

        if (existingIndex >= 0)
            state.nodes.splice(existingIndex, 1)
        state.nodes.push(node)
    },
    setReference(state, reference) {
        reference.key = reference.node.path.join('/')
        reference.reference_key = reference.referencing_node.path.join('/')

        let existingIndex = _.findIndex(state.references, (r) => r.key == reference.key && r.reference_key == reference.reference_key)

        if (existingIndex >= 0)
            state.references.splice(existingIndex, 1)
        state.references.push(reference)
    }
}