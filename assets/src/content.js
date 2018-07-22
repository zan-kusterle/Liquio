/* global IS_EXTENSION */

import Vue from 'vue'
import Vuex from 'vuex'
import { Autocomplete } from 'element-ui'
import Root from 'components/root.vue'
import mainCss from 'components/css/main.less'
import shadowCss from 'components/css/shadow.less'
import storeObject from 'store/index.js'

// Prepare container element
let bodyElement = document.getElementsByTagName('body')[0]
let vueElement = document.createElement('div')
vueElement.id = IS_EXTENSION ? 'liquio-bar-extension' : 'liquio-bar'
bodyElement.appendChild(vueElement)

let container = vueElement
if (IS_EXTENSION && (document.head.createShadowRoot || document.head.attachShadow)) {
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

// Hack to make autocomplete work with shadow DOM
let handleFocus = Autocomplete.methods.handleFocus
Autocomplete.methods.handleFocus = function (event) {
	this.lastFocusTime = Date.now()
	handleFocus.bind(this)(event)
}

let close = Autocomplete.methods.close
Autocomplete.methods.close = function (event) {
	let canClose = true
	if (this.lastFocusTime && Date.now() - this.lastFocusTime < 500)
		canClose = false

	if (canClose)
		close.bind(this)(event)
}

// Initialize
Vue.use(Vuex)

const store = new Vuex.Store(storeObject)

store.dispatch('initialize')
	
new Vue({
	store: store,
	el: innerElement,
	render (createElement) {
		return createElement(Root)
	}
})




// Development
store.dispatch('annotate/setDefinition', {
	title: 'Something',
	unit: 'Unreliable-Reliable'
})
store.dispatch('annotate/loadNode', store.state.annotate.definition)
store.dispatch('annotate/openDialog')
