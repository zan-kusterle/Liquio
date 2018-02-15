import { cleanUrl } from 'shared/votes'
import { CrossStorageClient } from 'cross-storage'
import * as Api from 'shared/api_client'
import { usernameFromPublicKey } from 'shared/identity'
import { state, updateState } from 'inject/state'
import Vue from 'vue'
import Bar from 'inject/bar.vue'
import { decodeBase64 } from 'shared/utils';

let isExtension = !!(window.chrome && chrome.runtime && chrome.runtime.id)

let vueElement = document.createElement('div')
vueElement.id = isExtension ? 'liquio-bar-extension' : 'liquio-bar'
document.getElementsByTagName('body')[0].appendChild(vueElement)
vueElement.appendChild(document.createElement('div'))

const BarConstructor = Vue.extend(Bar)
const app = new BarConstructor({
    el: vueElement.childNodes[0]
})

if (isExtension) {
    chrome.runtime.onMessage.addListener(function(message, sender, sendResponse) {
        if (message === 'update') {
            onUrlChange(document.location.href)
        }
    });    
}

function onUrlChange (url) {
    let isLiquio = url.startsWith(LIQUIO_URL + '/page/') || url.startsWith(LIQUIO_URL + '/v/')
    let isInactive = isExtension && document.getElementById('liquio-bar')
    let isHidden = isLiquio || isInactive
    let key = cleanUrl(decodeURIComponent(url))

    updateState({ isHidden, key, app }, app)

    if (isExtension) {
        
    } else {
        // Read local storage
        let storage = new CrossStorageClient(LIQUIO_URL + '/hub.html')
        let hasNodeWithUsernames = false
        storage.onConnect().then(function () {
            state.app.crossStorage = storage
            storage.get('publicKeys').then((encodedPublicKeys) => {
                let publicKeys = encodedPublicKeys.split(',').map(p => decodeBase64(p))
                let usernames = publicKeys.map(p => usernameFromPublicKey(p))
                updateState({ publicKeys: publicKeys, isLoading: true })
                Api.getNode(state.key, { depth: 2, trust_usernames: usernames.join(',') }, (node) => {
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
}
    

// Set MutationObserver
let onDomNodeInsert = (node) => {
    if (node.nodeType === Node.TEXT_NODE) {
        state.textNodes.push(node)
    } else if (node.nodeName.toLowerCase() === 'a') {
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

window.addEventListener("hashchange", () => onUrlChange(document.location.href), false)
onUrlChange(document.location.href)

// Update current selection
let updateSelection = () => updateState({ selection: (window.getSelection().toString() || null) })
document.addEventListener('keyup', updateSelection)
document.addEventListener('mouseup', updateSelection)
