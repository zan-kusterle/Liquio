import 'webextension-polyfill'
import Vue from 'vue'
import Vuex from 'vuex'
import Root from 'vue/root.vue'
import transformContent from 'transform_content'
import mainCss from 'main.less'
import shadowCss from 'shadow.less'
import storeObject from 'store/index.js'

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
            currentNode: null,
            currentSelection: null,
            currentVideoTime: null,
        }
    },
    methods: {
        toggle () {
            let root = this.$children[0]
            root.dialogVisible ? root.close () : root.open()
        }
    },
    render (createElement) {
        return createElement(Root, {
            props: {
                isHidden: this.isHidden,
                isUnavailable: this.isUnavailable,
                currentNode: this.currentNode,
                currentSelection: this.currentSelection,
                currentVideoTime: this.currentVideoTime
            }
        })
    }
})

let nodesByText = {}
let textNodes = []

let transformDomNode = (domNode) => {
    transformContent.transformNode(nodesByText, domNode, (activeNode, isClicked) => {
        if (activeNode) {
            vm.currentNode = activeNode

            if (isClicked) {
                store.dispatch('setCurrentReferenceTitle', null)
                store.dispatch('setCurrentTitle', activeNode.title)
                vm.toggle()
            }
        } else {
            vm.currentNode = null
        }
    })
}

store.subscribe((mutation, state, dispatch) => {
    if (mutation.type === 'SET_NODE' && mutation.payload.title === state.currentPage) {
        let node = mutation.payload
        let getNodesByText = (node, key) => {
            var result = {}
            node.references.forEach(function (reference) {
                if (reference.referenced_by_title.toLowerCase().startsWith(key.toLowerCase() + '/')) {
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
            if (IS_EXTENSION) {
                (chrome && chrome.runtime || browser.runtime).sendMessage({ name: 'score', score: score })
            }
        }

        nodesByText = getNodesByText(node, store.state.currentPage)

        transformContent.resetTransforms()
        for (let domNode of textNodes) {
            let didChange = transformDomNode(domNode)

        }

        let index = textNodes.length - 1
        let transformWithTimeouts = () => {
            while (index >= 0 && index < textNodes.length) {
                transformDomNode(textNodes[index])
                index --
            }
            index --
        }
        transformWithTimeouts()
    } else if (mutation.type === 'SET_IS_SIGN_WINDOW_OPEN' && mutation.payload === false) {
        // TODO get refresh titles from store
        let currentTitle = state.currentTitle
        let currentReferenceTitle = state.currentReferenceTitle
        setTimeout(() => {
            store.dispatch('loadNode', { key: state.currentPage })
            if (currentTitle)
                store.dispatch('loadNode', { key: currentTitle })
            if (currentReferenceTitle)
                store.dispatch('loadNode', { key: currentReferenceTitle })
        }, 500)
    }
})
    

if (IS_EXTENSION) {
    browser.runtime.onMessage.addListener(function(message) {
        if (message.name === 'update') {
            onUrlChange(document.location.href)
        } else if (message.name === 'open') {
            store.dispatch('setCurrentReferenceTitle', null)
            store.dispatch('setCurrentTitle', store.state.currentPage)
            vm.toggle()
        }
        return false
    })
}

function onUrlChange (url) {
    vm.isUnavailable = !IS_EXTENSION && document.getElementById('liquio-bar-extension')
    store.dispatch('setCurrentPage', decodeURIComponent(url).replace(/\/$/, ''))
}

let MutationObserver = window.MutationObserver || window.WebKitMutationObserver
let eventListenerSupported = window.addEventListener

if (MutationObserver) {
    let obs = new MutationObserver(function (mutations, observer) {
        mutations.forEach((mutation) => {
            mutation.addedNodes.forEach((node) => {
                if (node.nodeType === Node.TEXT_NODE) {
                    textNodes.push(node)
                    transformDomNode(node)
                }
            })
            mutation.removedNodes.forEach((node) => {
                let index = textNodes.indexOf(node)
                if (index >= 0)
                    textNodes.splice(index, 1)
            })
        })
    })
    obs.observe(document, {
        childList: true,
        subtree: true
    })
} else if (eventListenerSupported) {
    document.addEventListener('DOMNodeInserted', function (e) {
        if (e.target.nodeType === Node.TEXT_NODE) {
            textNodes.push(e.target)
            transformDomNode(e.target)
        }
    }, false)
}

let walker = document.createTreeWalker(document, NodeFilter.SHOW_TEXT, null, false)
while (walker.nextNode()) {
    if (walker.currentNode.nodeType === Node.TEXT_NODE) {
        textNodes.push(walker.currentNode)
        transformDomNode(walker.currentNode)
    }
}

window.addEventListener("hashchange", () => onUrlChange(document.location.href), false)
onUrlChange(document.location.href)

document.addEventListener('keyup', e => {
    if (e.keyCode === 8) {
        store.dispatch('navigateBack')
    }
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
    if (videos.length === 1) {
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
