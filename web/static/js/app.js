var choiceComponent = Vue.component('choice', {
	template: '#choice_template',
	props: ['node'],
	data: function() {
		let self = this;
		return {
			set_value: 0.5,
			set: function (event) {
				let title = self.node.title.replace('_', ' ').replace(' ', '-')
				self.$http.post('/api/nodes/' + title + '/votes', {choice: {main: self.set_value}}).then((response) => {
					console.log(response)
					self.$http.get('/api/nodes/' + title).then((response) => {
						console.log(response)
						self.results = mapResults(response.body.data.results)
						console.log(mapResults(response.body.data.results))
					}, (response) => {
					})
				}, (response) => {
				});
			},
			remove: function (event) {
				
			}
		}
	},
	computed: {
		mean: function() {
			return this.node.results.by_keys["main"].mean
		},
		turnout: function() {
			return this.node.results.turnout_ratio
		},
		points: function() {
			if(this.node.choice_type == "time_quantity") {

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
		headers: {}
	}
})

window['vue'] = app