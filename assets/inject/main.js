import jss from 'jss'
import preset from 'jss-preset-default'
import * as utils from 'inject/utils'
import * as text from 'inject/text'
import * as video from 'inject/video'
import * as bar from 'inject/bar'
import styles from 'inject/styles'
import {
    CrossStorageClient
} from 'cross-storage'

jss.setup(preset())
const {
    classes
} = jss.createStyleSheet(styles).attach()

let key = document.location.href
if (key.startsWith(LIQUIO_URL + '/page/'))
    key = decodeURIComponent(key.replace(LIQUIO_URL + '/page/', ''))
key = utils.cleanUrl(key)

if (!window.location.href.startsWith(LIQUIO_URL + '/v/') || window.location.href.startsWith(LIQUIO_URL + '/page')) {
    let storage = new CrossStorageClient(LIQUIO_URL + '/hub.html')
    let storageUsernames, storageTrustMetricURL
    storage.onConnect().then(function () {
        storage.get('usernames').then(function (usernames) {
            storageUsernames = usernames.split(',')
            if (storageTrustMetricURL)
                onDataReady(storageUsernames, storageTrustMetricURL)
        })
        storage.get('').then(function (value) {
            storageTrustMetricURL = value
            if (storageUsernames)
                onDataReady(storageUsernames, storageTrustMetricURL)
        })
    }).catch(function () {
        onDataReady([], null)
    })
}

let onDataReady = (usernames, trustMetricURL) => {
    if (key.startsWith("https:www.youtube.com/watch")) {
        window.onYouTubeIframeAPIReady = video.onYouTubeIframeAPIReady

        var tag = document.createElement('script')
        tag.src = 'https://www.youtube.com/iframe_api'
        var firstScriptTag = document.getElementsByTagName('script')[0]
        firstScriptTag.parentNode.insertBefore(tag, firstScriptTag)
    }

    utils.getUrl(LIQUIO_URL + '/api/nodes/' + encodeURIComponent(key) + '?depth=2&trust_usernames=' + usernames.join(','), function (data) {
        onResultsReady(data.data, trustMetricURL)
    })
}

let onResultsReady = (node, trustMetricURL) => {
    bar.init(key, trustMetricURL, node.results.by_units['reliable'], classes)

    let nodes_by_text = get_nodes_by_text(node)

    text.init(nodes_by_text, classes)
    video.setData(nodes_by_text)

    if (!key.startsWith(LIQUIO_URL + '/v/')) {
        initDomListener()
    }
}

let onDomNodeInsert = (node) => {
    if (node.nodeType === Node.TEXT_NODE) {
        text.onTextInsert(node)
    } else if (node.nodeName.toLowerCase() === 'a') {
        text.onAnchorInsert(node)
    }
}

function initDomListener() {
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


let get_nodes_by_text = (node) => {
    var nodes_by_text = {}
    node.references.forEach(function (reference) {
        reference.inverse_references.forEach(function (inverse_reference) {
            let topic = inverse_reference.path.join('/')
            if (topic.startsWith(key + '/')) {
                let remainder = topic.substring(key.length + 1)
                if (remainder.length > 0) {
                    let text = remainder.replace(/-/g, ' ')
                    if (!(text in nodes_by_text))
                        nodes_by_text[text] = []
                    nodes_by_text[text].push(reference)
                }
            }
        })
    })
    return nodes_by_text
}