let setVote = function($http, url_key, choice, cb) {
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

const resultsComponent = Vue.component('results', {
	template: '#results_template',
	props: ['node', 'resultsKey'],
	data: function() {
		return {
			results_key: this.resultsKey || 'main'
		}
	},
	computed: {
		mean: function() {
			return this.node.results && this.node.results.by_keys[this.results_key] && this.node.results.by_keys[this.results_key].mean
		},
		turnout_ratio: function() {
			return this.node.results.turnout_ratio
		},
		color: function() {
			return getColor(this.node.results && this.node.results.by_keys[this.results_key] && this.node.results.by_keys[this.results_key].mean)
		}
	}
})

const choiceForNode = function(node, results_key) {
	if(node.own_contribution) {
		if(node.choice_type == 'time_quantity') {
			let by_keys = node.own_contribution.results.by_keys
			var values = []
			for(var year in by_keys) {
				values.push({'value': by_keys[year].mean, 'year': '2000'})
			}
			return values
		} else {
			let d = node.own_contribution.results.by_keys[results_key] && node.own_contribution.results.by_keys[results_key].mean
			return [{'value': d || 0.5, 'year': '2000'}]
		}
	} else {
		return null
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
			choice[point.year] = point.value
		}
	} else {
		choice['main'] = parseFloat(self.value)
	}

	return choice
}

const ownVoteComponent = Vue.component('own-vote', {
	template: '#own_vote_template',
	props: ['node', 'resultsKey'],
	data: function() {
		let self = this
		return {
			values: choiceForNode(this.node, this.resultsKey || 'main'),
			set: function (event) {
				let choice = getCurrentChoice(self.node, self.values)
				setVote(self.$http, self.node.url_key, choice, function(new_node) {
					self.node.results = new_node.results
					self.node.own_contribution = new_node.own_contribution
				})
			},
			unset: function (event) {
				unsetVote(self.$http, self.node.url_key, function(new_node) {
					self.node.results = new_node.results
					self.node.own_contribution = null
					self.value = 0.5
				})
			},
			number_format: number_format
		}
	},
	computed: {
		turnout_ratio: function() {
			return this.node.own_contribution ? this.node.own_contribution.results.turnout_ratio : 0
		},
		color: function() {
			return getColor(parseFloat(this.values[0].value))
		}
	}
})

const nodeComponent = Vue.component('liquio-node', {
	template: '#liquio_node_template',
	props: ['node', 'resultsKey', 'votable', 'link'],
	data: function() {
		return {
			isOpen: false,
			mean: 0.5,
			set: function (event) {
				let choice_value = parseFloat(this.mean)
				Api.set(this.node.url_key, choice_value, function(new_node) {
					this.node.results = new_node.results
				})
			},
			unset: function (event) {
				Api.unset(this.node.url_key, function(new_node) {
					this.node.results = new_node.results
				})
			}
		}
	}
})

const inlineComponent = Vue.component('liquio-inline', {
	template: '#liquio_inline_template',
	props: ['node', 'referencingNode', 'referencesNode'],
	data: function() {
		return {}
	}
})

const listComponent = Vue.component('liquio-list', {
	template: '#liquio_list_template',
	props: ['nodes', 'referencingNode', 'referencesNode'],
	data: function() {
		return {}
	}
})

const calculationOptionsComponent = Vue.component('calculation-opts', {
	template: '#options_template',
	props: ['opts'],
	data: function() {
		return {}
	}
})

const fullNodeComponent = Vue.component('liquio-full', {
	template: '#liquio_full_template',
	props: ['node'],
	data: function() {
		return {
			optionsOpen: false,
			inverseReferencesOpen: false,
			referencesOpen: true
		}
	}
})

var app = new Vue({
	el: '#app',
	components: {
		//'date-picker': datepickerComponent,
		'liquio-node': nodeComponent,
		'liquio-inline': inlineComponent,
		'liquio-list': listComponent,
		'results': resultsComponent,
		'own-vote': ownVoteComponent,
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