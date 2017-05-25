<template>
<div v-if="this.results && Object.keys(this.results.contributions_by_identities).length > 0">
	<div v-html="this.results.embeds.spectrum" v-if="currentResultsView == 'latest' && this.results.embeds.spectrum" style="width: 500px; display: block; margin: 0px auto; font-size: 36px;"></div>
	<div v-html="this.results.embeds.value" v-if="currentResultsView == 'latest' && !this.results.embeds.spectrum" style="width: 400px; display: block; margin: 0px auto; font-size: 36px;"></div>
	
	<div v-html="this.results.embeds.distribution" v-if="currentResultsView == 'distribution'" style="width: 800px; height: 120px; display: block; margin: 0px auto; font-size: 36px;"></div>
	<div v-html="this.results.embeds.by_time" v-if="currentResultsView == 'by_time'" style="width: 800px; height: 120px; display: block; margin: 0px auto; font-size: 36px;"></div>
	<div v-if="currentResultsView == 'raw'" style="width: 800px; margin: 0 auto; font-size: 36px;">
		<div class="contributions">
			<div class="contribution" v-for="(identity_data, identity_id) in this.results.contributions_by_identities" :key="identity_id">
				<div class="weight">
					<el-progress :text-inside="true" :stroke-width="24" :percentage="Math.round(identity_data.contributions[0].weight * 100)"></el-progress>
				</div>
				<div v-html="identity_data.contributions[identity_data.contributions.length - 1].embeds.value" class="choice"></div>
				<div v-if="identity_data.embeds.by_time" v-html="identity_data.embeds.by_time" class="choice"></div>
				<div class="username"><router-link :to="'/identities/' + identity_data.contributions[0].identity_username">{{ identity_data.contributions[0].identity_username }}</router-link></div>
				<div class="date">{{ moment(new Date(identity_data.contributions[identity_data.contributions.length - 1].datetime)).fromNow() }}</div>
			</div>
			<p class="turnout">{{ Math.round(this.results.turnout_ratio * 100) }}% of trust metric</p>
		</div>
	</div>

	<span @click="currentResultsView = 'latest'" v-bind:class="{ active: currentResultsView == 'latest' }" class="results-view-button">Current</span>
	<span @click="currentResultsView = 'distribution'" v-if="this.results.embeds.distribution" v-bind:class="{ active: currentResultsView == 'distribution' }" class="results-view-button">Distribution</span>
	<span @click="currentResultsView = 'by_time'" v-if="this.results.embeds.by_time" v-bind:class="{ active: currentResultsView == 'by_time' }" class="results-view-button">Graph</span>
	<span @click="currentResultsView = 'raw'" v-bind:class="{ active: currentResultsView == 'raw' }" class="results-view-button">Votes</span>
</div>
</template>

<script>
import Vue from 'vue'
import ElementUI from 'element-ui';
import locale from 'element-ui/lib/locale/lang/en'
var _ = require('lodash')

Vue.use(ElementUI, {locale})

export default {
	props: ['results'],
	data: function() {
		return {
			moment: require('moment'),
			currentResultsView: 'latest'
		}
	}
}
</script>

<style scoped lang="less">
.results-view-button {
	display: inline-block;
	margin: 0px 20px;
	color: #111;
	font-size: 18px;
	text-transform: lowercase;
}
.results-view-button.active {
	font-weight: bold;
}

.contributions {
	margin-top: 50px;
	text-align: left;

	.turnout {
		text-align: center;
		font-size: 20px;
		margin-top: 20px;
		margin-bottom: 30px;
		color: #111;
	}

	.contribution {
		margin: 10px 0px;
		font-size: 16px;

		.weight {
			width: 300px;
			display: inline-block;
			vertical-align: middle;
		}
		.choice {
			width: 140px;
			height: 40px;
			display: inline-block;
			vertical-align: middle;
			margin-left: 40px;
			font-weight: bold;
		}
		.username {
			width: 180px;
			display: inline-block;
			vertical-align: middle;
			margin-left: 30px;
			text-align: left;
			font-size: 18px;
		}
		.date {
			display: inline;
			vertical-align: middle;
			text-align: left;
		}
	}
}
</style>