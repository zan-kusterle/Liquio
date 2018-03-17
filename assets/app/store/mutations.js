import { formatVotes } from 'shared/votes'

export default {
    setIdentity(state, identity) {
        let existingIndex = state.identities.findIndex((i) => i.username == identity.username)

        let votes = []
        identity.votes.forEach((vote) => {
            votes = votes.concat(vote.results.by_units.map((results_by_unit, unit) => {
                return {
                    choice: results_by_unit.average,
                    unit: results_by_unit.value,
                    path: vote.path
                }
            }))
        })
        let referenceVotes = []
        identity.votes.forEach((voteNode) => {
            referenceVotes = referenceVotes.concat(voteNode.references.map((referenceVote) => {
                return {
                    relevance: referenceVote.reference_results && referenceVote.reference_results.average,
                    path: voteNode.path,
                    reference_path: referenceVote.path
                }
            }))
        })
        identity.votes_text = formatVotes(votes, referenceVotes)

        if (existingIndex >= 0)
            state.identities.splice(existingIndex, 1)
        state.identities.push(identity)
    },
    setNode(state, node) {
        node.key = node.path.join('/')

        let existingIndex = state.nodes.findIndex((n) => n.key == node.key)
        let existing = existingIndex >= 0 ? state.nodes[existingIndex] : null

        if (node.references == null) {
            node.references = existing ? existing.references : []
        } else {
            node.references = node.references.map((n) => {
                return {
                    path: n.path,
                    reference_result: n.reference_result
                }
            })
        }

        if (node.inverse_references == null) {
            node.inverse_references = existing ? existing.inverse_references : []
        } else {
            node.inverse_references = node.inverse_references.map((n) => {
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

        let existingIndex = state.references.findIndex((r) => r.key == reference.key && r.reference_key == reference.reference_key)

        if (existingIndex >= 0)
            state.references.splice(existingIndex, 1)
        state.references.push(reference)
    }
}