import Vue from 'vue'
import Vuex from 'vuex'
import ElementUI from 'element-ui';
import locale from 'element-ui/lib/locale/lang/en'
import VueRouter from 'vue-router'

import 'element-ui/lib/theme-default/index.css'
require('vue2-animate/dist/vue2-animate.min.css')

Vue.use(Vuex)
Vue.use(VueRouter)
Vue.use(ElementUI, {locale})
import { sync } from 'vuex-router-sync'
import loginComponent from '../vue/login.vue'
import finishLoginComponent from '../vue/finish-login.vue'
import identityComponent from '../vue/identity-full.vue'
import nodeComponent from '../vue/liquio-full.vue'
import referenceComponent from '../vue/reference-full.vue'

let store = require('store.js').default

const routes = [
	{ path: '/', component: nodeComponent },
	{ path: '/login', component: loginComponent },
	{ path: '/login/:token/new', component: finishLoginComponent },
	{ path: '/identities/:username', component: identityComponent },
	{ name: 'search', path: '/search/:query', component: nodeComponent },
	{ path: '/:key/references', component: referenceComponent },
	{ path: '/:key/references/:referenceKey', component: referenceComponent },
	{ path: '/:key', component: nodeComponent }
]

const router = new VueRouter({
	mode: 'history',
	routes: routes
})

sync(store, router)

var bus = new Vue()

const app = new Vue({
	router: router,
	store: store,
	components: {},
	data: {bus: bus}
}).$mount('#app')