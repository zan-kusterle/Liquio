import Vue from 'vue'
import ElementUI from 'element-ui';
import locale from 'element-ui/lib/locale/lang/en'
import VueRouter from 'vue-router'

import 'element-ui/lib/theme-default/index.css'

Vue.use(VueRouter)
Vue.use(ElementUI, {locale})

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


import resultsComponent from '../vue/results.vue'
import fullComponent from '../vue/liquio-full.vue'
import nodeComponent from '../vue/liquio-node.vue'
import inlineComponent from '../vue/liquio-inline.vue'
import listComponent from '../vue/liquio-list.vue'
import ownVoteComponent from '../vue/own-vote.vue'
import getReferenceComponent from '../vue/get-reference.vue'
import referenceComponent from '../vue/reference-full.vue'
import calculationOptionsComponent from '../vue/calculation-options.vue'




const Reference = { template: '<div>bar</div>' }


// 2. Define some routes
// Each route should map to a component. The "component" can
// either be an actual component constructor created via
// Vue.extend(), or just a component options object.
// We'll talk about nested routes later.
const routes = [
	{ path: '/', component: listComponent },
	{ path: '/:urlKey', component: fullComponent },
	{ path: '/:urlKey/references/:referenceUrlKey', component: referenceComponent },
]

// 3. Create the router instance and pass the `routes` option
// You can pass in additional options here, but let's
// keep it simple for now.
const router = new VueRouter({
  routes // short for routes: routes
})


const app = new Vue({
	router: router,
	components: {
		'liquio-full': fullComponent,
		'liquio-node': nodeComponent,
		'liquio-inline': inlineComponent,
		'liquio-list': listComponent,
		'results': resultsComponent,
		'own-vote': ownVoteComponent,
		'get-reference': getReferenceComponent,
		'calculation-opts': calculationOptionsComponent
	},
	data: defaultVueData,
	http: {
		root: '/api',
		headers: {
			'Authorization': 'Bearer ' + token
		}
	}
}).$mount('#app')