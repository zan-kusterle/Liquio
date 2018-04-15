import 'webextension-polyfill'
import Vue from 'vue'
import Vuex from 'vuex'
import Root from 'inject/root.vue'
import transformContent from 'inject/transform_content'
import mainCss from 'inject/main.less'
import shadowCss from 'inject/shadow.less'
import storeObject from 'inject/store/index.js'

let getElement = () => {
    let bodyElement = document.getElementsByTagName('body')[0]
    let vueElement = document.createElement('div')
    vueElement.id = IS_EXTENSION ? 'liquio-bar-extension' : 'liquio-bar'
    bodyElement.appendChild(vueElement)

    let container = vueElement
    if (document.head.createShadowRoot || document.head.attachShadow) {
        vueElement.attachShadow({mode: 'open'})
        container = vueElement.shadowRoot
    }
    
    for (let file of shadowCss) {
        let content = file[1]
        let style = document.createElement('style')
        style.innerHTML = content
        container.appendChild(style)
    }

    for (let file of mainCss) {
        let content = file[1]
        let style = document.createElement('style')
        style.innerHTML = content
        bodyElement.appendChild(style)
    }

    let innerElement = document.createElement('div')
    container.appendChild(innerElement)

    return innerElement
}

Vue.use(Vuex)

const store = new Vuex.Store(storeObject)

store.dispatch('initialize')

const vm = new Vue({
    store: store,
    el: getElement(),
    data () {
        return {
            isHidden: true,
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
        },
        viewNode (key) {
            this.$children[0].viewNode(key)
        }
    },
    render (createElement) {
        return createElement(Root, {
            props: {
                isHidden: this.isHidden,
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
store.subscribe((mutation, state) => {
    if (mutation.type === 'SET_NODE' && mutation.payload.title === vm.urlKey) {
        let node = mutation.payload
        let getNodesByText = (node, key) => {
            var result = {}
            node.references.forEach(function (reference) {
                if (reference.referenced_by_title.startsWith(key + '/')) {
                    let text = reference.referenced_by_title.substring(key.length + 1)
                    
                    if (!(text in result))
                        result[text] = []
                    result[text].push(reference)
                }
            })
            return result
        }

        if (IS_EXTENSION) {
            let reliabilityResults = node.results["Reliable-Unreliable"]
            let score = reliabilityResults ? reliabilityResults.mean : null
            browser.runtime.sendMessage({ name: 'score', score: score })
        }

        nodesByText = getNodesByText(node, vm.urlKey)

        transformContent.resetTransforms()
        for (let domNode of textNodes) {
            transformContent.transformNode(nodesByText, domNode, (activeNode, isClicked) => {
                vm.currentNode = activeNode

                if (isClicked) {
                    vm.viewNode(vm.currentNode.title)
                }
            })
        }
    }
})
    

if (IS_EXTENSION) {
    browser.runtime.onMessage.addListener(function(message, sender, sendResponse) {
        if (message.name === 'update') {
            onUrlChange(document.location.href)
        } else if (message.name === 'open') {
            vm.viewNode(vm.urlKey)
        }
    })
}

function onUrlChange (url) {
    vm.isUnavailable = !IS_EXTENSION && document.getElementById('liquio-bar-extension')
    vm.urlKey = decodeURIComponent(url).replace(/\/$/, '');
    store.dispatch('loadNode', { key: vm.urlKey, refresh: true })
}

let onDomNodeInsert = (node) => {
    if (node.nodeType === Node.TEXT_NODE) {
        textNodes.push(node)
    } else if (node.nodeName.toLowerCase() === 'a') {
    }
}

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

let walker = document.createTreeWalker(document, NodeFilter.SHOW_TEXT, null, false)
while (walker.nextNode())
    onDomNodeInsert(walker.currentNode)

window.addEventListener("hashchange", () => onUrlChange(document.location.href), false)
onUrlChange(document.location.href)

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

let updateSelection = (e) => {    
    let selection = getValidSelection()
    if (selection) {
        vm.currentSelection = selection.toString()
    } else {
        vm.currentSelection = null
    }
    
    if (e) {
        setTimeout(updateSelection, 100)
    }
}
document.addEventListener('keyup', updateSelection)
document.addEventListener('mouseup', updateSelection)

const VIDEO_NODE_SHOW_DURATION = 10
let isCurrentVideoNode = false

let intervalId = setInterval(() => {
    let videos = document.getElementsByTagName('video')
    if (videos.length > 0) {
        clearInterval(intervalId)

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
}, 100)
