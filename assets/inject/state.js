import * as text from 'inject/text'
import * as video from 'inject/video'
import { updateState as updateBarState } from 'inject/bar'

let getNodesByText = (node, key) => {
    var result = {}
    node.references.forEach(function (reference) {
        reference.inverse_references.forEach(function (inverse_reference) {
            let topic = inverse_reference.path.join('/')
            if (topic.startsWith(key + '/')) {
                let remainder = topic.substring(key.length + 1)
                if (remainder.length > 0) {
                    let text = remainder.replace(/-/g, ' ')
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

export let state = {
    isLoading: true,
    classes: null,
    key: null,
    node: null,
    nodesByText: {},
    videoPlayer: null,
    textNodes: [],
    trustMetricURL: process.env.NODE_ENV === 'production' ? 'https://trust-metric.liqu.io' : 'http://127.0.0.1:8080/dev_trust_metric.html'
}

export function updateState(newValue) {
    for (let key in newValue) {
        state[key] = newValue[key]
    }
    if (state.key) {
        if (newValue.node) {
            state.nodesByText = getNodesByText(state.node, state.key)

            for (let domNode of state.textNodes) {
                text.onTextInsert(state.nodesByText, domNode, state.classes)
            }
        }

        updateBarState(state)

        if (state.node) {
            if (state.videoPlayer) {
                video.init(state.nodesByText, state.videoPlayer, state.classes)
            }
        }
    }
}