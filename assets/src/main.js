/* global IS_EXTENSION, chrome */

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
			isUnavailable: false,
			activeTitle: null,
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
				isUnavailable: this.isUnavailable,
				activeTitle: this.activeTitle,
				currentSelection: this.currentSelection,
				currentVideoTime: this.currentVideoTime
			}
		})
	},
	computed: {
		captureKeyboard () {
			let root = this.$children[0]
			return root.isAnnotationTitleInputShown || root.currentTitle && root.dialogVisible
		}
	}
})

window.addEventListener('keydown', (e) => {
	if (vm.captureKeyboard) {
		e.stopPropagation()
	}
}, true)

let titlesByText = {}
let canUpdateHighlights = true
let transformedTexts = []

function updateHighlights () {
	for (let text in titlesByText) {
		if (!transformedTexts.includes(text)) {
			let title = titlesByText[text][0]
			let span = transformContent.transformText(text)

			if (span) {
				transformedTexts.push(text)
				span.style.backgroundColor = 'rgba(255, 255, 0, 0.7)'
				span.style.cursor = 'pointer'
	
				span.addEventListener('mouseover', () => {
					vm.activeTitle = title
				})
				span.addEventListener('mouseout', () => {
					vm.activeTitle = null
				})
	
				span.addEventListener('click', () => {
					vm.activeTitle = title
	
					store.dispatch('setCurrentReferenceTitle', null)
					store.dispatch('setCurrentTitle', title)
					vm.toggle()
				})
			}
		}
	}
}

setInterval(() => {
	if (canUpdateHighlights) {
		canUpdateHighlights = false		
		updateHighlights()
	}
}, 1000)

updateHighlights()

store.subscribe((mutation, state) => {
	if (mutation.type === 'SET_NODE' && mutation.payload.title === state.currentPage) {
		let node = mutation.payload
		let getTitlesByText = (node, key) => {
			var result = {}
			node.references.forEach(function (reference) {
				if (reference.byTitle && reference.byTitle.toLowerCase().startsWith(key.toLowerCase() + '/')) {
					let text = reference.byTitle.substring(key.length + 1)
                    
					if (!(text in result))
						result[text] = []
					result[text].push(reference.title)
				}
			})
			return result
		}

		if (IS_EXTENSION) {
			let reliabilityResults = node.results['Reliable-Unreliable']
			let score = reliabilityResults ? reliabilityResults.mean : null
			chrome.runtime.sendMessage({ name: 'score', score: score })
		}

		titlesByText = getTitlesByText(node, store.state.currentPage)

		canUpdateHighlights = true
	}
})

if (IS_EXTENSION) {
	chrome.runtime.onMessage.addListener(function(message) {
		if (message.name === 'update') {
			onUrlChange(document.location.href)
			setTimeout(() => {
				onUrlChange(document.location.href)
			}, 1000)
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
	let obs = new MutationObserver(() => {
		canUpdateHighlights = true
	})
	obs.observe(document, {
		childList: true,
		subtree: true
	})
} else if (eventListenerSupported) {
	document.addEventListener('DOMNodeInserted', () => {
		canUpdateHighlights = true
	}, false)
}

window.addEventListener('hashchange', () => onUrlChange(document.location.href), false)
onUrlChange(document.location.href)

document.addEventListener('keyup', e => {
	if (e.keyCode === 8) {
		store.dispatch('navigateBack')
	}
})

const VIDEO_NODE_SHOW_DURATION = 10
let isCurrentVideoNode = false

let intervalId = setInterval(() => {
	let videos = document.getElementsByTagName('video')
	if (videos.length === 1) {
		clearInterval(intervalId)

		let video = videos[0]

		setInterval(() => {
			let closestTime = null
			let closestTitle = null
			for (let text in titlesByText) {
				let parts = text.split(':')
				if (parts.length === 2) {
					let minutes = parseInt(parts[0])
					let seconds = parseInt(parts[1])
					let time = isNaN(minutes) || isNaN(seconds) ? null : minutes * 60 + seconds

					let delta = video.currentTime - time
					if (delta >= 0 && delta < VIDEO_NODE_SHOW_DURATION && (closestTime === null || delta < closestTime)) {
						closestTime = delta
						closestTitle = titlesByText[text][0]
					}
				}
			}

			vm.currentVideoTime = video.currentTime
			if (closestTitle) {
				vm.activeTitle = closestTitle
				isCurrentVideoNode = true
			} else if (isCurrentVideoNode) {
				vm.activeTitle = null
			}
		}, 100)
	}
}, 100)
