import Vue from 'vue'
import ElementUI from 'element-ui';
import locale from 'element-ui/lib/locale/lang/en'
import VueRouter from 'vue-router'

import 'element-ui/lib/theme-default/index.css'
require('vue2-animate/dist/vue2-animate.min.css')

Vue.use(VueRouter)
Vue.use(ElementUI, {locale})

import loginComponent from '../vue/login.vue'
import identityComponent from '../vue/identity-full.vue'
import nodeComponent from '../vue/liquio-full.vue'
import referenceComponent from '../vue/reference-full.vue'

const routes = [
	{ path: '/login', component: loginComponent },
	{ path: '/identities/:username', component: identityComponent },
	{ path: '/', component: nodeComponent }, { path: '/:urlKey', component: nodeComponent },
	{ path: '/:urlKey/references/:referenceUrlKey', component: referenceComponent },
]

const router = new VueRouter({
	mode: 'history',
	routes: routes
})

const app = new Vue({
	router: router,
	components: {},
	data: defaultVueData
}).$mount('#app')