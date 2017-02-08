<template>
<div class="score-box" v-bind:style="{'background-color': color}" v-if="this.node.choice_type == 'probability'">
	<form class="data" action="<%= @conn.request_path %>/vote" method="POST">
		<div class="range">
			<input type="range" name="choice" min="0" max="1" step="any" v-model="values[0].value" style="width: 90%; margin: 0 auto;" />
		</div>
		<div class="number">
			<span class="number-value">{{ Math.round((values[0].value || 0.5) * 100) }}</span><span class="percent">%</span>
		</div>
		<div class="subtext">{{ Math.round(turnout_ratio * 100) }}% turnout</div>
	</form>

	<div class="links vote-links">
		<a class="vote-action" v-on:click="set"><i class="fa fa-check" aria-hidden="true" style="margin-right: 2px;"></i> Vote</a>
		<a class="vote-action" v-on:click="unset" style="border-left: 1px solid rgba(0,0,0,0.1);">Remove <i class="fa fa-remove" aria-hidden="true" style="margin-left: 2px;"></i></a>
	</div>
</div>

<div class="score-box" v-else-if="this.node.choice_type == 'quantity'">
	<form class="data" action="<%= @conn.request_path %>/vote" method="POST">
		<div class="number">
			<input class="number-value" v-model="values[0].value" style="width: 140px; text-align: center;"></input>
		</div>
		<div class="subtext">{{ Math.round(turnout_ratio * 100) }}% turnout</div>
	</form>

	<div class="links vote-links">
		<a class="vote-action" v-on:click="set"><i class="fa fa-check" aria-hidden="true" style="margin-right: 2px;"></i> Vote</a>
		<a class="vote-action" v-on:click="unset" style="border-left: 1px solid rgba(0,0,0,0.1);">Remove <i class="fa fa-remove" aria-hidden="true" style="margin-left: 2px;"></i></a>
	</div>
</div>

<div class="score-box" v-else-if="this.node.choice_type == 'time_quantity'">
	<form class="data" action="<%= @conn.request_path %>/vote" method="POST">
		<ul class="time-series-list">
			<li>
				<div class="number">
					<span class="number-value"><b>Year</b></span>
					<span class="number-value"><b>Value</b></span>
				</div>
			</li>
			<li v-for="point in values">
				<div class="number">
					<input class="number-value" v-model="point.year" v-on:keyup="keyup" />
					<input class="number-value" v-model="point.value" v-on:keyup="keyup" />
				</div>
			</li>
		</ul>
		<div class="subtext">{{ Math.round(turnout_ratio * 100) }}% turnout</div>
	</form>

	<div class="links vote-links">
		<a class="vote-action" v-on:click="set"><i class="fa fa-check" aria-hidden="true" style="margin-right: 2px;"></i> Vote</a>
		<a class="vote-action" v-on:click="unset" style="border-left: 1px solid rgba(0,0,0,0.1);">Remove <i class="fa fa-remove" aria-hidden="true" style="margin-left: 2px;"></i></a>
	</div>
</div>
</template>

<script>
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


const getColor = function(mean) {
	if(mean == null) return "#ddd"
	if(mean < 0.25)
		return "rgb(255, 164, 164)"
	else if(mean < 0.75)
		return "rgb(249, 226, 110)"
	else
		return "rgb(140, 232, 140)"
}

export default {
	props: ['node', 'resultsKey'],
	data: function() {
		let self = this

		function updateInputs() {
			let last_value = self.values[self.values.length - 1]
			var empty_index = self.values.length
			for(var i = self.values.length - 1; i >= 0; i--) {
				let value = self.values[i]
				if(value.value == '' && value.year == '')
					empty_index = i
			}
			if(empty_index >= self.values.length) {
				self.values.push({'value': '', 'year': ''})
			} else {
				self.values = self.values.slice(0, empty_index + 1)
			}
		}

		setTimeout(() => updateInputs(), 0)

		let choiceValues = choiceForNode(this.node, this.resultsKey || 'main')
		choiceValues.push([{'value': '', 'year': ''}])

		return {
			values: choiceValues,
			set: function(event) {
				let choice = getCurrentChoice(self.node, self.values)
				setVote(self.$http, self.node.url_key, choice, function(new_node) {
					self.node.results = new_node.results
					self.node.own_contribution = new_node.own_contribution
					self.node.embed_html = new_node.embed_html
				})
			},
			unset: function(event) {
				unsetVote(self.$http, self.node.url_key, function(new_node) {
					self.node.results = new_node.results
					self.node.own_contribution = null
					self.node.embed_html = new_node.embed_html
					self.values = [{'value': '', 'year': ''}]
				})
			},
			keyup: function(event) {
				updateInputs()
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
}
</script>