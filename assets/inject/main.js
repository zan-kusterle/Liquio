import 'webextension-polyfill'
import { cleanUrl } from 'shared/votes'
import * as Api from 'shared/api_client'
import { usernameFromPublicKey } from 'shared/identity'
import Vue from 'vue'
import Bar from 'inject/bar.vue'
import { decodeBase64 } from 'shared/utils';
import transformNode from 'inject/transform_content'
import css from 'inject/main.less'

let getElement = () => {
    let vueElement = document.createElement('div')
    vueElement.id = IS_EXTENSION ? 'liquio-bar-extension' : 'liquio-bar'
    vueElement.attachShadow({mode: 'open'})
    document.getElementsByTagName('body')[0].appendChild(vueElement)
    vueElement.shadowRoot.appendChild(document.createElement('div'))
    for (let file of css) {
        let content = file[1]
        let style = document.createElement('style')
        style.innerHTML = content
        vueElement.shadowRoot.appendChild(style)
    }
    return vueElement.shadowRoot.firstChild
}

const vm = new Vue({
    el: getElement(),
    data () {
        return {
            isUnavailable: false,
            urlKey: null,
            currentNode: null,
            currentSelection: null,
            currentVideoTime: null,
        }
    },
    methods: {
        startVoting () {
            this.$children[0].startVoting()
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

let nodesByText = {}
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

    nodesByText = getNodesByText(node, vm.urlKey)

    let overrideByClickOnlyTimeoutId = null
    let onClickOnlyTime
    for (let domNode of textNodes) {
        transformNode(nodesByText, domNode, (activeNode, isClicked) => {
            if (overrideByClickOnlyTimeoutId === null || isClicked) {
                vm.currentNode = activeNode
            }
            if (isClicked) {
                overrideByClickOnlyTimeoutId = setTimeout(() => {
                    clearTimeout(overrideByClickOnlyTimeoutId)
                    overrideByClickOnlyTimeoutId = null
                }, 3 * 1000)
            }
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

const voteIconSvg = `<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" viewBox="0 0 100 40">
<line x1="0" y1="20" x2="100" y2="20" style="stroke: #00a9e1; stroke-width: 6;"></line>

<circle cx="20" cy="20" r="20" fill="#00a9e1"></circle>
<circle cx="80" cy="20" r="20" fill="#00a9e1"></circle>
</svg>`

let icon = document.createElement('div')
icon.innerHTML = voteIconSvg
icon.style.display = 'inline-block'
icon.style.position = 'fixed'
icon.style.paddingTop = '20px'
icon.style.color = 'red'
icon.style.width = '30px'
icon.style.height = '30px'
icon.addEventListener('mousedown', (e) => {
    vm.startVoting()
    window.getSelection().removeAllRanges()
    icon.remove()
})

let getValidSelection = () => {
    let selection = window.getSelection()
    if (selection.anchorNode) {
        if (selection.isCollapsed)
            return null
        if (vm.$el.contains(selection.anchorNode))
            return null

        return selection
    } else {
        return null
    }
}

let updateSelection = () => {
    icon.remove()
    
    let selection = getValidSelection()
    if (selection) {
        let range = selection.getRangeAt(0)

        let replacementNode = selection.anchorNode.splitText(Math.min(range.startOffset, range.endOffset))

        selection.anchorNode.parentNode.insertBefore(icon, replacementNode)

        vm.currentSelection = selection.toString()
    } else {
        vm.currentSelection = null
    }
}
document.addEventListener('keyup', updateSelection)
document.addEventListener('mouseup', updateSelection)

const VIDEO_NODE_SHOW_DURATION = 10
let isCurrentVideoNode = false

setTimeout(() => {
    let videos = document.getElementsByTagName('video')
    if (videos.length > 0) {
        let video = videos[0]

        setInterval(() => {
            let closestTime = null
            let closestNode = null
            for (let text in nodesByText) {
                let parts = text.split(':')
                if (parts.length === 2) {
                    let minutes = parseInt(parts[0])
                    let seconds = parseInt(parts[1])
                    let time = isNaN(minutes) || isNaN(seconds) ? null : minutes * 60 + seconds

                    let delta = video.currentTime - time
                    if (delta >= 0 && delta < VIDEO_NODE_SHOW_DURATION && (closestTime === null || delta < closestTime)) {
                        closestTime = delta
                        closestNode = nodesByText[text][0]
                    }
                }
            }

            vm.currentVideoTime = video.currentTime
            if (closestNode) {
                vm.currentNode = closestNode
                isCurrentVideoNode = true
            } else if (isCurrentVideoNode) {
                vm.currentNode = null
            }
        }, 100)
    }
}, 500)
