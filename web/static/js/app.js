import Vue from 'vue'
import ElementUI from 'element-ui';
import locale from 'element-ui/lib/locale/lang/en'
import css from 'element-ui/lib/theme-default/index.css'

Vue.use(ElementUI, {locale})

function setVote($http, url_key, choice, cb) {
	for(var key in choice) {
		choice[key + ''] = parseFloat(choice[key])
	}
	return $http.post('/api/nodes/' + url_key + '/votes', {choice: choice}, {
		headers: {
			'authorization': 'Bearer ' + token
		}
	}).then((response) => {
		cb(transformVote(response.body.data))
	}, (response) => {
	})
}

let unsetVote = function($http, url_key, cb) {
	return $http.delete('/api/nodes/' + url_key + '/votes', {
		headers: {
			'authorization': 'Bearer ' + token
		}
	}).then((response) => {
		cb(transformVote(response.body.data))
	}, (response) => {
	})
}

let transformVote = function(node) {
	node.default_results = node.results && node.results.by_keys['main'] ? node.results.by_keys['main'].mean : null
	return node
}

const getColor = function(mean) {
	if(mean == null) return "#ddd"
	if(mean < 0.25)
		return "rgb(255, 164, 164)"
	else if(mean < 0.75)
		return "rgb(249, 226, 110)"
	else
		return "rgb(140, 232, 140)"
}


const choiceForNode = function(node, results_key) {
	if(node.own_contribution) {
		if(node.choice_type == 'time_quantity') {
			let by_keys = node.own_contribution.results.by_keys
			var values = []
			for(var year in by_keys) {
				values.push({'value': by_keys[year].mean, 'year': year})
			}
			return values
		} else {
			let d = node.own_contribution.results.by_keys[results_key] && node.own_contribution.results.by_keys[results_key].mean
			return [{'value': d || 0.5, 'year': year}]
		}
	} else {
		return []
	}
}

const number_format = function(number) {
	return Math.round(number * 10) / 10
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
import nodeComponent from '../vue/liquio-node.vue'
import inlineComponent from '../vue/liquio-inline.vue'
import listComponent from '../vue/liquio-list.vue'
import ownVoteComponent from '../vue/own-vote.vue'
import getReferenceComponent from '../vue/get-reference.vue'
import calculationOptionsComponent from '../vue/calculation-options.vue'





const getUrlKey = function(title, choice_type) {
	return (title + ' ' + choice_type).replace(/ /g, '-')
}

var app = new Vue({
	el: '#app',
	components: {
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
})

window['vue'] = app