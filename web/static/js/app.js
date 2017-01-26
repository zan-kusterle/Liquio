const getColor = function(mean) {
	if(mean < 0.25)
		return "rgb(255, 164, 164)"
	else if(mean < 0.75)
		return "rgb(249, 226, 110)"
	else
		return "rgb(140, 232, 140)"
}

const choiceComponent = Vue.component('choice', {
	template: '#choice_template',
	props: ['node'],
	data: function() {
		let self = this;
		return {
			vote_shown: false,
			latest_node: self.node,
			set_value: 0.5,
			set: function (event) {
				let choice_value = parseFloat(self.set_value)

				self.$http.post('/api/nodes/' + self.node.url_key + '/votes', {choice: {'main': choice_value}}, {
					headers: {
						'authorization': 'Bearer ' + token
					}
				}).then((response) => {
					let new_node = response.body.data
					self.latest_node.results = new_node.results
					self.vote_shown = false
				}, (response) => {
				});
			},
			unset: function (event) {
				self.$http.delete('/api/nodes/' + self.node.url_key + '/votes', {
					headers: {
						'authorization': 'Bearer ' + token
					}
				}).then((response) => {
					let new_node = response.body.data
					self.latest_node.results = new_node.results
					self.vote_shown = false
				}, (response) => {
				});
			}
		}
	},
	computed: {
		mean: function() {
			return this.latest_node.results && this.latest_node.results.by_keys["main"] && this.latest_node.results.by_keys["main"].mean
		},
		turnout: function() {
			return this.latest_node.results.turnout_ratio
		},
		points: function() {
			if(this.latest_node.choice_type == "time_quantity") {

			} else {
				return [];
			}
		},
		style: function() {
			if(this.latest_node.results && this.latest_node.results.by_keys["main"] && this.latest_node.choice_type == "probability") {
				return "background-color: " + getColor(this.latest_node.results.by_keys["main"].mean) + ";"
			} else {
				return "background-color: #ddd;"
			}
		},
		set_style: function() {
			if(this.latest_node.choice_type == "probability") {
				return "background-color: " + getColor(this.set_value) + ";"
			} else {
				return "background-color: #ddd;"
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