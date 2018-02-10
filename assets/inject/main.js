import j2c from 'j2c'
import { cleanUrl } from 'shared/votes'
import * as text from 'inject/text'
import * as video from 'inject/video'
import * as bar from 'inject/bar'
import styles from 'inject/styles'
import { CrossStorageClient } from 'cross-storage'
import * as Api from 'shared/api_client'
import { state, updateState } from 'inject/state'
import { init as initBar } from 'inject/bar'

initBar()

let classes = j2c.sheet(styles)
let style = document.createElement('style')
style.innerHTML = classes
document.getElementsByTagName('body')[0].appendChild(style)

let key = document.location.href
if (key.startsWith(LIQUIO_URL + '/page/'))
    key = decodeURIComponent(key.replace(LIQUIO_URL + '/page/', ''))
key = cleanUrl(key)

updateState({ classes, key })

// TODO: Make this support any HTML5 video
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
            updateState({ isLoading: true })
            Api.getNode(state.key, { depth: 2, trust_usernames: usernames }, (node) => {
                hasNodeWithUsernames = true
                updateState({ node: node, isLoading: false })
            })
        })
        storage.get('').then((value) => {
            updateState({ trustMetricURL: value })
        })
    })

    Api.getNode(state.key, { depth: 2 }, function (node) {
        if (!hasNodeWithUsernames) {
            updateState({ node: node, isLoading: false })
        }
    })
}

if (!state.key.startsWith(LIQUIO_URL + '/v/')) {
    let onDomNodeInsert = (node) => {
        if (node.nodeType === Node.TEXT_NODE) {
            state.textNodes.push(node)
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