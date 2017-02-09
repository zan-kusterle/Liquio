import Vue from 'vue'
import ElementUI from 'element-ui';
import locale from 'element-ui/lib/locale/lang/en'
import VueRouter from 'vue-router'

import 'element-ui/lib/theme-default/index.css'

Vue.use(VueRouter)
Vue.use(ElementUI, {locale})

require('vue2-animate/dist/vue2-animate.min.css')

let getNode = function($http, url_key, cb) {
	return $http.get('/api/nodes/' + url_key).then((response) => {
		cb(transformNode(response.body.data))
	}, (response) => {
	})
}

const getCurrentChoice = function(node, values) {
	var choice = {}

	if(node.choice_type == 'time_quantity') {
		for(var i in values) {
			let point = values[i]
			if(point.value != '' && point.year != '')
				choice[point.year] = point.value
		}
	} else {
		choice['main'] = parseFloat(values[0].value)
	}

	return choice
}

import fullComponent from '../vue/liquio-full.vue'
import exploreListComponent from '../vue/explore-list.vue'
import referenceComponent from '../vue/reference-full.vue'

const routes = [
	{ path: '/', component: exploreListComponent },
	{ path: '/:urlKey', component: fullComponent },
	{ path: '/:urlKey/references/:referenceUrlKey', component: referenceComponent },
]

const router = new VueRouter({
	mode: 'history',
	routes: routes
})

const app = new Vue({
	router: router,
	components: {},
	data: defaultVueData,
	http: {
		root: '/api',
		headers: {
			'Authorization': 'Bearer ' + token
		}
	}
}).$mount('#app')