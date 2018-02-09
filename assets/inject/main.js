import j2c from 'j2c'
import * as utils from 'inject/utils'
import * as text from 'inject/text'
import * as video from 'inject/video'
import * as bar from 'inject/bar'
import styles from 'inject/styles'
import { CrossStorageClient } from 'cross-storage'
import * as Api from 'shared/api_client'

let classes = j2c.sheet(styles)
let style = document.createElement('style')
style.innerHTML = classes
document.getElementsByTagName('body')[0].appendChild(style)

let key = document.location.href
if (key.startsWith(LIQUIO_URL + '/page/'))
    key = decodeURIComponent(key.replace(LIQUIO_URL + '/page/', ''))
key = utils.cleanUrl(key)

let state = {
    classes: classes,
    key: key,
    node: null,
    videoPlayer: null,
    textNodeQueue: [],
    trustMetricURL: null,
}

let updateState = (newValue) => {
    for (let key in newValue) {
        state[key] = newValue[key]
    }

    if (state.node) {
        for (let queuedNode of state.textNodeQueue) {
            console.log(queuedNode)
            text.onTextInsert(getNodesByText(state.node), queuedNode, state.classes)
        }
        state.textNodeQueue = []
        
        if (newValue.trustMetricURL !== undefined) {
            bar.init(state.key, state.trustMetricURL, state.node.results.by_units['reliable'], state.classes)
        }

        if (state.videoPlayer) {
            video.init(getNodesByText(state.node), state.videoPlayer, state.classes)
        }
    }
}

let getNodesByText = (node) => {
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

if (state.key.startsWith("https:www.youtube.com/watch")) {
    window.onYouTubeIframeAPIReady = () => {
        let player = new YT.Player('main-video-frame', {
            events: {
                'onReady': (event) => {
                    updateState({ videoPlayer: player })
                }
            }
        })
    }

    var tag = document.createElement('script')
    tag.src = 'https://www.youtube.com/iframe_api'
    var firstScriptTag = document.getElementsByTagName('script')[0]
    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag)
}

if (!window.location.href.startsWith(LIQUIO_URL + '/v/') || window.location.href.startsWith(LIQUIO_URL + '/page')) {
    let storage = new CrossStorageClient(LIQUIO_URL + '/hub.html')
    let hasNodeWithUsernames = false
    storage.onConnect().then(function () {
        storage.get('usernames').then((usernames) => {
            utils.getUrl(LIQUIO_URL + '/api/nodes/' + encodeURIComponent(state.key) + '?depth=2&trust_usernames=' + usernames, (data) => {
                hasNodeWithUsernames = true
                updateState({ node: data.data })
            })
        })
        storage.get('').then((value) => {
            updateState({ trustMetricURL: value })
        })
    })

    utils.getUrl(LIQUIO_URL + '/api/nodes/' + encodeURIComponent(key) + '?depth=2', function (data) {
        if (!hasNodeWithUsernames) {
            updateState({ node: data.data })
        }
    })
}

if (!state.key.startsWith(LIQUIO_URL + '/v/')) {
    let onDomNodeInsert = (node) => {
        if (node.nodeType === Node.TEXT_NODE) {
            if (state.node) {
                text.onTextInsert(getNodesByText(state.node), node, state.classes)
            } else {
                state.textNodeQueue.push(node)
            }
        } else if (node.nodeName.toLowerCase() === 'a') {
            text.onAnchorInsert(node)
        }
    }

    let walker = document.createTreeWalker(document, NodeFilter.SHOW_TEXT, null, false)
    while (walker.nextNode())
        onDomNodeInsert(walker.currentNode)

    let MutationObserver = window.MutationObserver || window.WebKitMutationObserver
    let eventListenerSupported = window.addEventListener

    if (MutationObserver) {
        let obs = new MutationObserver(function (mutations, observer) {
            mutations.forEach((mutation) => {
                mutation.addedNodes.forEach((node) => {
                    onDomNodeInsert(node)
                })
            })
        })
        obs.observe(document, {
            childList: true,
            subtree: true
        })
    } else if (eventListenerSupported) {
        document.addEventListener('DOMNodeInserted', function (e) {
            onDomNodeInsert(e.target)
        }, false)
    }
}