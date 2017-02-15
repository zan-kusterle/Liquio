<template>
<div class="score-box" v-bind:style="{'background-color': color}" v-if="choice_type == 'probability'">
	<div class="range">
		<el-slider v-model="values[0].value" style="width: 90%; margin: 0 auto;" />
	</div>
	<div class="number">
		<span class="number-value">{{ Math.round(values[0].value) }}</span><span class="percent">%</span>
	</div>
	<div class="subtext">{{ Math.round(turnout_ratio * 100) }}% turnout</div>

	<div class="links vote-links">
		<a class="vote-action" v-on:click="set"><i class="el-icon-circle-check" style="margin-right: 6px;"></i> Vote</a>
		<a class="vote-action" v-if="node.own_contribution" v-on:click="unset" style="border-left: 1px solid rgba(0,0,0,0.1);">Remove <i class="el-icon-circle-close" style="margin-left: 5px;"></i></a>
	</div>
</div>

<div class="score-box" v-else-if="choice_type == 'quantity'">
	<div class="number">
		<input class="number-value" v-model="values[0].value" style="width: 140px; text-align: center;"></input>
	</div>
	<div class="subtext">{{ Math.round(turnout_ratio * 100) }}% turnout</div>

	<div class="links vote-links">
		<a class="vote-action" v-on:click="set"><i class="fa fa-check" aria-hidden="true" style="margin-right: 2px;"></i> Vote</a>
		<a class="vote-action" v-on:click="unset" style="border-left: 1px solid rgba(0,0,0,0.1);">Remove <i class="fa fa-remove" aria-hidden="true" style="margin-left: 2px;"></i></a>
	</div>
</div>

<div class="score-box" v-else-if="choice_type == 'time_quantity'">
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
let Api = require('api.js')

const choiceForNode = function(node, results_key, choiceType) {
	if(node.own_contribution) {
		if(choiceType == 'time_quantity') {
			let by_keys = node.own_contribution.results.by_keys
			let values = []
			for(let year in by_keys) {
				values.push({'value': by_keys[year].mean, 'year': year})
			}
			return values
		} else {
			let d = node.own_contribution.results.by_keys[results_key] && node.own_contribution.results.by_keys[results_key].mean
			return [{'value': (d || 0.5) * 100, 'year': ''}]
		}
	} else {
		return []
	}
}

const getCurrentChoice = function(node, values, resultsKey, choiceType) {
	let choice = {}

	if(choiceType == 'time_quantity') {
		for(let i in values) {
			let point = values[i]
			if(point.value != '' && point.year != '')
				choice[point.year] = point.value
		}
	} else {
		choice[resultsKey] = parseFloat(values[0].value) / 100
	}

	return choice
}

export default {
	props: ['node', 'resultsKey', 'referenceKey', 'choiceType'],
	data: function() {
		let self = this
		let choiceType = self.choiceType || self.node.choice_type

		function updateInputs() {
			if(choiceType == 'time_quantity') {
				let last_value = self.values[self.values.length - 1]
				let empty_index = self.values.length
				for(let i = self.values.length - 1; i >= 0; i--) {
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
		}

		setTimeout(() => updateInputs(), 0)

		let choiceValues = choiceForNode(this.node, this.resultsKey || 'main', choiceType)
		choiceValues.push({'value': 50, 'year': ''})

		return {
			choice_type: choiceType,
			values: choiceValues,
			set: function(event) {
				let choice = getCurrentChoice(self.node, self.values, self.resultsKey || 'main', choiceType)
				Api.setVote(self.node.url_key, self.referenceKey, choice, function(node) {
					self.$root.bus.$emit('change')
				})
			},
			unset: function(event) {
				Api.unsetVote(self.node.url_key, self.referenceKey, function(node) {
					self.values = [{'value': '', 'year': ''}]
					self.$root.bus.$emit('change')
				})
			},
			keyup: function(event) {
				updateInputs()
			},
			number_format: Api.formatNumber
		}
	},
	computed: {
		turnout_ratio: function() {
			return this.node.own_contribution ? this.node.own_contribution.results.turnout_ratio : 0
		},
		color: function() {
			return Api.getColor(parseFloat(this.values[0].value / 100))
		}
	}
}
</script>

<style scoped>
	.score-box {
		display: block;
		margin: 0 auto;
		width: 220px;
		padding: 0px;
		text-align: center;
		border: 1px solid rgba(0, 0, 0, 0.1);
		background-color: #ddd;
	}

	.number {
		font-size: 28px;
		line-height: 24px;
	}

	.subtext {
		font-weight: bold;
		font-size: 12px;
	}

	.vote-links {
		margin-top: 10px;
		border-top: 1px solid rgba(0, 0, 0, 0.1);
		padding-top: 2px;
	}

	.vote-action {
		width: 46%;
		font-size: 13px;
		display: inline-block;
		text-align: center;
		line-height: 30px;
	}
</style>