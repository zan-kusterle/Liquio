<template>
<div>
	<div class="score-box" v-if="this.node.choice_type == 'probability'" v-bind:style="{'background-color': this.color}">
		<div class="data">
			<div class="number" v-if="turnout_ratio > 0">
				<span class="number-value">{{ Math.round(mean * 100) }}</span><span class="percent">%</span>
			</div>
			<div class="number" v-if="turnout_ratio == 0">?</div>
			<div class="subtext">{{ Math.round(turnout_ratio * 100) }}% turnout</div>
		</div>
	</div>

	<div class="score-box" v-else-if="this.node.choice_type == 'quantity'">
		<div class="data">
			<div class="number" v-if="turnout_ratio > 0">
				<span class="number-value">{{ Math.round(mean) }}</span>
			</div>
			<div class="number" v-if="turnout_ratio == 0">?</div>
			<div class="subtext">{{ Math.round(turnout_ratio * 100) }}% turnout</div>
		</div>
	</div>

	<div v-else-if="this.node.choice_type == 'time_quantity'">
		<div v-html="this.node.embed_html" style="width: 100%; height: 250px;"></div>
		<div class="data">
			<div class="subtext">{{ Math.round(turnout_ratio * 100) }}% turnout</div>
		</div>
	</div>
</div>
</template>

<script>
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
}
</script>

<style scoped>

	.score-container {
		margin-top: 30px;
		width: 100%;
	}
	.score-box {
			display: block;
		}
		.chart-turnout {
			font-size: 15px;
			margin-bottom: 20px;
		}



		.score-box {
	margin: 0 auto;
	width: 220px;
	padding: 0px;
	text-align: center;
	border: 1px solid rgba(0, 0, 0, 0.1);
	background-color: #ddd;

	.data {
		padding: 16px 0px;
	}
	
	.number {
		line-height: 24px;
		font-size: 28px;
	}

	.percent {
		font-size: 24px;
	}

	.units {
		font-size: 16px;
	}

	.subtext {
		font-size: 12px;
		font-weight: bold;
	}
}
</style>