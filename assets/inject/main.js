import 'webextension-polyfill'
import { cleanUrl } from 'shared/votes'
import * as Api from 'shared/api_client'
import { usernameFromPublicKey } from 'shared/identity'
import Vue from 'vue'
import Bar from 'inject/bar.vue'
import { decodeBase64 } from 'shared/utils';
import transformNode from 'inject/transform_content'
let vueElement = document.createElement('div')
vueElement.id = IS_EXTENSION ? 'liquio-bar-extension' : 'liquio-bar'
document.getElementsByTagName('body')[0].appendChild(vueElement)
vueElement.appendChild(document.createElement('div'))

const vm = new Vue({
    el: vueElement.childNodes[0],
    data () {
        return {
            isUnavailable: false,
            urlKey: null,
            currentNode: null,
            currentSelection: null,
            currentVideoTime: null,
        }
    },
    render (createElement) {
        return createElement(Bar, {
            props: {
                isUnavailable: this.isUnavailable,
                urlKey: this.urlKey,
                currentNode: this.currentNode,
                currentSelection: this.currentSelection,
                currentVideoTime: this.currentVideoTime
            }
        })
    }
})

let textNodes = []
vm.$on('update-node', (node) => {
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

    let nodesByText = getNodesByText(node, vm.urlKey)

    for (let domNode of textNodes) {
        transformNode(nodesByText, domNode, (activeNode) => {
            vm.currentNode = activeNode
        })
    }
})

if (IS_EXTENSION) {
    browser.runtime.onMessage.addListener(function(message, sender, sendResponse) {
        if (message === 'update') {
            onUrlChange(document.location.href)
        }
    });    
}

function onUrlChange (url) {
    let isLiquio = url.startsWith(LIQUIO_URL + '/page/') || url.startsWith(LIQUIO_URL + '/v/')
    let isInactive = !IS_EXTENSION && document.getElementById('liquio-bar-extension')
    let isUnavailable = isLiquio || isInactive
    let key = cleanUrl(decodeURIComponent(url))

    vm.isUnavailable = isUnavailable
    vm.urlKey = key

}

let onDomNodeInsert = (node) => {
    if (node.nodeType === Node.TEXT_NODE) {
        textNodes.push(node)
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

let updateSelection = () => {
    vm.currentSelection = window.getSelection().toString() || null
}
document.addEventListener('keyup', updateSelection)
document.addEventListener('mouseup', updateSelection)
