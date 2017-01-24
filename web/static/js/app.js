var choiceComponent = Vue.component('choice', {
	template: '#choice_template',
	props: ['node'],
	data: function() {
		let self = this;
		return {
			latest_node: self.node,
			set_value: 0.5,
			set: function (event) {
				let title = self.node.title.replace('_', ' ').replace(' ', '-')
				let choice = {'main': parseFloat(self.set_value)}

				self.$http.post('/api/nodes/' + title + '/votes', {choice: choice}, {
					headers: {
						'authorization': 'Bearer ' + token
					}
				}).then((response) => {
					let new_node = response.body.data
					self.latest_node.results = new_node.results
				}, (response) => {
				});
			},
			remove: function (event) {
				
			}
		}
	},
	computed: {
		mean: function() {
			return this.latest_node.results.by_keys["main"].mean
		},
		turnout: function() {
			return this.latest_node.results.turnout_ratio
		},
		points: function() {
			if(this.latest_node.choice_type == "time_quantity") {

			} else {
				return [];
			}
		}
	}
})

var app = new Vue({
	el: '#app',
	components: {'choice': choiceComponent},
	data: {
		message: 'Hello Vue.js!',
		mainNode: mainNode
	},
	http: {
		root: '/api',
		headers: {
			'Authorization': 'Bearer ' + token
		}
	}
})

window['vue'] = app