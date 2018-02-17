import transformNode from 'inject/transform_content'


export let state = {
    app: null,
    isLoading: true,
    key: null,
    publicKeys: null,
    node: null,
    nodesByText: {},
    videoPlayer: null,
    textNodes: [],
    trustMetricURL: process.env.NODE_ENV === 'production' ? 'https://trust-metric.liqu.io' : 'http://127.0.0.1:8080/dev_trust_metric.html',
    selection: null
}

export function updateState(newValue) {
    for (let key in newValue) {
        state[key] = newValue[key]
    }
    if (state.key) {
        if (newValue.node) {
            let getNodesByText = (node, key) => {
                var result = {}
                node.references.forEach(function (reference) {
                    reference.inverse_references.forEach(function (inverse_reference) {
                        let topic = inverse_reference.path.join('/')
                        if (topic.startsWith(key + '/')) {
                            let text = topic.substring(key.length + 1)
                            if (text.length > 0) {
                                if (!(text in result)) {
                                    result[text] = []
                                }
                                result[text].push(reference)
                            }
                        }
                    })
                })
                return result
            }

            let nodesByText = getNodesByText(state.node, state.key)

            for (let domNode of state.textNodes) {
                transformNode(nodesByText, domNode)
            }
        }
    }

    if (state.app) {
        state.app.isHidden = state.isHidden
        state.app.key = state.key
        state.app.publicKeys = state.publicKeys
        state.app.node = state.node
        state.app.trustMetricUrl = state.trustMetricURL
        state.app.currentNode = state.currentNode
        state.app.currentSelection = state.selection
    }
}